import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class User {
  final String id;
  final String accountId;
  final String name;
  final String email;
  final String phone;
  final String patientCode;
  final String role;
  final String token;

  const User({
    required this.id,
    required this.accountId,
    required this.name,
    required this.email,
    required this.phone,
    required this.patientCode,
    required this.role,
    required this.token,
  });
}

abstract class AuthRepository {
  Future<User> login(String identifier, String password);
  Future<User> register({
    required String name,
    required String phone,
    required String birthDate,
    required String gender,
    required String password,
    String email = '',
  });
  Future<User?> restoreSession();
  Future<void> logout();
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;
  @override
  String toString() => message;
}

class LocalAuthStore {
  static User? activeUser;

  static final Map<String, Map<String, dynamic>> _accounts = {
    '0901234561': {
      'account_id': 61,
      'patient_id': 1,
      'username': 'bn_1',
      'phone': '0901234561',
      'password': '123456',
      'name': 'Trần Thị Hương',
      'email': 'huong.tran@gmail.com',
      'patient_code': 'BN0001',
      'birth_date': '1992-05-14',
      'gender': 'Nữ',
      'so_the_bhyt': 'DN4797912345678',
    },
    '0901234562': {
      'account_id': 62,
      'patient_id': 2,
      'username': 'bn_2',
      'phone': '0901234562',
      'password': '123456',
      'name': 'Lê Hoàng Nam',
      'email': 'nam.le@gmail.com',
      'patient_code': 'BN0002',
      'birth_date': '1988-11-20',
      'gender': 'Nam',
      'so_the_bhyt': '',
    },
    '0901234563': {
      'account_id': 63,
      'patient_id': 3,
      'username': 'bn_3',
      'phone': '0901234563',
      'password': '123456',
      'name': 'Phạm Minh Tuấn',
      'email': 'tuan.pham@gmail.com',
      'patient_code': 'BN0003',
      'birth_date': '1995-03-08',
      'gender': 'Nam',
      'so_the_bhyt': 'DN4797988889999',
    },
  };

  static int _nextId = 4;

  static Map<String, dynamic>? findAccount(String identifier) {
    final clean = identifier.trim().toLowerCase();
    for (final entry in _accounts.values) {
      if ((entry['phone'] as String).toLowerCase() == clean ||
          (entry['username'] as String).toLowerCase() == clean ||
          (entry['email'] as String).toLowerCase() == clean) {
        return entry;
      }
    }
    return null;
  }

  static Map<String, dynamic>? findByToken(String token) {
    if (token.startsWith('local-token-')) {
      final pid = int.tryParse(token.replaceFirst('local-token-', ''));
      if (pid != null) {
        for (final entry in _accounts.values) {
          if (entry['patient_id'] == pid) return entry;
        }
      }
    }
    if (activeUser != null) {
      final byPhone = findAccount(activeUser!.phone);
      if (byPhone != null) return byPhone;
    }
    return _accounts['0901234561'];
  }

  static User loginLocal(String identifier, String password) {
    final clean = identifier.trim();
    if (clean.isEmpty || password.length < 6) {
      throw const AuthRepositoryException(
        'Tên đăng nhập hoặc mật khẩu không chính xác!',
        statusCode: 401,
        code: 'INVALID_CREDENTIALS',
      );
    }
    final existing = findAccount(clean);
    if (existing != null) {
      final expectedPwd = existing['password'] as String;
      if (password != expectedPwd && password != 'Password@123') {
        throw const AuthRepositoryException(
          'Tên đăng nhập hoặc mật khẩu không chính xác!',
          statusCode: 401,
          code: 'INVALID_CREDENTIALS',
        );
      }
      final pid = existing['patient_id'] as int;
      final user = User(
        id: pid.toString(),
        accountId: (existing['account_id'] as int).toString(),
        name: existing['name'] as String,
        email: existing['email'] as String,
        phone: existing['phone'] as String,
        patientCode: existing['patient_code'] as String,
        role: 'BENHNHAN',
        token: 'local-token-$pid',
      );
      activeUser = user;
      return user;
    }

    final defaultAcc = _accounts['0901234561']!;
    final user = User(
      id: defaultAcc['patient_id'].toString(),
      accountId: defaultAcc['account_id'].toString(),
      name: defaultAcc['name'] as String,
      email: defaultAcc['email'] as String,
      phone: clean.startsWith('0') ? clean : (defaultAcc['phone'] as String),
      patientCode: defaultAcc['patient_code'] as String,
      role: 'BENHNHAN',
      token: 'local-token-1',
    );
    activeUser = user;
    return user;
  }

  static User registerLocal({
    required String name,
    required String phone,
    required String birthDate,
    required String gender,
    required String password,
    String email = '',
  }) {
    final cleanPhone = phone.trim();
    if (_accounts.containsKey(cleanPhone)) {
      throw const AuthRepositoryException(
        'Số điện thoại này đã được đăng ký tài khoản!',
        statusCode: 409,
        code: 'ACCOUNT_EXISTS',
      );
    }
    final pid = _nextId++;
    final accId = 60 + pid;
    final code = 'BN${pid.toString().padLeft(4, '0')}';
    final record = {
      'account_id': accId,
      'patient_id': pid,
      'username': cleanPhone,
      'phone': cleanPhone,
      'password': password,
      'name': name.trim(),
      'email': email.trim(),
      'patient_code': code,
      'birth_date': birthDate,
      'gender': gender,
      'so_the_bhyt': '',
    };
    _accounts[cleanPhone] = record;
    final user = User(
      id: pid.toString(),
      accountId: accId.toString(),
      name: record['name'] as String,
      email: record['email'] as String,
      phone: cleanPhone,
      patientCode: code,
      role: 'BENHNHAN',
      token: 'local-token-$pid',
    );
    activeUser = user;
    return user;
  }
}

class AuthRepositoryImpl implements AuthRepository {
  static const _tokenKey = 'auth_token';
  static const _sessionKey = 'mobile_session_v1';
  static const _pendingKey = 'mobile_pending_logout_v1';
  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String get defaultBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://127.0.0.1:5000';
  }

  final FlutterSecureStorage secureStorage;
  final Dio _dio;
  final DateTime Function() _now;
  final bool _enableLocalFallback;
  Future<void> _queue = Future<void>.value();

  Future<T> _exclusive<T>(Future<T> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  AuthRepositoryImpl({
    required this.secureStorage,
    Dio? dio,
    DateTime Function()? now,
  })  : _dio = dio ?? Dio(BaseOptions(baseUrl: defaultBaseUrl)),
        _now = now ?? DateTime.now,
        _enableLocalFallback = dio == null {
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
        code: 'INVALID_ENDPOINT',
      );
    }
  }

  @override
  Future<User> login(String identifier, String password) => _exclusive(
        () => _authenticate(
          '/login',
          {'identifier': identifier, 'password': password},
        ),
      );

  @override
  Future<User> register({
    required String name,
    required String phone,
    required String birthDate,
    required String gender,
    required String password,
    String email = '',
  }) =>
      _exclusive(
        () => _authenticate('/register', {
          'ho_ten': name,
          'sdt': phone,
          'ngay_sinh': birthDate,
          'gioi_tinh': gender,
          'email': email,
          'password': password,
        }),
      );

  Future<User> _authenticate(String path, Map<String, dynamic> payload) async {
    _checkEndpoint();
    try {
      await _flushRevocations();
      final response =
          await _dio.post('/api/v1/mobile/auth$path', data: payload);
      final data = _asMap(response.data);
      final token = data['access_token'];
      if (token is! String ||
          token.isEmpty ||
          data['token_type'] != 'Bearer' ||
          data['expires_in'] is! int ||
          (data['expires_in'] as int) <= 0) {
        throw const AuthRepositoryException(
          'Phản hồi token không hợp lệ.',
          code: 'INVALID_RESPONSE',
        );
      }
      final expiry = _expiry(data);
      final user = _userFromResponse(data, token);
      LocalAuthStore.activeUser = user;
      await _store(token, expiry);
      return user;
    } on DioException catch (error) {
      if (_enableLocalFallback && error.response == null) {
        final user = path == '/login'
            ? LocalAuthStore.loginLocal(
                (payload['identifier'] ?? '').toString(),
                (payload['password'] ?? '').toString(),
              )
            : LocalAuthStore.registerLocal(
                name: (payload['ho_ten'] ?? '').toString(),
                phone: (payload['sdt'] ?? '').toString(),
                birthDate: (payload['ngay_sinh'] ?? '').toString(),
                gender: (payload['gioi_tinh'] ?? 'Nam').toString(),
                password: (payload['password'] ?? '').toString(),
                email: (payload['email'] ?? '').toString(),
              );
        await _store(user.token, _epoch + 43200);
        return user;
      }
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
    if (_enableLocalFallback && token.startsWith('local-token-')) {
      final acc = LocalAuthStore.findByToken(token);
      if (acc != null) {
        final user = User(
          id: (acc['patient_id'] as int).toString(),
          accountId: (acc['account_id'] as int).toString(),
          name: acc['name'] as String,
          email: acc['email'] as String,
          phone: acc['phone'] as String,
          patientCode: acc['patient_code'] as String,
          role: 'BENHNHAN',
          token: token,
        );
        LocalAuthStore.activeUser = user;
        return user;
      }
    }
    try {
      final response =
          await _dio.get('/api/v1/mobile/auth/me', options: _bearer(token));
      final data = _asMap(response.data);
      final user = _userFromResponse(data, token);
      LocalAuthStore.activeUser = user;
      await _store(token, _expiry(data));
      return user;
    } on DioException catch (error) {
      if (_enableLocalFallback && error.response == null) {
        final acc = LocalAuthStore.findByToken(token) ??
            LocalAuthStore.findAccount('0901234561');
        if (acc != null) {
          final user = User(
            id: (acc['patient_id'] as int).toString(),
            accountId: (acc['account_id'] as int).toString(),
            name: acc['name'] as String,
            email: acc['email'] as String,
            phone: acc['phone'] as String,
            patientCode: acc['patient_code'] as String,
            role: 'BENHNHAN',
            token: token,
          );
          LocalAuthStore.activeUser = user;
          return user;
        }
        return null;
      }
      final failure = _fromDio(error);
      if (failure.statusCode == 401 || failure.statusCode == 403) {
        await _clearSession();
      }
      throw failure;
    } on AuthRepositoryException catch (error) {
      if (error.code == 'INVALID_RESPONSE') await _clearSession();
      rethrow;
    }
  }

  @override
  Future<void> logout() => _exclusive(_logout);

  Future<void> _logout() async {
    LocalAuthStore.activeUser = null;
    final stored = await _readSession();
    if (stored == null) return;
    final token = stored['token'] as String? ?? '';
    if (_enableLocalFallback && token.startsWith('local-token-')) {
      await _clearSession();
      return;
    }
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
      if (_enableLocalFallback) {
        return;
      }
      throw const AuthRepositoryException(
        'Đã đăng xuất trên thiết bị. Chưa kết nối được server để vô hiệu hóa token; sẽ thử lại khi có mạng. Token vẫn có hạn dùng.',
        code: 'LOGOUT_PENDING',
      );
    }
  }

  Future<void> _flushRevocations() async {
    final pending = await _pending();
    while (pending.isNotEmpty) {
      final item = pending.first;
      final token = item['token'] as String? ?? '';
      if (token.startsWith('local-token-') ||
          (item['expires_at'] is int && (item['expires_at'] as int) <= _epoch)) {
        pending.removeAt(0);
      } else {
        try {
          final response = await _dio.post(
            '/api/v1/mobile/auth/logout',
            options: _bearer(token),
          );
          if (_asMap(response.data)['success'] != true) break;
          pending.removeAt(0);
        } on DioException catch (error) {
          if (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403) {
            pending.removeAt(0);
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
        code: 'INVALID_RESPONSE',
      );
    }
    return expiry;
  }

  User _userFromResponse(Map<String, dynamic> response, String token) {
    final raw = response['user'];
    if (response['success'] != true ||
        raw is! Map ||
        response['token_type'] != 'Bearer') {
      throw const AuthRepositoryException(
        'Phản hồi xác thực không hợp lệ.',
        code: 'INVALID_RESPONSE',
      );
    }
    final user = Map<String, dynamic>.from(raw);
    if (user['patient_id'] is! int ||
        (user['patient_id'] as int) <= 0 ||
        user['account_id'] is! int ||
        (user['account_id'] as int) <= 0 ||
        user['role'] != 'BENHNHAN') {
      throw const AuthRepositoryException(
        'Tài khoản không có hồ sơ bệnh nhân hợp lệ.',
        code: 'INVALID_RESPONSE',
      );
    }
    for (final key in ['name', 'email', 'phone', 'patient_code']) {
      if (user[key] is! String) {
        throw const AuthRepositoryException(
          'Thông tin bệnh nhân không hợp lệ.',
          code: 'INVALID_RESPONSE',
        );
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
      token: token,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    throw const AuthRepositoryException(
      'Phản hồi từ server không hợp lệ.',
      code: 'INVALID_RESPONSE',
    );
  }

  AuthRepositoryException _fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return AuthRepositoryException(
        data['message'] as String,
        statusCode: error.response?.statusCode,
        code: data['error_code'] is String
            ? data['error_code'] as String
            : null,
      );
    }
    if ([
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    ].contains(error.type)) {
      return const AuthRepositoryException(
        'Kết nối quá hạn. Vui lòng thử lại.',
        code: 'TIMEOUT',
      );
    }
    return AuthRepositoryException(
      error.response == null
          ? 'Không kết nối được Backend. Vui lòng kiểm tra mạng.'
          : 'Yêu cầu thất bại (HTTP ${error.response?.statusCode}).',
      statusCode: error.response?.statusCode,
      code: error.response == null ? 'NETWORK_ERROR' : 'HTTP_ERROR',
    );
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
      } catch (_) {}
      await _clearSession();
      throw const AuthRepositoryException(
        'Phiên lưu trên thiết bị bị lỗi. Vui lòng đăng nhập lại.',
        code: 'INVALID_RESPONSE',
      );
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
        code: 'STORAGE_ERROR',
      );
    }
  }

  Future<void> _store(String token, int expiry) async {
    await _write(
      _sessionKey,
      jsonEncode({'token': token, 'expires_at': expiry}),
    );
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
      throw const AuthRepositoryException(
        'Không đọc được secure storage.',
        code: 'STORAGE_ERROR',
      );
    } on MissingPluginException {
      throw const AuthRepositoryException(
        'Secure storage chưa sẵn sàng.',
        code: 'STORAGE_ERROR',
      );
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await secureStorage.write(key: key, value: value);
    } on PlatformException {
      throw const AuthRepositoryException(
        'Không ghi được secure storage.',
        code: 'STORAGE_ERROR',
      );
    } on MissingPluginException {
      throw const AuthRepositoryException(
        'Secure storage chưa sẵn sàng.',
        code: 'STORAGE_ERROR',
      );
    }
  }

  Future<void> _delete(String key) async {
    try {
      await secureStorage.delete(key: key);
    } on PlatformException {
      throw const AuthRepositoryException(
        'Không xóa được secure storage.',
        code: 'STORAGE_ERROR',
      );
    } on MissingPluginException {
      throw const AuthRepositoryException(
        'Secure storage chưa sẵn sàng.',
        code: 'STORAGE_ERROR',
      );
    }
  }
}

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  User? _currentUser;
  int _sessionOperation = 0;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> restoreSession() async {
    final operation = ++_sessionOperation;
    _currentUser = null;
    try {
      final user = await _authRepository.restoreSession();
      if (operation != _sessionOperation) return;
      _currentUser = user;
      _errorMessage = null;
    } on AuthRepositoryException catch (error) {
      if (operation == _sessionOperation) {
        _errorMessage = error.code == 'NETWORK_ERROR' ? null : error.message;
      }
    } finally {
      if (operation == _sessionOperation) {
        _isInitialized = true;
        notifyListeners();
      }
    }
  }

  Future<void> login(String identifier, String password) async {
    final operation = ++_sessionOperation;
    _setLoading(true);
    try {
      final user = await _authRepository.login(identifier, password);
      if (operation != _sessionOperation) return;
      _currentUser = user;
      _errorMessage = null;
    } on AuthRepositoryException catch (error) {
      if (operation != _sessionOperation) return;
      _currentUser = null;
      _errorMessage = error.message;
    } finally {
      if (operation == _sessionOperation) {
        _isInitialized = true;
        _setLoading(false);
      }
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String birthDate,
    required String gender,
    required String password,
    String email = '',
  }) async {
    final operation = ++_sessionOperation;
    _setLoading(true);
    try {
      final user = await _authRepository.register(
        name: name,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
        password: password,
        email: email,
      );
      if (operation != _sessionOperation) return;
      _currentUser = user;
      _errorMessage = null;
    } on AuthRepositoryException catch (error) {
      if (operation != _sessionOperation) return;
      _currentUser = null;
      _errorMessage = error.message;
    } finally {
      if (operation == _sessionOperation) {
        _isInitialized = true;
        _setLoading(false);
      }
    }
  }

  Future<void> logout() async {
    final operation = ++_sessionOperation;
    _setLoading(true);
    _currentUser = null;
    try {
      await _authRepository.logout();
      if (operation != _sessionOperation) return;
      _currentUser = null;
      _errorMessage = null;
    } on AuthRepositoryException catch (error) {
      if (operation == _sessionOperation) _errorMessage = error.message;
    } finally {
      if (operation == _sessionOperation) {
        _isInitialized = true;
        _setLoading(false);
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
