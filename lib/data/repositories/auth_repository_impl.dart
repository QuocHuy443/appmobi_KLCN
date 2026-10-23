import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthRepositoryImpl implements AuthRepository {
  static const _tokenKey = 'auth_token';
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  final FlutterSecureStorage secureStorage;
  final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  AuthRepositoryImpl({required this.secureStorage});

  @override
  Future<User> login(String identifier, String password) async {
    try {
      final response = await _dio.post(
        '/api/v1/mobile/auth/login',
        data: {'identifier': identifier, 'password': password},
      );
      final data = _asMap(response.data);
      final token = data['access_token'];
      if (token is! String || token.isEmpty) {
        throw const AuthRepositoryException(
          'Phản hồi đăng nhập không có access token hợp lệ.',
        );
      }
      final user = _userFromResponse(data, token);
      await _writeToken(token);
      return user;
    } on DioException catch (error) {
      throw _fromDio(error);
    }
  }

  @override
  Future<User> register({
    required String name,
    required String phone,
    required String birthDate,
    required String gender,
    required String password,
    String email = '',
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/mobile/auth/register',
        data: {
          'ho_ten': name,
          'sdt': phone,
          'ngay_sinh': birthDate,
          'gioi_tinh': gender,
          'email': email,
          'password': password,
        },
      );
      final data = _asMap(response.data);
      final token = data['access_token'];
      if (token is! String || token.isEmpty) {
        throw const AuthRepositoryException(
          'Phản hồi đăng ký không có access token hợp lệ.',
        );
      }
      final user = _userFromResponse(data, token);
      await _writeToken(token);
      return user;
    } on DioException catch (error) {
      throw _fromDio(error);
    }
  }

  @override
  Future<User?> restoreSession() async {
    final token = await _readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _dio.get(
        '/api/v1/mobile/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return _userFromResponse(_asMap(response.data), token);
    } on DioException catch (error) {
      final authError = _fromDio(error);
      if (authError.statusCode == 401 || authError.statusCode == 403) {
        await _deleteToken();
      }
      throw authError;
    }
  }

  @override
  Future<void> logout() => _deleteToken();

  User _userFromResponse(Map<String, dynamic> response, String token) {
    final rawUser = response['user'];
    if (rawUser is! Map) {
      throw const AuthRepositoryException(
        'Phản hồi xác thực không có thông tin tài khoản hợp lệ.',
      );
    }
    final user = Map<String, dynamic>.from(rawUser);
    final patientId = user['patient_id'];
    final accountId = user['account_id'];
    if (patientId == null || accountId == null || user['role'] != 'BENHNHAN') {
      throw const AuthRepositoryException(
        'Tài khoản không có quyền sử dụng ứng dụng bệnh nhân.',
      );
    }
    return User(
      id: patientId.toString(),
      accountId: accountId.toString(),
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phone: user['phone']?.toString() ?? '',
      patientCode: user['patient_code']?.toString() ?? '',
      role: user['role'] as String,
      token: token,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const AuthRepositoryException('Phản hồi từ máy chủ không hợp lệ.');
  }

  AuthRepositoryException _fromDio(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map && responseData['message'] is String) {
      return AuthRepositoryException(
        responseData['message'] as String,
        statusCode: error.response?.statusCode,
      );
    }
    if (error.response == null) {
      return const AuthRepositoryException(
        'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và địa chỉ Backend.',
      );
    }
    return AuthRepositoryException(
      'Yêu cầu thất bại (HTTP ${error.response?.statusCode ?? 'unknown'}).',
      statusCode: error.response?.statusCode,
    );
  }

  Future<String?> _readToken() async {
    try {
      return await secureStorage.read(key: _tokenKey);
    } on PlatformException {
      throw const AuthRepositoryException('Không thể đọc phiên đăng nhập an toàn.');
    } on MissingPluginException {
      throw const AuthRepositoryException('Bộ lưu trữ an toàn chưa sẵn sàng.');
    }
  }

  Future<void> _writeToken(String token) async {
    try {
      await secureStorage.write(key: _tokenKey, value: token);
    } on PlatformException {
      throw const AuthRepositoryException('Không thể lưu phiên đăng nhập an toàn.');
    } on MissingPluginException {
      throw const AuthRepositoryException('Bộ lưu trữ an toàn chưa sẵn sàng.');
    }
  }

  Future<void> _deleteToken() async {
    try {
      await secureStorage.delete(key: _tokenKey);
    } on PlatformException {
      throw const AuthRepositoryException('Không thể xóa phiên đăng nhập an toàn.');
    } on MissingPluginException {
      throw const AuthRepositoryException('Bộ lưu trữ an toàn chưa sẵn sàng.');
    }
  }
}
