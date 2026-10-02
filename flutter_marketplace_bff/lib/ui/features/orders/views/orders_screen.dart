import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../domain/models/order.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/animations/fade_slide_in.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/illustration.dart';
import '../../../core/widgets/state_message.dart';
import '../view_models/orders_view_model.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, required this.viewModel});

  final OrdersViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final gutter = math.max(
      AppSpacing.lg,
      (MediaQuery.sizeOf(context).width - 720) / 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus pedidos'),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => RefreshIndicator(
          onRefresh: viewModel.load,
          child: switch (viewModel.state) {
            OrdersLoading() => const Center(child: CircularProgressIndicator()),
            OrdersFailure(:final message) => _Scrollable(
              child: StateMessage(
                illustration: AppIllustration.connectionLost,
                title: 'Não conseguimos carregar seus pedidos',
                message: message,
                actionLabel: 'Tentar de novo',
                onAction: viewModel.load,
              ),
            ),
            OrdersLoaded(:final orders) when orders.isEmpty =>
              const _Scrollable(
                child: StateMessage(
                  illustration: AppIllustration.emptyOrders,
                  title: 'Nenhum pedido por aqui',
                  message:
                      'Seus pedidos aparecem aqui assim que forem criados.',
                ),
              ),
            OrdersLoaded(:final orders) => ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.sm,
                gutter,
                AppSpacing.xl,
              ),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => FadeSlideIn(
                key: ValueKey(orders[index].id),
                delay: AppMotion.stagger * math.min(index, 8),
                child: _OrderTile(order: orders[index], index: index),
              ),
            ),
          },
        ),
      ),
    );
  }
}

/// Permite o pull-to-refresh também nos estados de erro e vazio.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [FadeSlideIn(child: child)],
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.index});

  final Order order;
  final int index;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final items = order.itemsCount == 1
        ? '1 item'
        : '${order.itemsCount} itens';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.pastels[index % AppColors.pastels.length],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const FaIcon(
                FontAwesomeIcons.receipt,
                size: 18,
                color: AppColors.espresso,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${order.shortId}',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$items · ${formatDateTime(order.createdAt)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.mocha,
                    ),
                  ),
                ],
              ),
            ),
            _StatusChip(status: order.status),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      OrderStatus.created => ('Confirmado', AppColors.sage, AppColors.olive),
      OrderStatus.unknown => ('Em análise', AppColors.sand, AppColors.mocha),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}
