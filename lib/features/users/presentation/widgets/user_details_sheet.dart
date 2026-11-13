import 'package:flutter/material.dart';
import 'package:floraccess_app/features/users/presentation/widgets/user_form_dialog.dart';

import '../../models/user.dart';
import '../viewmodels/users_view_model.dart';

class UserDetailsSheet {
  static void show(
    BuildContext context,
    User user,
    UsersViewModel usersViewModel,
    void Function(String) showSnack,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _Sheet(
        user: user,
        usersViewModel: usersViewModel,
        showSnack: showSnack,
      ),
    );
  }

  static Future<void> deleteUser(
    BuildContext context,
    User user,
    UsersViewModel usersViewModel,
    void Function(String) showSnack,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur ?'),
        content: Text(user.email),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final res = await usersViewModel.deleteUser(user.id.toString());
    res.when(success: (_) => showSnack('Supprimé'), error: showSnack);
  }

  /// Unblocks the logins of the user, after a confirmation, then closes the
  /// sheet: the list of the users is reloaded with his new state.
  static Future<void> unblockUserLogin(
    BuildContext context,
    User user,
    UsersViewModel usersViewModel,
    void Function(String) showSnack,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Débloquer les connexions ?'),
        content: Text(
          '${user.email} pourra de nouveau demander un code de connexion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Débloquer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await usersViewModel.unblockUserLogin(user.id.toString());
    result.when(
      success: (_) {
        if (context.mounted) Navigator.of(context).pop();
        showSnack('Connexions débloquées');
      },
      error: showSnack,
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.user,
    required this.usersViewModel,
    required this.showSnack,
  });

  final User user;
  final UsersViewModel usersViewModel;
  final void Function(String) showSnack;

  @override
  Widget build(BuildContext context) {
    /* A bottom sheet takes at most 9/16 of the screen: on a small phone, its rows are scrolled instead of overflowing */
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    user.pseudo,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await UserFormDialog.show(
                        context,
                        initial: user,
                      );
                      if (result == null) return;
                      result.remove('email');
                      final res = await usersViewModel.updateUser(
                        user.id.toString(),
                        result,
                      );
                      res.when(
                        success: (_) => showSnack('Utilisateur mis à jour'),
                        error: showSnack,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => UserDetailsSheet.deleteUser(
                      context,
                      user,
                      usersViewModel,
                      showSnack,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('ID', Text(user.id.toString())),
          _row('Email', Text(user.email)),
          _row('Auth methods', Text(user.authMethodsId.toString())),
          _row(
            'Connecté',
            Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: user.isConnected ? 'Connecté' : 'Non connecté',
                child: Icon(
                  user.isConnected ? Icons.circle : Icons.circle_outlined,
                  color: user.isConnected ? Colors.green : Colors.grey,
                  size: 14,
                ),
              ),
            ),
          ),
          _row(
            'Email vérifié',
            Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: user.isVerifiedEmail
                    ? 'Email vérifié'
                    : 'Email non vérifié',
                child: Icon(
                  user.isVerifiedEmail ? Icons.verified : Icons.mail,
                  color: user.isVerifiedEmail ? Colors.green : Colors.orange,
                  size: 16,
                ),
              ),
            ),
          ),
          _row('Connexions', _loginBlockState(context)),
          _row('Dernière IP', Text(user.lastIp ?? '-')),
          _row('Connexion', Text(_formatDate(user.lastLogin))),
          _row('Déconnexion', Text(_formatDate(user.lastLogoutAt))),
          _row('Créé le', Text(_formatDate(user.createdAt))),
          _row('Mis à jour le', Text(_formatDate(user.updatedAt))),
        ],
      ),
    );
  }

  /// Shows if the user can log in, and offers to unblock his logins when they
  /// are blocked.
  Widget _loginBlockState(BuildContext context) {
    if (!user.isLoginBlocked) return const Text('Autorisées');

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        const Icon(Icons.lock, color: Colors.red, size: 16),
        Text('Bloquées jusqu\'au ${_formatDate(user.loginBlockedUntil)}'),
        TextButton.icon(
          icon: const Icon(Icons.lock_open),
          label: const Text('Débloquer'),
          onPressed: () => UserDetailsSheet.unblockUserLogin(
            context,
            user,
            usersViewModel,
            showSnack,
          ),
        ),
      ],
    );
  }

  Widget _row(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label)),
          Expanded(child: child),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    /* format to DD Mounth YYYY HH:MM */
    /* The API gives the dates in UTC: they are shown in the time zone of the administrator */
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')} '
        '${_monthName(localDate.month)} '
        '${localDate.year} '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month - 1];
  }
}
