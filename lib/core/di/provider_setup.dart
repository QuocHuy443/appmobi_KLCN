
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:appmobi/data/repositories/auth_repository_impl.dart';
import 'package:appmobi/domain/repositories/auth_repository.dart';
import 'package:appmobi/presentation/viewmodels/auth_viewmodel.dart';

class ProviderSetup {
  static List<SingleChildWidget> get providers => [
        // Secure storage singleton
        Provider<FlutterSecureStorage>(
          create: (_) => const FlutterSecureStorage(),
        ),
        // Auth repository implementation
        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            secureStorage: context.read<FlutterSecureStorage>(),
          ),
        ),
        // Auth ViewModel uses the repository
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        // TODO: add other ViewModels (HomeViewModel, AppointmentViewModel, …)
      ];
}
