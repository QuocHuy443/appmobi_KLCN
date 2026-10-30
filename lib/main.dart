import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const H2THealthcareApp());
}

class H2THealthcareApp extends StatelessWidget {
  const H2THealthcareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FlutterSecureStorage>(
          create: (_) => const FlutterSecureStorage(),
        ),
        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            secureStorage: context.read<FlutterSecureStorage>(),
          ),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) {
            final viewModel = AuthViewModel(
              authRepository: context.read<AuthRepository>(),
            );
            unawaited(viewModel.restoreSession());
            return viewModel;
          },
        ),
      ],
      child: MaterialApp(
        title: 'H2T Healthcare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        initialRoute: '/home',
        routes: {
          '/login': (context) => const AuthScreen(),
          '/register': (context) =>
              const AuthScreen(initialMode: AuthMode.register),
          '/home': (context) => const MainNavigationScreen(),
        },
      ),
    );
  }
}
