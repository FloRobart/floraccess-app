import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_request_page.dart';
import '../../features/auth/presentation/pages/login_verify_page.dart';
import '../../features/legal/presentation/pages/legal_notice_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../features/users/presentation/viewmodels/users_view_model.dart';
import '../../shared/app_state.dart';

class AppRouter {
  final AppState appState;
  final AuthViewModel authViewModel;
  final UsersViewModel usersViewModel;
  AppRouter({
    required this.appState,
    required this.authViewModel,
    required this.usersViewModel,
  }) {
    router = GoRouter(
      initialLocation: '/',
      refreshListenable: appState,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginRequestPage(
            authViewModel: authViewModel,
            appState: appState,
          ),
        ),
        GoRoute(
          path: '/verify',
          builder: (context, state) =>
              LoginVerifyPage(authViewModel: authViewModel, appState: appState),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => UsersPage(
            usersViewModel: usersViewModel,
            authViewModel: authViewModel,
            appState: appState,
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              ProfilePage(authViewModel: authViewModel, appState: appState),
        ),
        GoRoute(
          path: legalNoticePath,
          builder: (context, state) => const LegalNoticePage(),
        ),
      ],
      redirect: (context, state) {
        final loggedIn = appState.isAuthenticated;
        final loggingIn = state.matchedLocation == '/login';
        final verifying = state.matchedLocation == '/verify';
        /* The legal notice must be readable by anyone, logged in or not */
        if (state.matchedLocation == legalNoticePath) return null;
        if (!loggedIn && !loggingIn && !verifying) return '/login';
        if (loggedIn && (loggingIn || verifying)) return '/';
        if (verifying && appState.loginRequestToken == null) return '/login';
        return null;
      },
    );
  }

  late final GoRouter router;
}
