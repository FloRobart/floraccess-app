import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../legal_notice_content.dart';

/// Path of the legal notice. It is reachable without being logged in: the
/// legal notice must be readable by anyone.
const String legalNoticePath = '/legal';

/// Page of the legal notice and of the protection of the personal data.
class LegalNoticePage extends StatelessWidget {
  const LegalNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _goBack(context),
        ),
        title: const Text('Mentions légales'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          /* Long lines are hard to read on a wide screen */
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final section in LegalNoticeContent.sections)
                  _buildSection(section, textTheme),
                Text(
                  'Dernière mise à jour : ${LegalNoticeContent.lastUpdate}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(LegalNoticeSection section, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final paragraph in section.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              /* Selectable, so that the contact address can be copied */
              child: SelectableText(paragraph, style: textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }

  /// Goes back to the previous page, or to the home page when the legal
  /// notice was opened directly from its address.
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

/// Button which opens the legal notice.
class LegalNoticeButton extends StatelessWidget {
  const LegalNoticeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.gavel_outlined),
      label: const Text('Mentions légales'),
      onPressed: () => context.push(legalNoticePath),
    );
  }
}
