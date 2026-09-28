import 'package:flutter/material.dart';
import 'package:appmobi/presentation/screens/auth/login_screen.dart';
import 'package:appmobi/presentation/screens/auth/register_screen.dart';
import 'package:appmobi/screens/main_navigation_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String appointment = '/appointment';
  static const String healthRecord = '/health_record';
  static const String payment = '/payment';
  static const String notifications = '/notifications';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        home: (context) => const MainNavigationScreen(),
        // TODO: add other route builders when screens are created
      };
}
