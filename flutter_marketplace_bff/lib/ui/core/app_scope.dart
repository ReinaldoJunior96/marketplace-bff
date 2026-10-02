import 'package:flutter/widgets.dart';

import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../features/cart/view_models/cart_view_model.dart';
import '../features/notifications/view_models/notifications_view_model.dart';

/// Abas da navegação principal.
enum AppTab { home, orders, notifications }

/// Dependências compartilhadas pelas telas (injeção manual, sem pacote).
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.productRepository,
    required this.orderRepository,
    required this.cart,
    required this.notifications,
    required this.navigatorKey,
    required this.currentTab,
    required super.child,
  });

  final ProductRepository productRepository;
  final OrderRepository orderRepository;
  final CartViewModel cart;
  final NotificationsViewModel notifications;
  final GlobalKey<NavigatorState> navigatorKey;
  final ValueNotifier<AppTab> currentTab;

  /// Volta para a tela principal e seleciona [tab].
  void goToTab(AppTab tab) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    currentTab.value = tab;
  }

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado na árvore.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      productRepository != oldWidget.productRepository ||
      orderRepository != oldWidget.orderRepository ||
      cart != oldWidget.cart ||
      notifications != oldWidget.notifications ||
      navigatorKey != oldWidget.navigatorKey ||
      currentTab != oldWidget.currentTab;
}
