import 'package:flutter/material.dart';

import '../core/storage/local_storage.dart';

class AppState extends ChangeNotifier {
  AppState({required this._storage}) {
    _jwtToken = _storage.readToken();
    _loginEmail = _storage.readLoginEmail();
    _loginRequestToken = _storage.readLoginRequestToken();
    _themeMode = _readThemeMode();
  }

  final LocalStorage _storage;
  String? _jwtToken;
  String? _loginEmail;
  String? _loginRequestToken;
  ThemeMode _themeMode = ThemeMode.system;

  String? get jwtToken => _jwtToken;
  String? get loginEmail => _loginEmail;
  String? get loginRequestToken => _loginRequestToken;
  ThemeMode get themeMode => _themeMode;
  bool get isAuthenticated => _jwtToken != null && _jwtToken!.isNotEmpty;

  Future<void> setJwtToken(String token) async {
    _jwtToken = token;
    await _storage.writeToken(token);
    notifyListeners();
  }

  Future<void> clearJwtToken() async {
    _jwtToken = null;
    await _storage.clearToken();
    notifyListeners();
  }

  Future<void> setLoginEmail(String? email) async {
    _loginEmail = email;
    if (email == null) {
      await _storage.clearLoginEmail();
    } else {
      await _storage.writeLoginEmail(email);
    }
    notifyListeners();
  }

  Future<void> setLoginRequestToken(String? token) async {
    _loginRequestToken = token;
    if (token == null) {
      await _storage.clearLoginRequestToken();
    } else {
      await _storage.writeLoginRequestToken(token);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.writeThemeMode(mode.name);
    notifyListeners();
  }

  ThemeMode _readThemeMode() {
    final stored = _storage.readThemeMode();
    if (stored == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }
}
