import 'dart:math';

import 'package:floraccess_app/config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/app_state.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../models/user.dart';
import '../../presentation/viewmodels/users_view_model.dart';
import '../widgets/custom_email_dialog.dart';
import '../widgets/user_details_sheet.dart';
import '../widgets/user_form_dialog.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({
    super.key,
    required this.usersViewModel,
    required this.authViewModel,
    required this.appState,
  });

  final UsersViewModel usersViewModel;
  final AuthViewModel authViewModel;
  final AppState appState;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.usersViewModel.load();
    widget.authViewModel.loadProfile();
    _searchCtrl.text = widget.usersViewModel.search;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Config.appName),
        actions: [
          AnimatedBuilder(
            animation: widget.authViewModel,
            builder: (context, _) {
              final profile = widget.authViewModel.profile;
              final displayName = profile?.pseudo ?? profile?.email ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: InkWell(
                  onTap: () => context.go('/profile'),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        if (displayName.isNotEmpty) Text(displayName),
                        const SizedBox(width: 8),
                        const Icon(Icons.person),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.usersViewModel,
        builder: (_, _) {
          final vm = widget.usersViewModel;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _ActionsBar(
                  onAdd: _createUser,
                  onResendVerification: vm.selectedIds.isEmpty
                      ? null
                      : () async {
                          final res = await vm.resendVerification();
                          res.when(
                            success: (_) => _showSnack('Emails envoyés'),
                            error: _showSnack,
                          );
                        },
                  onSendEmail: vm.selectedIds.isEmpty
                      ? null
                      : () async {
                          final data = await CustomEmailDialog.show(context);
                          if (data == null) return;
                          final res = await vm.sendCustomEmail(
                            subject: data.$1,
                            content: data.$2,
                          );
                          res.when(
                            success: (_) => _showSnack('Email envoyé'),
                            error: _showSnack,
                          );
                        },
                  selectionCount: vm.selectedIds.length,
                ),
                const SizedBox(height: 8),
                if (vm.error != null)
                  Text(vm.error!, style: const TextStyle(color: Colors.red)),
                if (vm.isLoading) const LinearProgressIndicator(minHeight: 2),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _UsersTable(
                      vm: vm,
                      onDetails: (u) => UserDetailsSheet.show(
                        context,
                        u,
                        widget.usersViewModel,
                        _showSnack,
                      ),
                      onEdit: _editUser,
                      onDelete: (u) => UserDetailsSheet.deleteUser(
                        context,
                        u,
                        widget.usersViewModel,
                        _showSnack,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Pagination(
                  current: vm.page,
                  totalPages: vm.totalPages,
                  totalCount: vm.totalCount,
                  pageSize: vm.pageSize,
                  onChanged: (p) => vm.goToPage(p),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createUser() async {
    final result = await UserFormDialog.show(context);
    if (result == null) return;
    final res = await widget.usersViewModel.createUser(
      email: result['email'] as String,
      pseudo: result['pseudo'] as String,
    );
    res.when(success: (_) => _showSnack('Utilisateur créé'), error: _showSnack);
  }

  Future<void> _editUser(User user) async {
    final result = await UserFormDialog.show(context, initial: user);
    if (result == null) return;
    final res = await widget.usersViewModel.updateUser(
      user.id.toString(),
      result,
    );
    res.when(
      success: (_) => _showSnack('Utilisateur mis à jour'),
      error: _showSnack,
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ActionsBar extends StatelessWidget {
  const _ActionsBar({
    required this.onAdd,
    required this.onResendVerification,
    required this.onSendEmail,
    required this.selectionCount,
  });

  final VoidCallback onAdd;
  final VoidCallback? onResendVerification;
  final VoidCallback? onSendEmail;
  final int selectionCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
            ElevatedButton.icon(
              onPressed: onResendVerification,
              icon: const Icon(Icons.mark_email_unread),
              label: const Text('Renvoyer vérification'),
            ),
            OutlinedButton.icon(
              onPressed: onSendEmail,
              icon: const Icon(Icons.email),
              label: const Text('Email personnalisé'),
            ),
            Container(
              margin: const EdgeInsets.only(left: 16),
              child: Text('Sélection: $selectionCount'),
            ),
          ],
        );
      },
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.vm,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final UsersViewModel vm;
  final void Function(User) onDetails;
  final void Function(User) onEdit;
  final void Function(User) onDelete;

  @override
  Widget build(BuildContext context) {
    final sortedUsers = List<User>.from(vm.users)
      ..sort((a, b) => a.id.compareTo(b.id));
    final rows = sortedUsers
        .map(
          (u) => DataRow(
            selected: vm.selectedIds.contains(u.id),
            onSelectChanged: (_) => vm.toggleSelection(u.id),
            cells: [
              DataCell(
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(u.id.toString()),
                ),
              ),
              DataCell(
                Tooltip(
                  message: u.isConnected ? 'Connecté' : 'Non connecté',
                  child: Icon(
                    u.isConnected ? Icons.circle : Icons.circle_outlined,
                    color: u.isConnected ? Colors.green : Colors.grey,
                    size: 14,
                  ),
                ),
              ),
              DataCell(
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (u.isLoginBlocked)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Tooltip(
                            message: 'Connexions bloquées',
                            child: Icon(
                              Icons.lock,
                              color: Colors.red,
                              size: 14,
                            ),
                          ),
                        ),
                      Text(u.pseudo),
                    ],
                  ),
                ),
                onTap: () => onDetails(u),
              ),
              DataCell(
                Tooltip(
                  message: u.isVerifiedEmail
                      ? 'Email vérifié'
                      : 'Email non vérifié',
                  child: Icon(
                    u.isVerifiedEmail ? Icons.verified : Icons.mail,
                    color: u.isVerifiedEmail ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                ),
              ),
              DataCell(
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => onDetails(u),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => onEdit(u),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculer un espacement dynamique selon la largeur
        final double minSpacing = 8;
        final double maxSpacing = 32;
        final double spacing = (constraints.maxWidth / 40).clamp(
          minSpacing,
          maxSpacing,
        );
        return SizedBox(
          width: constraints.maxWidth,
          child: DataTable(
            columnSpacing: spacing,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(
                label: Tooltip(
                  message: 'Connecté / Non connecté',
                  child: Text('C'),
                ),
              ),
              DataColumn(label: Text('Pseudo')),
              DataColumn(
                label: Tooltip(
                  message: 'Email vérifié / Non vérifié',
                  child: Text('V'),
                ),
              ),
              DataColumn(label: Text('Actions')),
            ],
            rows: rows,
          ),
        );
      },
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.current,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.onChanged,
  });

  final int current;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Total: $totalCount'),
        const Spacer(),
        IconButton(
          onPressed: current > 1 ? () => onChanged(current - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '${(current - 1) * pageSize + 1} - ${min(current * pageSize, totalCount)} / $totalCount',
        ),
        IconButton(
          onPressed: current < totalPages ? () => onChanged(current + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
