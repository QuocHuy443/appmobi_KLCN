import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FlutterSecureStorage secureStorage;
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

  AuthRepositoryImpl({required this.secureStorage});

  @override
  Future<User> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data;
    final user = User(
      id: data['id'].toString(),
      name: data['name'] ?? '',
      email: data['email'],
      token: data['token'],
    );
    // Save token securely
    await secureStorage.write(key: 'auth_token', value: user.token);
    return user;
  }

  @override
  Future<User> register(String name, String email, String password) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final data = response.data;
    final user = User(
      id: data['id'].toString(),
      name: data['name'],
      email: data['email'],
      token: data['token'],
    );
    await secureStorage.write(key: 'auth_token', value: user.token);
    return user;
  }
}
