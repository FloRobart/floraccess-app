import 'package:flutter/material.dart';

import '../../models/user.dart';

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({super.key, this.initial});

  final User? initial;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    User? initial,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => UserFormDialog(initial: initial),
    );
  }

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _pseudoCtrl;
  late final TextEditingController _authMethodCtrl;
  bool _verified = false;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initial?.email ?? '');
    _pseudoCtrl = TextEditingController(text: widget.initial?.pseudo ?? '');
    _authMethodCtrl = TextEditingController(
      text: widget.initial?.authMethodsId.toString() ?? '0',
    );
    _verified = widget.initial?.isVerifiedEmail ?? false;
    _connected = widget.initial?.isConnected ?? false;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pseudoCtrl.dispose();
    _authMethodCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Email invalide',
              readOnly: !isEdit,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pseudoCtrl,
              decoration: const InputDecoration(labelText: 'Pseudo'),
              validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Le pseudo est requis',
            ),
            if (isEdit) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _authMethodCtrl,
                decoration: const InputDecoration(
                  labelText: 'Auth methods id (optionnel)',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Email vérifié'),
                value: _verified,
                onChanged: (v) => setState(() => _verified = v),
              ),
              SwitchListTile(
                title: const Text('Connecté'),
                value: _connected,
                onChanged: (v) => setState(() => _connected = v),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop({
                'email': _emailCtrl.text.trim(),
                'pseudo': _pseudoCtrl.text.trim(),
                'auth_methods_id':
                    isEdit && _authMethodCtrl.text.trim().isNotEmpty
                    ? int.tryParse(_authMethodCtrl.text.trim())
                    : null,
                'is_connected': isEdit ? _connected : null,
                'is_verified_email': isEdit ? _verified : null,
              });
            }
          },
          child: Text(isEdit ? 'Mettre à jour' : 'Créer'),
        ),
      ],
    );
  }
}
