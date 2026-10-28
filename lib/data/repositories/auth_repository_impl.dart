import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;
  @override
  String toString() => message;
}

class AuthRepositoryImpl implements AuthRepository {
  static const _tokenKey =
      'auth_token'; // Read only for migration of old installs.
  static const _sessionKey = 'mobile_session_v1';
  static const _pendingKey = 'mobile_pending_logout_v1';
  static const _baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000');
  final FlutterSecureStorage secureStorage;
  final Dio _dio;
  final DateTime Function() _now;
  Future<void> _queue = Future<void>.value();

  Future<T> _exclusive<T>(Future<T> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  AuthRepositoryImpl(
      {required this.secureStorage, Dio? dio, DateTime Function()? now})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl)),
        _now = now ?? DateTime.now {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 15);
    _dio.options.followRedirects = false;
  }

  void _checkEndpoint() {
    final uri = Uri.tryParse(_dio.options.baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        !['http', 'https'].contains(uri.scheme) ||
        (kReleaseMode && uri.scheme != 'https')) {
      throw const AuthRepositoryException(
          'Backend phải dùng HTTPS trong bản phát hành.',
          code: 'INVALID_ENDPOINT');
    }
  }

  @override
  Future<User> login(String identifier, String password) =>
      _exclusive(() => _authenticate(
          '/login', {'identifier': identifier, 'password': password}));

  @override
  Future<User> register(
          {required String name,
          required String phone,
          required String birthDate,
          required String gender,
          required String password,
          String email = ''}) =>
      _exclusive(() => _authenticate('/register', {
            'ho_ten': name,
            'sdt': phone,
            'ngay_sinh': birthDate,
            'gioi_tinh': gender,
            'email': email,
            'password': password
          }));

  Future<User> _authenticate(String path, Map<String, dynamic> payload) async {
    _checkEndpoint();
    await _flushRevocations();
    try {
      final response =
          await _dio.post('/api/v1/mobile/auth$path', data: payload);
      final data = _asMap(response.data);
      final token = data['access_token'];
      if (token is! String ||
          token.isEmpty ||
          data['token_type'] != 'Bearer' ||
          data['expires_in'] is! int ||
          (data['expires_in'] as int) <= 0) {
        throw const AuthRepositoryException('Phản hồi token không hợp lệ.',
            code: 'INVALID_RESPONSE');
      }
      final expiry = _expiry(data);
      final user = _userFromResponse(data, token);
      await _store(token, expiry);
      return user;
    } on DioException catch (error) {
      throw _fromDio(error);
    }
  }

  @override
  Future<User?> restoreSession() => _exclusive(_restoreSession);

  Future<User?> _restoreSession() async {
    _checkEndpoint();
    await _flushRevocations();
    final stored = await _readSession();
    if (stored == null) return null;
    final token = stored['token'] as String;
    final expiry = stored['expires_at'];
    if (expiry is int && expiry <= _epoch) {
      await _clearSession();
      return null;
    }
    try {
      final response =
          await _dio.get('/api/v1/mobile/auth/me', options: _bearer(token));
      final data = _asMap(response.data);
      final user = _userFromResponse(data, token);
      await _store(token, _expiry(data));
      return user; // Never restore identity from secure-storage contents alone.
    } on DioException catch (error) {
      final failure = _fromDio(error);
      if (failure.statusCode == 401 || failure.statusCode == 403) {
        await _clearSession();
      }
      throw failure; // Network/503 leaves credentials available for an explicit retry.
    } on AuthRepositoryException catch (error) {
      if (error.code == 'INVALID_RESPONSE') await _clearSession();
      rethrow;
    }
  }

  @override
  Future<void> logout() => _exclusive(_logout);

  Future<void> _logout() async {
    final stored = await _readSession();
    if (stored == null) return;
    // Queue before erasing the active session so an offline logout can be retried.
    final pending = await _pending();
    if (!pending.any((item) => item['token'] == stored['token'])) {
      pending.add(stored);
    }
    try {
      await _write(_pendingKey, jsonEncode(pending));
    } finally {
      await _clearSession();
    }
    _checkEndpoint();
    await _flushRevocations();
    if ((await _pending()).any((item) => item['token'] == stored['token'])) {
      throw const AuthRepositoryException(
          'Đã đăng xuất trên thiết bị. Chưa kết nối được server để vô hiệu hóa token; sẽ thử lại khi có mạng. Token vẫn có hạn dùng.',
          code: 'LOGOUT_PENDING');
    }
  }

  Future<void> _flushRevocations() async {
    final pending = await _pending();
    while (pending.isNotEmpty) {
      final item = pending.first;
      if (item['expires_at'] is int && (item['expires_at'] as int) <= _epoch) {
        pending.removeAt(0);
      } else {
        try {
          final response = await _dio.post('/api/v1/mobile/auth/logout',
              options: _bearer(item['token'] as String));
          if (_asMap(response.data)['success'] != true) break;
          pending.removeAt(0);
        } on DioException catch (error) {
          if (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403) {
            pending.removeAt(0); // Server already refuses this token.
          } else {
            break;
          }
        }
      }
      await _write(_pendingKey, jsonEncode(pending));
    }
  }

  int get _epoch => _now().toUtc().millisecondsSinceEpoch ~/ 1000;
  Options _bearer(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});
  int _expiry(Map<String, dynamic> data) {
    final expiry = data['expires_at'];
    if (expiry is! int || expiry <= _epoch || expiry > _epoch + 86400) {
      throw const AuthRepositoryException(
          'Thời hạn phiên từ server không hợp lệ.',
          code: 'INVALID_RESPONSE');
    }
    return expiry;
  }

  User _userFromResponse(Map<String, dynamic> response, String token) {
    final raw = response['user'];
    if (response['success'] != true ||
        raw is! Map ||
        response['token_type'] != 'Bearer') {
      throw const AuthRepositoryException('Phản hồi xác thực không hợp lệ.',
          code: 'INVALID_RESPONSE');
    }
    final user = Map<String, dynamic>.from(raw);
    if (user['patient_id'] is! int ||
        (user['patient_id'] as int) <= 0 ||
        user['account_id'] is! int ||
        (user['account_id'] as int) <= 0 ||
        user['role'] != 'BENHNHAN') {
      throw const AuthRepositoryException(
          'Tài khoản không có hồ sơ bệnh nhân hợp lệ.',
          code: 'INVALID_RESPONSE');
    }
    for (final key in ['name', 'email', 'phone', 'patient_code']) {
      if (user[key] is! String) {
        throw const AuthRepositoryException('Thông tin bệnh nhân không hợp lệ.',
            code: 'INVALID_RESPONSE');
      }
    }
    return User(
        id: user['patient_id'].toString(),
        accountId: user['account_id'].toString(),
        name: user['name'] as String,
        email: user['email'] as String,
        phone: user['phone'] as String,
        patientCode: user['patient_code'] as String,
        role: 'BENHNHAN',
        token: token);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const AuthRepositoryException('Phản hồi từ server không hợp lệ.',
        code: 'INVALID_RESPONSE');
  }

  AuthRepositoryException _fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return AuthRepositoryException(data['message'] as String,
          statusCode: error.response?.statusCode,
          code: data['error_code'] is String
              ? data['error_code'] as String
              : null);
    }
    if ([
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout
    ].contains(error.type)) {
      return const AuthRepositoryException('Kết nối quá hạn. Vui lòng thử lại.',
          code: 'TIMEOUT');
    }
    return AuthRepositoryException(
        error.response == null
            ? 'Không kết nối được Backend. Vui lòng kiểm tra mạng.'
            : 'Yêu cầu thất bại (HTTP ${error.response?.statusCode}).',
        statusCode: error.response?.statusCode,
        code: error.response == null ? 'NETWORK_ERROR' : 'HTTP_ERROR');
  }

  Future<Map<String, dynamic>?> _readSession() async {
    final value = await _read(_sessionKey);
    if (value != null) {
      try {
        final data = _asMap(jsonDecode(value));
        if (data['token'] is String &&
            (data['token'] as String).isNotEmpty &&
            data['expires_at'] is int) {
          return data;
        }
      } catch (_) {/* Invalid local data is not an authenticated session. */}
      await _clearSession();
      throw const AuthRepositoryException(
          'Phiên lưu trên thiết bị bị lỗi. Vui lòng đăng nhập lại.',
          code: 'INVALID_RESPONSE');
    }
    final legacy = await _read(_tokenKey);
    return legacy == null || legacy.isEmpty ? null : {'token': legacy};
  }

  Future<List<Map<String, dynamic>>> _pending() async {
    final value = await _read(_pendingKey);
    if (value == null) return [];
    try {
      final items = jsonDecode(value) as List;
      return items
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((item) => item['token'] is String)
          .toList();
    } catch (_) {
      throw const AuthRepositoryException(
          'Không đọc được danh sách phiên chờ vô hiệu hóa.',
          code: 'STORAGE_ERROR');
    }
  }

  Future<void> _store(String token, int expiry) async {
    await _write(
        _sessionKey, jsonEncode({'token': token, 'expires_at': expiry}));
    await _delete(_tokenKey);
  }

  Future<void> _clearSession() async {
    await _delete(_sessionKey);
    await _delete(_tokenKey);
  }

  Future<String?> _read(String key) async {
    try {
      return await secureStorage.read(key: key);
    } on PlatformException {
      throw const AuthRepositoryException('Không đọc được secure storage.',
          code: 'STORAGE_ERROR');
    } on MissingPluginException {
      throw const AuthRepositoryException('Secure storage chưa sẵn sàng.',
          code: 'STORAGE_ERROR');
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await secureStorage.write(key: key, value: value);
    } on PlatformException {
      throw const AuthRepositoryException('Không ghi được secure storage.',
          code: 'STORAGE_ERROR');
    } on MissingPluginException {
      throw const AuthRepositoryException('Secure storage chưa sẵn sàng.',
          code: 'STORAGE_ERROR');
    }
  }

  Future<void> _delete(String key) async {
    try {
      await secureStorage.delete(key: key);
    } on PlatformException {
      throw const AuthRepositoryException('Không xóa được secure storage.',
          code: 'STORAGE_ERROR');
    } on MissingPluginException {
      throw const AuthRepositoryException('Secure storage chưa sẵn sàng.',
          code: 'STORAGE_ERROR');
    }
  }
}
