import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/animations/app_motion.dart';
import '../../../core/app_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/count_badge.dart';
import '../../home/view_models/home_view_model.dart';
import '../../home/views/home_screen.dart';
import '../../notifications/views/notifications_screen.dart';
import '../../orders/view_models/orders_view_model.dart';
import '../../orders/views/orders_screen.dart';

/// Navegação principal: Início, Pedidos e Notificações.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.homeViewModel});

  final HomeViewModel homeViewModel;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  OrdersViewModel? _ordersViewModel;
  AppScope? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    if (_scope == scope) return;
    _scope?.currentTab.removeListener(_onTabChanged);
    _scope?.notifications.removeListener(_onNotificationsChanged);
    _scope = scope
      ..currentTab.addListener(_onTabChanged)
      ..notifications.addListener(_onNotificationsChanged);
    _ordersViewModel ??= OrdersViewModel(repository: scope.orderRepository);
  }

  void _onTabChanged() {
    switch (_scope!.currentTab.value) {
      case AppTab.orders:
        _ordersViewModel!.load();
      case AppTab.notifications:
        _scope!.notifications.markAllRead();
      case AppTab.home:
        break;
    }
    setState(() {});
  }

  /// Com a aba de notificações aberta, o que chega já conta como lido.
  void _onNotificationsChanged() {
    if (_scope!.currentTab.value == AppTab.notifications) {
      _scope!.notifications.markAllRead();
    }
  }

  @override
  void dispose() {
    _scope?.currentTab.removeListener(_onTabChanged);
    _scope?.notifications.removeListener(_onNotificationsChanged);
    _ordersViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope!;
    final tab = scope.currentTab.value;

    return Scaffold(
      body: _FadeIndexedStack(
        index: tab.index,
        children: [
          HomeScreen(viewModel: widget.homeViewModel),
          OrdersScreen(viewModel: _ordersViewModel!),
          NotificationsScreen(viewModel: scope.notifications),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: scope.notifications,
        builder: (context, _) => NavigationBar(
          selectedIndex: tab.index,
          onDestinationSelected: (index) =>
              scope.currentTab.value = AppTab.values[index],
          backgroundColor: AppColors.linen,
          indicatorColor: AppColors.peach,
          destinations: [
            const NavigationDestination(
              icon: FaIcon(FontAwesomeIcons.house, size: 18),
              label: 'Início',
            ),
            const NavigationDestination(
              icon: FaIcon(FontAwesomeIcons.receipt, size: 18),
              label: 'Pedidos',
            ),
            NavigationDestination(
              icon: CountBadge(
                count: scope.notifications.unreadCount,
                child: const FaIcon(FontAwesomeIcons.bell, size: 18),
              ),
              selectedIcon: const FaIcon(FontAwesomeIcons.solidBell, size: 18),
              label: 'Avisos',
            ),
          ],
        ),
      ),
    );
  }
}

/// `IndexedStack` que preserva o estado das abas e anima a troca.
class _FadeIndexedStack extends StatefulWidget {
  const _FadeIndexedStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: 1,
  );

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.emphasized,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: IndexedStack(index: widget.index, children: widget.children),
      ),
    );
  }
}
