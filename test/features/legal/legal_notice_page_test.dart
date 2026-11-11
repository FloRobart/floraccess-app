import 'package:floraccess_app/features/legal/legal_notice_content.dart';
import 'package:floraccess_app/features/legal/presentation/pages/legal_notice_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Application with a page holding the button of the legal notice, like the
/// profile page, and the legal notice itself.
Widget buildApplicationWithLegalNoticeButton() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: LegalNoticeButton())),
      ),
      GoRoute(
        path: legalNoticePath,
        builder: (context, state) => const LegalNoticePage(),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('shows every section of the legal notice', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LegalNoticePage()));

    for (final section in LegalNoticeContent.sections) {
      /* The page scrolls: each selectable paragraph also has its own scrollable */
      await tester.scrollUntilVisible(
        find.text(section.title),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(section.title), findsOneWidget);
    }
  });

  test('names the publisher, the host, the contact and the retention', () {
    final allParagraphs = LegalNoticeContent.sections
        .expand((section) => section.paragraphs)
        .join('\n');

    expect(allParagraphs, contains('FloRobart, particulier non professionnel'));
    expect(allParagraphs, contains('OVH SAS'));
    expect(allParagraphs, contains('2 rue Kellermann, 59100 Roubaix'));
    expect(allParagraphs, contains(LegalNoticeContent.contactEmail));
    expect(allParagraphs, contains('trois mois après sa création'));
  });

  testWidgets('opens the legal notice from its button, then goes back', (
    tester,
  ) async {
    await tester.pumpWidget(buildApplicationWithLegalNoticeButton());

    await tester.tap(find.text('Mentions légales'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalNoticePage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(LegalNoticePage), findsNothing);
    expect(find.byType(LegalNoticeButton), findsOneWidget);
  });
}
