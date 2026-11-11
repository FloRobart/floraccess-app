import 'package:floraccess_app/features/users/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Raw JSON as returned by the admin routes of the FlorAccess API
  final Map<String, dynamic> userJson = {
    'id': 7,
    'email': 'user@example.com',
    'pseudo': 'user',
    'auth_methods_id': 2,
    'is_connected': true,
    'is_verified_email': false,
    'last_login': '2026-10-15T10:30:00.000Z',
    'last_logout_at': '2026-10-14T08:00:00.000Z',
    'last_ip': '192.168.1.10',
    'created_at': '2026-01-02T03:04:05.000Z',
    'updated_at': '2026-10-15T10:30:00.000Z',
  };

  group('User.fromJson', () {
    test('parses the snake_case keys of the API into the fields', () {
      final user = User.fromJson(userJson);

      expect(user.id, 7);
      expect(user.email, 'user@example.com');
      expect(user.pseudo, 'user');
      expect(user.authMethodsId, 2);
      expect(user.isConnected, isTrue);
      expect(user.isVerifiedEmail, isFalse);
      expect(user.lastIp, '192.168.1.10');
    });

    test('converts the ISO dates into UTC DateTime objects', () {
      final user = User.fromJson(userJson);

      expect(user.lastLogin, DateTime.utc(2026, 10, 15, 10, 30));
      expect(user.lastLogoutAt, DateTime.utc(2026, 10, 14, 8));
      expect(user.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
      expect(user.updatedAt, DateTime.utc(2026, 10, 15, 10, 30));
    });

    test('reads timestamps given in seconds or in milliseconds', () {
      const secondsSinceEpoch = 1760000000;
      const millisecondsSinceEpoch = secondsSinceEpoch * 1000;

      final userFromSeconds = User.fromJson({
        ...userJson,
        'last_login': secondsSinceEpoch,
      });
      final userFromMilliseconds = User.fromJson({
        ...userJson,
        'last_login': millisecondsSinceEpoch,
      });

      expect(userFromSeconds.lastLogin, userFromMilliseconds.lastLogin);
      expect(
        userFromMilliseconds.lastLogin!.millisecondsSinceEpoch,
        millisecondsSinceEpoch,
      );
    });

    test('accepts the numbers and booleans written as text', () {
      final user = User.fromJson({
        ...userJson,
        'id': '7',
        'auth_methods_id': '2',
        'is_connected': 'TRUE',
        'is_verified_email': 1,
      });

      expect(user.id, 7);
      expect(user.authMethodsId, 2);
      expect(user.isConnected, isTrue);
      expect(user.isVerifiedEmail, isTrue);
    });

    test('falls back to neutral values when the fields are missing', () {
      final user = User.fromJson(const {});

      expect(user.id, 0);
      expect(user.email, '');
      expect(user.pseudo, '');
      expect(user.isConnected, isFalse);
      expect(user.lastLogin, isNull);
      expect(user.lastIp, isNull);
      expect(user.loginBlockedUntil, isNull);
    });

    test('reads the end of the block of the logins', () {
      final user = User.fromJson({
        ...userJson,
        'login_blocked_until': '2026-10-16T10:30:00.000Z',
      });

      expect(user.loginBlockedUntil, DateTime.utc(2026, 10, 16, 10, 30));
    });
  });

  group('User.isLoginBlocked', () {
    /// Builds a user whose logins are blocked until [blockEnd].
    User userBlockedUntil(DateTime blockEnd) {
      return User.fromJson({
        ...userJson,
        'login_blocked_until': blockEnd.toUtc().toIso8601String(),
      });
    }

    test('is false when the logins were never blocked', () {
      expect(User.fromJson(userJson).isLoginBlocked, isFalse);
    });

    test('is true until the end of the block', () {
      final blockEnd = DateTime.now().add(const Duration(hours: 1));

      expect(userBlockedUntil(blockEnd).isLoginBlocked, isTrue);
    });

    test('is false once the block is over, without any action', () {
      final blockEnd = DateTime.now().subtract(const Duration(hours: 1));

      expect(userBlockedUntil(blockEnd).isLoginBlocked, isFalse);
    });
  });

  group('User equality', () {
    test('two users built from the same JSON are equal', () {
      expect(User.fromJson(userJson), User.fromJson(userJson));
    });

    test('a different pseudo makes two users different', () {
      final renamedUser = User.fromJson({...userJson, 'pseudo': 'renamed'});

      expect(renamedUser, isNot(User.fromJson(userJson)));
    });

    test('a different block of the logins makes two users different', () {
      final blockedUser = User.fromJson({
        ...userJson,
        'login_blocked_until': '2026-10-16T10:30:00.000Z',
      });

      expect(blockedUser, isNot(User.fromJson(userJson)));
    });
  });
}
