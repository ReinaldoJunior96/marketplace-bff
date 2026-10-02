import 'package:flutter/material.dart';
import 'package:flutter_marketplace_bff/ui/core/theme/app_theme.dart';
import 'package:flutter_marketplace_bff/ui/features/notifications/view_models/notifications_view_model.dart';
import 'package:flutter_marketplace_bff/ui/features/notifications/views/in_app_notification_host.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_flow_repositories.dart';

void main() {
  testWidgets('aviso aparece quando chega notificação nova', (tester) async {
    final repository = FakeNotificationRepository();
    final notifications = NotificationsViewModel(repository: repository);
    addTearDown(notifications.dispose);
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => InAppNotificationHost(
          notifications: notifications,
          onOpen: () => opened = true,
          child: child!,
        ),
        home: const Scaffold(),
      ),
    );

    await notifications.poll(); // histórico inicial vazio
    repository.onGetNotifications = () async => [notification('novo')];
    await notifications.poll();
    await tester.pumpAndSettle();

    expect(find.text('Pedido confirmado'), findsOneWidget);

    await tester.tap(find.text('Pedido confirmado'));
    await tester.pumpAndSettle();
    expect(opened, isTrue);
  });

  testWidgets('histórico existente não gera aviso', (tester) async {
    final repository = FakeNotificationRepository()
      ..onGetNotifications = () async => [notification('antigo')];
    final notifications = NotificationsViewModel(repository: repository);
    addTearDown(notifications.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => InAppNotificationHost(
          notifications: notifications,
          onOpen: () {},
          child: child!,
        ),
        home: const Scaffold(),
      ),
    );
    await notifications.poll();
    await tester.pumpAndSettle();

    expect(find.text('Pedido confirmado'), findsNothing);
  });
}
