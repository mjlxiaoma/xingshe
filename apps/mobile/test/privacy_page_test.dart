import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:xingshe/features/auth/email_login_page.dart';
import 'package:xingshe/features/settings/settings_pages.dart';

void main() {
  testWidgets('signed-out privacy flow exposes external deletion guidance', (
    tester,
  ) async {
    const contact = 'privacy-test@example.invalid';
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const EmailLoginPage()),
        GoRoute(
          path: '/privacy',
          builder: (_, _) => const PrivacyPage(contactEmail: contact),
        ),
        GoRoute(
          path: '/privacy/account-deletion',
          builder: (_, _) =>
              const ExternalAccountDeletionPage(contactEmail: contact),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    final publicPrivacy = find.byKey(const Key('open-public-privacy'));
    await tester.ensureVisible(publicPrivacy);
    await tester.tap(publicPrivacy);
    await tester.pumpAndSettle();
    expect(find.text(contact), findsOneWidget);

    await tester.tap(find.byKey(const Key('copy-privacy-contact')));
    await tester.pump();
    await tester.pump();
    expect(copied, contact);
    expect(find.text('隐私联系邮箱已复制'), findsOneWidget);

    final deletionGuide = find.byKey(const Key('open-external-deletion-guide'));
    await tester.ensureVisible(deletionGuide);
    await tester.pumpAndSettle();
    await tester.tap(deletionGuide);
    await tester.pumpAndSettle();
    expect(find.text('账号删除申请'), findsOneWidget);
    expect(find.text(contact), findsOneWidget);
    expect(find.textContaining('不要发送密码、验证码、Token'), findsOneWidget);
    expect(find.textContaining('系统相册原图不在服务端'), findsOneWidget);
  });

  testWidgets('missing privacy contact disables copying', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PrivacyPage(contactEmail: '')),
    );
    await tester.pumpAndSettle();

    expect(find.text('当前构建未配置隐私联系邮箱'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('copy-privacy-contact')))
          .onPressed,
      isNull,
    );
  });
}
