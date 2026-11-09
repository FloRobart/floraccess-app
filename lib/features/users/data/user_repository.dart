import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
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
      debugPrint('fetchUsers error: $e\n$st');
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

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure('Impossible de créer l\'utilisateur');
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return Success(User.fromJson(data));
      }

      return Failure('Format de réponse invalide');
    } catch (e, st) {
      debugPrint('createUser error: $e\n$st');
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
      debugPrint('updateUser error: $e\n$st');
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
      debugPrint('deleteUser error: $e\n$st');
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
      return Failure('Impossible d\'envoyer l\'email de vérification');
    } catch (e, st) {
      debugPrint('resendVerification error: $e\n$st');
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
      return Failure('Impossible d\'envoyer l\'email personnalisé');
    } catch (e, st) {
      debugPrint('sendCustomEmail error: $e\n$st');
      return Failure('Erreur réseau inattendue');
    }
  }
}
