import 'package:floraccess_app/config.dart';
import 'package:floraccess_app/core/network/api_client.dart';
import 'package:floraccess_app/core/router/app_router.dart';
import 'package:floraccess_app/core/storage/local_storage.dart';
import 'package:floraccess_app/features/auth/data/auth_repository.dart';
import 'package:floraccess_app/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:floraccess_app/features/legal/presentation/pages/legal_notice_page.dart';
import 'package:floraccess_app/features/users/data/user_repository.dart';
import 'package:floraccess_app/features/users/presentation/viewmodels/users_view_model.dart';
import 'package:floraccess_app/shared/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Router of the application for a visitor who is not logged in.
Future<GoRouter> buildRouterOfVisitorNotLoggedIn() async {
  SharedPreferences.setMockInitialValues({});
  final appState = AppState(storage: await LocalStorage.init());
  final apiClient = ApiClient(
    baseUrl: 'http://api.test',
    tokenProvider: () async => null,
  );

  return AppRouter(
    appState: appState,
    authViewModel: AuthViewModel(
      authRepository: AuthRepository(apiClient),
      appState: appState,
    ),
    usersViewModel: UsersViewModel(UserRepository(apiClient)),
  ).router;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Config.load();
  });

  testWidgets('shows the legal notice to a visitor who is not logged in', (
    tester,
  ) async {
    final router = await buildRouterOfVisitorNotLoggedIn();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go(legalNoticePath);
    await tester.pumpAndSettle();

    expect(find.byType(LegalNoticePage), findsOneWidget);
  });

  testWidgets('still sends a visitor who is not logged in to the login page', (
    tester,
  ) async {
    final router = await buildRouterOfVisitorNotLoggedIn();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/profile');
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/login');
  });
}
