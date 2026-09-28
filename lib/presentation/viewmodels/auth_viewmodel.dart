import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authRepository.login(email, password);
      _currentUser = user;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authRepository.register(name, email, password);
      _currentUser = user;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
