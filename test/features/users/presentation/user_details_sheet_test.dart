import 'dart:convert';

import 'package:floraccess_app/core/network/api_client.dart';
import 'package:floraccess_app/features/users/data/user_repository.dart';
import 'package:floraccess_app/features/users/models/user.dart';
import 'package:floraccess_app/features/users/presentation/viewmodels/users_view_model.dart';
import 'package:floraccess_app/features/users/presentation/widgets/user_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Raw JSON of a user as returned by the admin routes of the FlorAccess API.
Map<String, dynamic> userJson({String? loginBlockedUntil}) => {
  'id': 7,
  'email': 'user@example.com',
  'pseudo': 'user',
  'auth_methods_id': 2,
  'is_connected': true,
  'is_verified_email': true,
  'login_blocked_until': loginBlockedUntil,
};

/// Fake API of the administrators: unblocks any user, and has no user to list.
Future<http.Response> answerAsAdminApi(
  http.Request request,
  List<String> receivedRequests,
) async {
  receivedRequests.add('${request.method} ${request.url.path}');

  if (request.url.path.endsWith('/login/unblock')) {
    return http.Response(jsonEncode(userJson()), 200);
  }

  if (request.url.path.endsWith('/count')) {
    return http.Response(jsonEncode({'count': 0}), 200);
  }

  return http.Response(jsonEncode(<Object>[]), 200);
}

/// Opens the details sheet of [user] from a button of an empty page.
Future<void> openDetailsSheet(
  WidgetTester tester,
  User user,
  UsersViewModel usersViewModel,
  List<String> shownMessages,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => UserDetailsSheet.show(
              context,
              user,
              usersViewModel,
              shownMessages.add,
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  final usersViewModel = UsersViewModel(
    UserRepository(
      ApiClient(
        baseUrl: 'http://api.test',
        tokenProvider: () async => 'administrator-jwt',
      ),
    ),
  );

  testWidgets('shows that the logins of a user are allowed', (tester) async {
    final user = User.fromJson(userJson());

    await openDetailsSheet(tester, user, usersViewModel, []);

    expect(find.text('Autorisées'), findsOneWidget);
    expect(find.text('Débloquer'), findsNothing);
  });

  testWidgets(
    'unblocks a blocked user after a confirmation, then closes the sheet',
    (tester) async {
      final receivedRequests = <String>[];
      final shownMessages = <String>[];
      final blockEnd = DateTime.now().add(const Duration(hours: 5));
      final blockedUser = User.fromJson(
        userJson(loginBlockedUntil: blockEnd.toUtc().toIso8601String()),
      );

      await http.runWithClient(
        () async {
          await openDetailsSheet(
            tester,
            blockedUser,
            usersViewModel,
            shownMessages,
          );
          expect(find.textContaining('Bloquées jusqu\'au'), findsOneWidget);

          await tester.ensureVisible(find.text('Débloquer'));
          await tester.tap(find.text('Débloquer'));
          await tester.pumpAndSettle();
          expect(find.text('Débloquer les connexions ?'), findsOneWidget);

          await tester.tap(find.widgetWithText(ElevatedButton, 'Débloquer'));
          await tester.pumpAndSettle();
        },
        () => MockClient(
          (request) => answerAsAdminApi(request, receivedRequests),
        ),
      );

      expect(receivedRequests.first, 'POST /admins/user/7/login/unblock');
      expect(shownMessages, ['Connexions débloquées']);
      expect(find.textContaining('Bloquées jusqu\'au'), findsNothing);
    },
  );

  testWidgets('changes nothing when the unblock is cancelled', (tester) async {
    final receivedRequests = <String>[];
    final blockEnd = DateTime.now().add(const Duration(hours: 5));
    final blockedUser = User.fromJson(
      userJson(loginBlockedUntil: blockEnd.toUtc().toIso8601String()),
    );

    await http.runWithClient(
      () async {
        await openDetailsSheet(tester, blockedUser, usersViewModel, []);

        await tester.ensureVisible(find.text('Débloquer'));
        await tester.tap(find.text('Débloquer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();
      },
      () =>
          MockClient((request) => answerAsAdminApi(request, receivedRequests)),
    );

    expect(receivedRequests, isEmpty);
    expect(find.textContaining('Bloquées jusqu\'au'), findsOneWidget);
  });
}
