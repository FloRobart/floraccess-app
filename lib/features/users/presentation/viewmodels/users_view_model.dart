import 'package:flutter/material.dart';

import '../../../../core/utils/result.dart';
import '../../data/user_repository.dart';
import '../../models/user.dart';

class UsersViewModel extends ChangeNotifier {
  UsersViewModel(this._repository);

  final UserRepository _repository;

  List<User> _users = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  final int _pageSize = 10;
  String _search = '';
  bool? _filterConnected;
  bool? _filterVerified;

  List<User> get users => _users;
  Set<int> get selectedIds => _selectedIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get page => _page;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  int get pageSize => _pageSize;
  String get search => _search;
  bool? get filterConnected => _filterConnected;
  bool? get filterVerified => _filterVerified;

  Future<void> load() async {
    _setLoading(true);
    final result = await _repository.fetchUsers(
      page: _page,
      pageSize: _pageSize,
      search: _search.isEmpty ? null : _search,
      isConnected: _filterConnected,
      isVerifiedEmail: _filterVerified,
    );
    _setLoading(false);
    result.when(
      success: (data) {
        _users = data.users;
        _totalPages = data.totalPages;
        _totalCount = data.totalCount;
        _error = null;
        _selectedIds.clear();
        notifyListeners();
      },
      error: (msg) {
        _error = msg;
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    _page = 1;
    await load();
  }

  void updateSearch(String value) {
    _search = value;
    _page = 1;
    notifyListeners();
  }

  void updateFilters({bool? connected, bool? verified}) {
    _filterConnected = connected;
    _filterVerified = verified;
    _page = 1;
    notifyListeners();
  }

  Future<void> goToPage(int newPage) async {
    _page = newPage.clamp(1, _totalPages);
    await load();
  }

  void toggleSelection(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  Future<Result<User>> createUser({
    required String email,
    required String pseudo,
  }) async {
    _setLoading(true);
    final result = await _repository.createUser(email: email, pseudo: pseudo);
    _setLoading(false);
    result.when(success: (_) => load(), error: (_) {});
    return result;
  }

  Future<Result<User>> updateUser(
    String id,
    Map<String, dynamic> payload,
  ) async {
    _setLoading(true);
    final result = await _repository.updateUser(id, payload);
    _setLoading(false);
    result.when(success: (_) => load(), error: (_) {});
    return result;
  }

  Future<Result<User>> unblockUserLogin(String id) async {
    _setLoading(true);
    final result = await _repository.unblockUserLogin(id);
    _setLoading(false);
    result.when(success: (_) => load(), error: (_) {});
    return result;
  }

  Future<Result<void>> deleteUser(String id) async {
    _setLoading(true);
    final result = await _repository.deleteUser(id);
    _setLoading(false);
    result.when(success: (_) => load(), error: (_) {});
    return result;
  }

  Future<Result<void>> resendVerification() async {
    _setLoading(true);
    final result = await _repository.resendVerification(_selectedIds.toList());
    _setLoading(false);
    return result;
  }

  Future<Result<void>> sendCustomEmail({
    required String subject,
    required String content,
  }) async {
    _setLoading(true);
    final result = await _repository.sendCustomEmail(
      userIds: _selectedIds.toList(),
      subject: subject,
      content: content,
    );
    _setLoading(false);
    return result;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
