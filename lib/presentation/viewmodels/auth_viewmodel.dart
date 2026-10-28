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
  int _sessionOperation = 0;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  Future<void> restoreSession() async {
    final operation = ++_sessionOperation;
    _currentUser = null;
    try {
      final user = await _authRepository.restoreSession();
      if (operation != _sessionOperation) return;
      _currentUser = user;
      _errorMessage = null;
    } on AuthRepositoryException catch (error) {
      if (operation == _sessionOperation) _errorMessage = error.message;
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
