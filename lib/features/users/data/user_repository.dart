import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/utils/debug_log.dart';
import '../../../core/utils/result.dart';
import '../models/user.dart';

class PaginatedUsers {
  const PaginatedUsers({
    required this.users,
    required this.page,
    required this.totalPages,
    required this.totalCount,
  });

  final List<User> users;
  final int page;
  final int totalPages;
  final int totalCount;
}

class UserRepository {
  UserRepository(this._client);

  final ApiClient _client;

  /// The API refuses the emails beyond its daily limit, so that its mail account is never blocked,
  /// and keeps the last emails of the day for the login codes of the users.
  static const _emailLimitReachedMessage =
      'Plus assez d\'emails disponibles aujourd\'hui pour cet envoi, réessayez plus tard';

  /// The API accepts a few requests per hour and per IP address on the routes which send emails.
  static const _tooManyEmailRequestsMessage =
      'Trop d\'envois d\'emails depuis cette adresse IP, réessayez dans une heure';

  /// Explains why the API refused to send emails, or gives null for any other answer.
  static String? _emailSendingRefusalMessage(int statusCode) =>
      switch (statusCode) {
        429 => _tooManyEmailRequestsMessage,
        503 => _emailLimitReachedMessage,
        _ => null,
      };

  Future<Result<PaginatedUsers>> fetchUsers({
    int page = 1,
    int pageSize = 10,
    String? search,
    bool? isConnected,
    bool? isVerifiedEmail,
  }) async {
    try {
      /* Fetch users from API */
      final userQuery = <String, String>{
        'limit': pageSize.toString(),
        'offset': ((page - 1) * pageSize).toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (isConnected != null) 'is_connected': isConnected.toString(),
        if (isVerifiedEmail != null)
          'is_verified_email': isVerifiedEmail.toString(),
      };

      final userResponse = await _client.get(
        '/admins/users',
        queryParams: userQuery,
      );
      if (userResponse.statusCode < 200 || userResponse.statusCode >= 300) {
        return Failure('Impossible de récupérer les utilisateurs');
      }

      final userDecoded = jsonDecode(userResponse.body);

      /* Parse users */
      List<User> users = [];
      if (userDecoded is List) {
        users = userDecoded
            .whereType<Map<String, dynamic>>()
            .map(User.fromJson)
            .toList();
      }

      /* Fetch number of users for pagination */
      final userCountResponse = await _client.get('/admins/users/count');
      if (userCountResponse.statusCode < 200 ||
          userCountResponse.statusCode >= 300) {
        return Failure('Impossible de récupérer le nombre d\'utilisateurs');
      }

      final userCountDecoded = jsonDecode(userCountResponse.body);
      int totalCount = userCountDecoded['count'] ?? users.length;
      final totalPages = (totalCount / pageSize).ceil();

      return Success(
        PaginatedUsers(
          users: users,
          page: page,
          totalPages: totalPages,
          totalCount: totalCount,
        ),
      );
    } catch (e, st) {
      logErrorInDebug('fetchUsers', e, st);
      return Failure('Erreur réseau inattendue');
    }
  }

  Future<Result<User>> createUser({
    required String email,
    required String pseudo,
  }) async {
    try {
      final response = await _client.post(
        '/admins/user',
        body: {'email': email, 'pseudo': pseudo},
      );

      if (response.statusCode == 409) {
        return Failure('Un utilisateur utilise déjà cette adresse email');
      }

      final emailRefusalMessage = _emailSendingRefusalMessage(
        response.statusCode,
      );
      if (emailRefusalMessage != null) {
        return Failure(emailRefusalMessage);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure('Impossible de créer l\'utilisateur');
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return Success(User.fromJson(data));
      }

      return Failure('Format de réponse invalide');
    } catch (e, st) {
      logErrorInDebug('createUser', e, st);
      return Failure('Erreur réseau inattendue');
    }
  }

  Future<Result<User>> updateUser(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _client.put('/admins/user/$id', body: payload);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure('Impossible de mettre à jour l\'utilisateur');
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return Success(User.fromJson(data));
      }

      return Failure('Format de réponse invalide');
    } catch (e, st) {
      logErrorInDebug('updateUser', e, st);
      return Failure('Erreur réseau inattendue');
    }
  }

  /// Unblocks the logins of a user, blocked by the link of a login code email
  /// or after too many codes sent without a successful login.
  Future<Result<User>> unblockUserLogin(String id) async {
    try {
      final response = await _client.post('/admins/user/$id/login/unblock');

      if (response.statusCode == 404) {
        return Failure('Utilisateur introuvable');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure('Impossible de débloquer les connexions');
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return Success(User.fromJson(data));
      }

      return Failure('Format de réponse invalide');
    } catch (error, stackTrace) {
      logErrorInDebug('unblockUserLogin', error, stackTrace);
      return Failure('Erreur réseau inattendue');
    }
  }

  Future<Result<void>> deleteUser(String id) async {
    try {
      final response = await _client.delete('/admins/user/$id');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      }

      return Failure('Suppression impossible');
    } catch (e, st) {
      logErrorInDebug('deleteUser', e, st);
      return Failure('Erreur réseau inattendue');
    }
  }

  Future<Result<void>> resendVerification(List<int> userIds) async {
    try {
      final response = await _client.post(
        '/admins/users/send/verify-email',
        body: {'userIdList': userIds},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      }

      final emailRefusalMessage = _emailSendingRefusalMessage(
        response.statusCode,
      );
      if (emailRefusalMessage != null) {
        return Failure(emailRefusalMessage);
      }

      return Failure('Impossible d\'envoyer l\'email de vérification');
    } catch (e, st) {
      logErrorInDebug('resendVerification', e, st);
      return Failure('Erreur réseau inattendue');
    }
  }

  Future<Result<void>> sendCustomEmail({
    required List<int> userIds,
    required String subject,
    required String content,
  }) async {
    try {
      final response = await _client.post(
        '/admins/users/send/email',
        body: {'userIdList': userIds, 'object': subject, 'message': content},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      }

      final emailRefusalMessage = _emailSendingRefusalMessage(
        response.statusCode,
      );
      if (emailRefusalMessage != null) {
        return Failure(emailRefusalMessage);
      }

      return Failure('Impossible d\'envoyer l\'email personnalisé');
    } catch (e, st) {
      logErrorInDebug('sendCustomEmail', e, st);
      return Failure('Erreur réseau inattendue');
    }
  }
}
