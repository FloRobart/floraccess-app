import 'package:flutter/material.dart';

class CustomEmailDialog extends StatefulWidget {
  const CustomEmailDialog({super.key});

  static Future<(String subject, String content)?> show(BuildContext context) {
    return showDialog<(String, String)>(
      context: context,
      builder: (_) => const CustomEmailDialog(),
    );
  }

  @override
  State<CustomEmailDialog> createState() => _CustomEmailDialogState();
}

class _CustomEmailDialogState extends State<CustomEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Envoyer un email'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(labelText: 'Objet'),
              validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Objet obligatoire',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentCtrl,
              decoration: const InputDecoration(labelText: 'Contenu'),
              maxLines: 5,
              validator: (v) =>
                  v != null && v.isNotEmpty ? null : 'Contenu obligatoire',
            ),
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
              Navigator.of(context)
                  .pop((_subjectCtrl.text.trim(), _contentCtrl.text.trim()));
            }
          },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
