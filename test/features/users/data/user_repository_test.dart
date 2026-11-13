import 'dart:convert';

import 'package:floraccess_app/core/network/api_client.dart';
import 'package:floraccess_app/core/utils/result.dart';
import 'package:floraccess_app/features/users/data/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Result of a request of the repository, with the request the API received.
typedef RepositoryCall<T> = ({Result<T> result, http.Request request});

/// Runs a request of the repository against a fake API which always answers
/// [statusCode] with [body].
Future<RepositoryCall<T>> callWithApiAnswer<T>(
  int statusCode,
  Future<Result<T>> Function(UserRepository repository) request, {
  Object body = 'Message of the API',
}) async {
  final repository = UserRepository(
    ApiClient(
      baseUrl: 'http://api.test',
      tokenProvider: () async => 'administrator-jwt',
    ),
  );

  late http.Request receivedRequest;
  final result = await http.runWithClient(
    () => request(repository),
    () => MockClient((request) async {
      receivedRequest = request;
      return http.Response(jsonEncode(body), statusCode);
    }),
  );

  return (result: result, request: receivedRequest);
}

/// Reads the message of a failed result, or "success".
String messageOf<T>(Result<T> result) {
  return result.when(success: (_) => 'success', error: (message) => message);
}

void main() {
  // Raw JSON as returned by the admin routes of the FlorAccess API
  final Map<String, dynamic> unblockedUserJson = {
    'id': 7,
    'email': 'user@example.com',
    'pseudo': 'user',
    'auth_methods_id': 2,
    'is_connected': true,
    'is_verified_email': true,
    'login_blocked_until': null,
  };

  group('UserRepository.unblockUserLogin', () {
    test(
      'asks the API to unblock the user of the ID, as an administrator',
      () async {
        final call = await callWithApiAnswer(
          200,
          (repository) => repository.unblockUserLogin('7'),
          body: unblockedUserJson,
        );

        expect(call.request.method, 'POST');
        expect(call.request.url.path, '/admins/user/7/login/unblock');
        expect(
          call.request.headers['Authorization'],
          'Bearer administrator-jwt',
        );
      },
    );

    test('gives back the user with his new state', () async {
      final call = await callWithApiAnswer(
        200,
        (repository) => repository.unblockUserLogin('7'),
        body: unblockedUserJson,
      );

      final unblockedUser = call.result.when(
        success: (user) => user,
        error: (message) => fail(message),
      );
      expect(unblockedUser.id, 7);
      expect(unblockedUser.isLoginBlocked, isFalse);
    });

    test('explains why the logins could not be unblocked', () async {
      const expectedMessages = {
        404: 'Utilisateur introuvable',
        403: 'Impossible de débloquer les connexions',
        500: 'Impossible de débloquer les connexions',
      };

      for (final expected in expectedMessages.entries) {
        final call = await callWithApiAnswer(
          expected.key,
          (repository) => repository.unblockUserLogin('7'),
        );

        expect(
          messageOf(call.result),
          expected.value,
          reason: 'HTTP ${expected.key}',
        );
      }
    });

    test('refuses an answer which is not a user', () async {
      final call = await callWithApiAnswer(
        200,
        (repository) => repository.unblockUserLogin('7'),
        body: const <Object>[],
      );

      expect(messageOf(call.result), 'Format de réponse invalide');
    });
  });

  group('UserRepository email sendings', () {
    final emailSendings =
        <String, Future<Result<Object?>> Function(UserRepository)>{
          'createUser': (repository) =>
              repository.createUser(email: 'user@example.com', pseudo: 'user'),
          'resendVerification': (repository) =>
              repository.resendVerification([7]),
          'sendCustomEmail': (repository) => repository.sendCustomEmail(
            userIds: [7],
            subject: 'Maintenance',
            content: 'The API will be stopped tonight.',
          ),
        };

    test('explains the limit of the requests which send emails, and the emails kept for the login codes', () async {
      const expectedMessages = {
        429: 'Trop d\'envois d\'emails depuis cette adresse IP, réessayez dans une heure',
        503: 'Plus assez d\'emails disponibles aujourd\'hui pour cet envoi, réessayez plus tard',
      };

      for (final sending in emailSendings.entries) {
        for (final expected in expectedMessages.entries) {
          final call = await callWithApiAnswer(expected.key, sending.value);

          expect(
            messageOf(call.result),
            expected.value,
            reason: '${sending.key}, HTTP ${expected.key}',
          );
        }
      }
    });
  });
}
