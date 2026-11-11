import 'package:floraccess_app/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Sends a GET request with a client whose JWT is [jwt], to a fake API which always answers [statusCode].
/// Returns the number of times the client closed the session.
Future<int> countSessionClosings({
  required String? jwt,
  required int statusCode,
}) async {
  var sessionClosings = 0;
  final apiClient = ApiClient(
    baseUrl: 'http://api.test',
    tokenProvider: () async => jwt,
  );
  apiClient.onUnauthorized = () async => sessionClosings++;

  await http.runWithClient(
    () => apiClient.get('/users'),
    () => MockClient((_) async => http.Response('"Refused"', statusCode)),
  );

  return sessionClosings;
}

void main() {
  group('ApiClient session closing', () {
    test('closes the session when the API refuses the JWT', () async {
      expect(
        await countSessionClosings(jwt: 'expired-jwt', statusCode: 401),
        1,
      );
    });

    test('keeps the user on his page when a request without JWT is refused, like a wrong login code', () async {
      expect(await countSessionClosings(jwt: null, statusCode: 401), 0);
      expect(await countSessionClosings(jwt: '', statusCode: 401), 0);
    });

    test('keeps the session for the other refusals', () async {
      expect(await countSessionClosings(jwt: 'valid-jwt', statusCode: 403), 0);
      expect(await countSessionClosings(jwt: 'valid-jwt', statusCode: 200), 0);
    });
  });
}
