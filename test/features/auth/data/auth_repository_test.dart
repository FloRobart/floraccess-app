import 'dart:convert';

import 'package:floraccess_app/core/network/api_client.dart';
import 'package:floraccess_app/core/utils/result.dart';
import 'package:floraccess_app/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Runs a request of the repository against a fake API which always answers [statusCode] with [body].
Future<Result<T>> requestWithApiAnswer<T>(
  int statusCode,
  Future<Result<T>> Function(AuthRepository repository) request, {
  Object body = 'Message of the API',
}) {
  final repository = AuthRepository(
    ApiClient(baseUrl: 'http://api.test', tokenProvider: () async => null),
  );

  return http.runWithClient(
    () => request(repository),
    () => MockClient((_) async => http.Response(jsonEncode(body), statusCode)),
  );
}

/// Reads the message of a failed result, or "success".
String messageOf<T>(Result<T> result) {
  return result.when(success: (_) => 'success', error: (message) => message);
}

void main() {
  group('AuthRepository.loginRequest', () {
    test('gives the token of the login code sent by the API', () async {
      final result = await requestWithApiAnswer(
        200,
        (repository) => repository.loginRequest('test@test.fr'),
        body: {'token': 'login-token'},
      );

      expect(
        result.when(success: (token) => token, error: (message) => message),
        'login-token',
      );
    });

    test(
      'explains each refusal of the API, not always "Email non reconnu"',
      () async {
        const expectedMessages = {
          400: 'Adresse email invalide',
          403: 'Les connexions sont temporairement bloquées pour ce compte',
          429: 'Trop de demandes : patientez avant de demander un nouveau code',
          501: 'La méthode de connexion de ce compte n\'est pas disponible',
          503: 'Service momentanément indisponible, réessayez plus tard',
          500: 'Impossible d\'envoyer le code, réessayez plus tard',
        };

        for (final expected in expectedMessages.entries) {
          final result = await requestWithApiAnswer(
            expected.key,
            (repository) => repository.loginRequest('test@test.fr'),
          );

          expect(
            messageOf(result),
            expected.value,
            reason: 'HTTP ${expected.key}',
          );
        }
      },
    );
  });

  group('AuthRepository.loginConfirm', () {
    test(
      'explains each refusal of the API, not always "Code invalide"',
      () async {
        const expectedMessages = {
          400: 'Code invalide ou expiré',
          401: 'Code invalide ou expiré',
          403: 'Les connexions sont temporairement bloquées pour ce compte',
          429: 'Trop d\'essais : demandez un nouveau code',
          500: 'Connexion impossible, réessayez plus tard',
        };

        for (final expected in expectedMessages.entries) {
          final result = await requestWithApiAnswer(
            expected.key,
            (repository) => repository.loginConfirm(
              email: 'test@test.fr',
              code: '123456',
              requestToken: 'login-token',
            ),
          );

          expect(
            messageOf(result),
            expected.value,
            reason: 'HTTP ${expected.key}',
          );
        }
      },
    );
  });
}
