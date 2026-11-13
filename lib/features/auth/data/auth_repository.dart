import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/utils/debug_log.dart';
import '../../../core/utils/result.dart';
import '../../users/models/user.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  /// Explains why the API refused to send a login code, from the status of its answer.
  static String _loginRequestErrorMessage(int statusCode) =>
      switch (statusCode) {
        400 => 'Adresse email invalide',
        403 => 'Les connexions sont temporairement bloquées pour ce compte',
        429 => 'Trop de demandes : patientez avant de demander un nouveau code',
        501 => 'La méthode de connexion de ce compte n\'est pas disponible',
        503 => 'Service momentanément indisponible, réessayez plus tard',
        _ => 'Impossible d\'envoyer le code, réessayez plus tard',
      };

  /// Explains why the API refused the login code, from the status of its answer.
  static String _loginConfirmErrorMessage(int statusCode) =>
      switch (statusCode) {
        400 || 401 => 'Code invalide ou expiré',
        403 => 'Les connexions sont temporairement bloquées pour ce compte',
        429 => 'Trop d\'essais : demandez un nouveau code',
        _ => 'Connexion impossible, réessayez plus tard',
      };

  Future<Result<String>> loginRequest(String email) async {
    try {
      final response = await _client.post(
        '/users/login/request',
        body: {'email': email},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Success(decoded['token'] as String);
      }
      return Failure(_loginRequestErrorMessage(response.statusCode));
    } catch (e, st) {
      logErrorInDebug('loginRequest', e, st);
      return Failure('Erreur réseau inattendue');
    }
  }

  Future<Result<String>> loginConfirm({
    required String email,
    required String code,
    required String requestToken,
  }) async {
    try {
      final response = await _client.post(
        '/users/login/confirm',
        body: {'email': email, 'secret': code, 'token': requestToken},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Success(decoded['jwt'] as String);
      }
      return Failure(_loginConfirmErrorMessage(response.statusCode));
    } catch (e, st) {
      logErrorInDebug('loginConfirm', e, st);
      return Failure('Erreur réseau inattendue');
    }
  }

  Future<Result<void>> logoutAll() async {
    try {
      final response = await _client.post('/users/logout');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      }
      return Failure('Impossible de déconnecter les sessions');
    } catch (e, st) {
      logErrorInDebug('logoutAll', e, st);
      return Failure('Erreur réseau inattendue');
    }
  }

  Future<Result<User>> fetchProfile() async {
    try {
      final response = await _client.get('/users');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Success(User.fromJson(decoded));
      }
      return Failure('Profil introuvable');
    } catch (e, st) {
      logErrorInDebug('fetchProfile', e, st);
      return Failure('Erreur réseau inattendue');
    }
  }

  Future<Result<({User user, String? jwt})>> updatePseudo(
    String email,
    String pseudo,
  ) async {
    try {
      final response = await _client.put(
        '/users',
        body: {'email': email, 'pseudo': pseudo},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final userPayload = decoded['user'];
        final Map<String, dynamic> userJson;
        if (userPayload is Map<String, dynamic>) {
          userJson = userPayload;
        } else if (userPayload is Map) {
          userJson = userPayload.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        } else {
          userJson = decoded;
        }
        final jwt = decoded['jwt']?.toString();
        return Success((user: User.fromJson(userJson), jwt: jwt));
      }
      return Failure('Impossible de mettre à jour le pseudo');
    } catch (e, st) {
      logErrorInDebug('updatePseudo', e, st);
      return Failure('Erreur réseau inattendue');
    }
  }
}
