import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  Future<void> restoreSession() async {
    try {
      _currentUser = await _authRepository.restoreSession();
    } on AuthRepositoryException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> login(String identifier, String password) async {
    _setLoading(true);
    try {
      _currentUser = await _authRepository.login(identifier, password);
      _errorMessage = null;
    } on AuthRepositoryException catch (error) {
      _currentUser = null;
      _errorMessage = error.message;
    } finally {
      _isInitialized = true;
      _setLoading(false);
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
    _setLoading(true);
    try {
      _currentUser = await _authRepository.register(
        name: name,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
        password: password,
        email: email,
      );
      _errorMessage = null;
    } on AuthRepositoryException catch (error) {
      _currentUser = null;
      _errorMessage = error.message;
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authRepository.logout();
      _currentUser = null;
      _errorMessage = null;
    } on AuthRepositoryException catch (error) {
      _errorMessage = error.message;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
