import 'package:floraccess_app/config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/viewmodels/auth_view_model.dart';
import 'features/users/data/user_repository.dart';
import 'features/users/presentation/viewmodels/users_view_model.dart';
import 'shared/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await LocalStorage.init();
  final appState = AppState(storage: storage);
  await Config.load();
  final apiClient = ApiClient(
    baseUrl: Config.dataUrl,
    tokenProvider: () async => appState.jwtToken,
  );
  final userRepository = UserRepository(apiClient);
  final authRepository = AuthRepository(apiClient);
  final usersViewModel = UsersViewModel(userRepository);
  final authViewModel = AuthViewModel(
    authRepository: authRepository,
    appState: appState,
  );
  final router = AppRouter(
    appState: appState,
    authViewModel: authViewModel,
    usersViewModel: usersViewModel,
  ).router;

  apiClient.onUnauthorized = () async {
    await appState.clearJwtToken();
    router.go('/');
  };

  runApp(FloraccessApp(appState: appState, router: router));
}

class FloraccessApp extends StatelessWidget {
  const FloraccessApp({
    required this.appState,
    required this.router,
    super.key,
  });

  final AppState appState;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (_, _) => MaterialApp.router(
        title: 'Floraccess',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: appState.themeMode,
        routerConfig: router,
      ),
    );
  }
}
