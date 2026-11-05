import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'core/app_scroll_behavior.dart';
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
        scrollBehavior: const AppScrollBehavior(),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        builder: (context, child) {
          final windowSize = MediaQuery.of(context).size;
          // Khi mo tren trinh duyet may tinh man hinh rong, hien khung mo phong dien thoai thuc the
          if (windowSize.width > 500) {
            const phoneWidth = 412.0;
            final maxAllowedHeight = windowSize.height > 60
                ? windowSize.height - 30
                : windowSize.height;
            final phoneHeight = maxAllowedHeight.clamp(400.0, 890.0);
            return Scaffold(
              backgroundColor: const Color(0xFF0F172A),
              body: Center(
                child: Container(
                  width: phoneWidth,
                  height: phoneHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFF334155),
                      width: 8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 32,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(phoneWidth, phoneHeight),
                      ),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            );
          }
          return child ?? const SizedBox.shrink();
        },
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
