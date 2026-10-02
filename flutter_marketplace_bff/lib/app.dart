import 'package:flutter/material.dart';

import 'data/repositories/home_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/product_repository.dart';
import 'ui/core/app_scope.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/cart/view_models/cart_view_model.dart';
import 'ui/features/home/view_models/home_view_model.dart';
import 'ui/features/notifications/view_models/notifications_view_model.dart';
import 'ui/features/notifications/views/in_app_notification_host.dart';
import 'ui/features/shell/views/app_shell.dart';
import 'ui/features/splash/views/splash_screen.dart';

class MarketplaceApp extends StatefulWidget {
  const MarketplaceApp({
    super.key,
    required this.homeRepository,
    required this.productRepository,
    required this.orderRepository,
    required this.notificationRepository,
  });

  final HomeRepository homeRepository;
  final ProductRepository productRepository;
  final OrderRepository orderRepository;
  final NotificationRepository notificationRepository;

  @override
  State<MarketplaceApp> createState() => _MarketplaceAppState();
}

class _MarketplaceAppState extends State<MarketplaceApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _currentTab = ValueNotifier(AppTab.home);
  final _cart = CartViewModel();
  late final _homeViewModel = HomeViewModel(
    homeRepository: widget.homeRepository,
  );
  late final _notifications = NotificationsViewModel(
    repository: widget.notificationRepository,
  )..start();

  @override
  void dispose() {
    _homeViewModel.dispose();
    _notifications.dispose();
    _cart.dispose();
    _currentTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      productRepository: widget.productRepository,
      orderRepository: widget.orderRepository,
      cart: _cart,
      notifications: _notifications,
      navigatorKey: _navigatorKey,
      currentTab: _currentTab,
      child: MaterialApp(
        title: 'TerraShop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorKey: _navigatorKey,
        builder: (context, child) => InAppNotificationHost(
          notifications: _notifications,
          onOpen: () {
            _navigatorKey.currentState?.popUntil((route) => route.isFirst);
            _currentTab.value = AppTab.notifications;
          },
          child: child!,
        ),
        home: SplashScreen(
          preload: _homeViewModel.load,
          nextBuilder: (_) => AppShell(homeViewModel: _homeViewModel),
        ),
      ),
    );
  }
}
