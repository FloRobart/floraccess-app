import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.pseudo,
    required this.authMethodsId,
    required this.isConnected,
    required this.isVerifiedEmail,
    this.lastLogin,
    this.lastLogoutAt,
    this.lastIp,
    this.createdAt,
    this.updatedAt,
    this.loginBlockedUntil,
  });

  final int id;
  final String email;
  final String pseudo;
  final int authMethodsId;
  final bool isConnected;
  final bool isVerifiedEmail;
  final DateTime? lastLogin;
  final DateTime? lastLogoutAt;
  final String? lastIp;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// End of the block of the logins, set by the block link of a login code
  /// email or after too many codes sent without a successful login.
  final DateTime? loginBlockedUntil;

  /// Tells if the logins of the user are blocked right now: a block ends by
  /// itself, so a date in the past means that the user can log in again.
  bool get isLoginBlocked {
    final blockEnd = loginBlockedUntil;
    if (blockEnd == null) return false;

    return blockEnd.isAfter(DateTime.now());
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _asInt(json['id']),
      email: _asString(json['email']),
      pseudo: _asString(json['pseudo']),
      authMethodsId: _asInt(json['auth_methods_id']),
      isConnected: _asBool(json['is_connected']),
      isVerifiedEmail: _asBool(json['is_verified_email']),
      lastLogin: _parseDate(json['last_login']),
      lastLogoutAt: _parseDate(json['last_logout_at']),
      lastIp: json['last_ip']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      loginBlockedUntil: _parseDate(json['login_blocked_until']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    pseudo,
    authMethodsId,
    isConnected,
    isVerifiedEmail,
    lastLogin,
    lastLogoutAt,
    lastIp,
    createdAt,
    updatedAt,
    loginBlockedUntil,
  ];
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) {
    return value < 10000000000
        ? DateTime.fromMillisecondsSinceEpoch(value * 1000)
        : DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _asString(dynamic value) => value?.toString() ?? '';

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  return false;
}
