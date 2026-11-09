import 'package:floraccess_app/config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../shared/app_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.authViewModel,
    required this.appState,
  });

  final AuthViewModel authViewModel;
  final AppState appState;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_handleAppStateChanged);
    widget.authViewModel.loadProfile();
    _loadAppVersion();
  }

  @override
  void dispose() {
    widget.appState.removeListener(_handleAppStateChanged);
    super.dispose();
  }

  void _handleAppStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
      });
    } catch (_) {
      // Ignore version lookup failures; version display is optional.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(Config.appName),
      ),
      body: AnimatedBuilder(
        animation: widget.authViewModel,
        builder: (_, _) {
          final profile = widget.authViewModel.profile;
          final error = widget.authViewModel.error;
          final isLoading = widget.authViewModel.isLoading;
          final themeMode = widget.appState.themeMode;

          if (isLoading && profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => widget.authViewModel.loadProfile(),
                    child: const Text('Recharger le profil'),
                  ),
                ],
              ),
            );
          }

          final colorScheme = Theme.of(context).colorScheme;
          final backgroundColor =
              Theme.of(context).appBarTheme.backgroundColor ??
              colorScheme.primary;
          final textColor =
              ThemeData.estimateBrightnessForColor(backgroundColor) ==
                  Brightness.dark
              ? Colors.white
              : Colors.black;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: backgroundColor,
                  child: Text(
                    _initials(
                      profile.pseudo.isNotEmpty
                          ? profile.pseudo
                          : profile.email,
                    ),
                    style: TextStyle(fontSize: 40, color: textColor),
                  ),
                ),
                const SizedBox(height: 30),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Pseudo'),
                          subtitle: Text(
                            profile.pseudo.isNotEmpty ? profile.pseudo : '—',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showEditPseudoDialog(profile.pseudo),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(profile.email),
                        ),
                        ListTile(
                          leading: const Icon(Icons.verified_user),
                          title: const Text('Email vérifié'),
                          trailing: Icon(
                            profile.isVerifiedEmail
                                ? Icons.check_circle
                                : Icons.error,
                            color: profile.isVerifiedEmail
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Compte créé le'),
                          subtitle: Text(
                            _formatDate(profile.createdAt, dateOnly: true),
                          ),
                        ),
                        if (profile.lastLogoutAt != null)
                          ListTile(
                            leading: const Icon(Icons.exit_to_app),
                            title: const Text('Dernière déconnexion'),
                            subtitle: Text(_formatDate(profile.lastLogoutAt)),
                          ),
                        ListTile(
                          leading: const Icon(Icons.wifi),
                          title: const Text('Statut'),
                          subtitle: Text(
                            profile.isConnected ? 'Connecté' : 'Hors ligne',
                          ),
                          trailing: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: profile.isConnected
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.brightness_6_outlined),
                          title: const Text('Thème'),
                          subtitle: Text(_themeLabel(themeMode)),
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<ThemeMode>(
                              value: themeMode,
                              items: const [
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text('Auto'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text('Clair'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text('Sombre'),
                                ),
                              ],
                              onChanged: (mode) async {
                                if (mode == null) return;
                                await widget.appState.setThemeMode(mode);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _confirmLogoutLocal,
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Se déconnecter'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _confirmLogoutEverywhere,
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter de tous les appareils'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_appVersion != null)
                  Text(
                    'Version : $_appVersion',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditPseudoDialog(String currentPseudo) async {
    final newPseudo = await showDialog<String>(
      context: context,
      builder: (_) => _EditPseudoDialog(initialPseudo: currentPseudo),
    );
    if (newPseudo == null || newPseudo.isEmpty) return;
    await _updatePseudo(newPseudo);
  }

  Future<void> _updatePseudo(String newPseudo) async {
    final email = widget.authViewModel.profile?.email;
    if (email == null) return;

    await widget.authViewModel.updatePseudo(email, newPseudo);
    if (!mounted) return;

    final error = widget.authViewModel.error;
    final messenger = ScaffoldMessenger.of(context);
    if (error == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Pseudo mis à jour')),
      );
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _confirmLogoutLocal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter sur cet appareil ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    await widget.authViewModel.logoutLocal();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _confirmLogoutEverywhere() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Déconnexion globale'),
          content: const Text(
            'Voulez-vous déconnecter tous les appareils associés à votre compte ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    await widget.authViewModel.logoutEverywhere();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (widget.authViewModel.error == null) {
      context.go('/login');
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(widget.authViewModel.error!)),
      );
    }
  }

  String _initials(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts[0].substring(0, 1).toUpperCase();
    final second = parts[1].substring(0, 1).toUpperCase();
    return '$first$second';
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Auto';
    }
  }

  String _formatDate(DateTime? date, {bool dateOnly = false}) {
    if (date == null) return '—';
    final pattern = dateOnly ? 'dd/MM/yyyy' : 'dd/MM/yyyy HH:mm';
    return DateFormat(pattern).format(date.toLocal());
  }
}

class _EditPseudoDialog extends StatefulWidget {
  const _EditPseudoDialog({required this.initialPseudo});

  final String initialPseudo;

  @override
  State<_EditPseudoDialog> createState() => _EditPseudoDialogState();
}

class _EditPseudoDialogState extends State<_EditPseudoDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPseudo);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _errorText = 'Le pseudo ne peut pas être vide';
      });
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le pseudo'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'Nouveau pseudo',
          errorText: _errorText,
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }
}
