import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/di/provider_setup.dart';
import 'presentation/routes/app_routes.dart';

void main() {
  runApp(const H2THealthcareApp());
}

class H2THealthcareApp extends StatelessWidget {
  const H2THealthcareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: ProviderSetup.providers,
      child: MaterialApp(
        title: 'H2T Healthcare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.home,
        routes: AppRoutes.routes,
      ),
    );
  }
}
