import 'package:flutter/material.dart';
import 'package:flutter_marketplace_bff/ui/core/app_scope.dart';
import 'package:flutter_marketplace_bff/ui/core/theme/app_theme.dart';
import 'package:flutter_marketplace_bff/ui/features/cart/view_models/cart_view_model.dart';
import 'package:flutter_marketplace_bff/ui/features/notifications/view_models/notifications_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_flow_repositories.dart';

/// Dependências fake do app para testes de tela.
class TestDependencies {
  final products = FakeProductRepository((_) async => sampleDetail);
  final orders = FakeOrderRepository();
  final notificationRepository = FakeNotificationRepository();
  final cart = CartViewModel();
  final navigatorKey = GlobalKey<NavigatorState>();
  final currentTab = ValueNotifier(AppTab.home);
  late final notifications = NotificationsViewModel(
    repository: notificationRepository,
  );

  void dispose() {
    notifications.dispose();
    cart.dispose();
    currentTab.dispose();
  }

  /// [home] dentro de `MaterialApp` com tema e `AppScope`.
  Widget app(Widget home) => AppScope(
    productRepository: products,
    orderRepository: orders,
    cart: cart,
    notifications: notifications,
    navigatorKey: navigatorKey,
    currentTab: currentTab,
    child: MaterialApp(
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      home: home,
    ),
  );
}

TestDependencies createTestDependencies() {
  final dependencies = TestDependencies();
  addTearDown(dependencies.dispose);
  return dependencies;
}
