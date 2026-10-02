import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../domain/models/cart_line.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/animations/app_page_route.dart';
import '../../../core/animations/fade_slide_in.dart';
import '../../../core/app_scope.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/illustration.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/state_message.dart';
import '../../checkout/views/checkout_screen.dart';
import '../view_models/cart_view_model.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = AppScope.of(context).cart;

    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Seu carrinho'),
          backgroundColor: AppColors.cream,
          surfaceTintColor: Colors.transparent,
        ),
        body: AnimatedSwitcher(
          duration: AppMotion.medium,
          child: cart.isEmpty
              ? StateMessage(
                  key: const ValueKey('empty'),
                  illustration: AppIllustration.emptyCart,
                  title: 'Seu carrinho está vazio',
                  message: 'Que tal dar uma volta pela vitrine?',
                  actionLabel: 'Explorar produtos',
                  onAction: () => Navigator.of(context).maybePop(),
                )
              : _CartContent(key: const ValueKey('content'), cart: cart),
        ),
        bottomNavigationBar: cart.isEmpty
            ? null
            : _CheckoutBar(totalInCents: cart.totalInCents),
      ),
    );
  }
}

class _CartContent extends StatelessWidget {
  const _CartContent({super.key, required this.cart});

  final CartViewModel cart;

  @override
  Widget build(BuildContext context) {
    final lines = cart.lines;
    final gutter = math.max(
      AppSpacing.lg,
      (MediaQuery.sizeOf(context).width - 720) / 2,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.sm,
        gutter,
        AppSpacing.xl,
      ),
      children: [
        for (final (index, line) in lines.indexed)
          FadeSlideIn(
            key: ValueKey(line.product.id),
            delay: AppMotion.stagger * index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _CartLineTile(line: line, cart: cart),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        FadeSlideIn(
          delay: AppMotion.stagger * lines.length,
          child: _Summary(
            itemCount: cart.itemCount,
            totalInCents: cart.totalInCents,
          ),
        ),
      ],
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line, required this.cart});

  final CartLine line;
  final CartViewModel cart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final product = line.product;

    return Dismissible(
      key: ValueKey('dismiss-${product.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        cart.remove(product.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.blush,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: const FaIcon(
          FontAwesomeIcons.trashCan,
          color: AppColors.terracotta,
        ),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: SizedBox.square(
                  dimension: 76,
                  child: ColoredBox(
                    color: AppColors.sand,
                    child: NetworkPhoto(url: product.thumbnailUrl),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatBrl(line.totalInCents),
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.terracotta,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    QuantityStepper(
                      compact: true,
                      quantity: line.quantity,
                      onIncrement: () => cart.increment(product.id),
                      onDecrement: () => cart.decrement(product.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.itemCount, required this.totalInCents});

  final int itemCount;
  final int totalInCents;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium?.copyWith(color: AppColors.mocha);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.peach.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  itemCount == 1
                      ? 'Subtotal (1 item)'
                      : 'Subtotal ($itemCount itens)',
                  style: muted,
                ),
              ),
              Text(formatBrl(totalInCents), style: muted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: Text('Frete', style: muted)),
              Text(
                'Grátis',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.olive,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl, color: AppColors.stone),
          Row(
            children: [
              Expanded(child: Text('Total', style: textTheme.titleLarge)),
              Text(formatBrl(totalInCents), style: textTheme.titleLarge),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.totalInCents});

  final int totalInCents;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.linen,
        border: Border(top: BorderSide(color: AppColors.stone)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(AppPageRoute<void>(builder: (_) => const CheckoutScreen())),
            icon: const FaIcon(FontAwesomeIcons.lock, size: 16),
            label: Text('Ir para pagamento · ${formatBrl(totalInCents)}'),
          ),
        ),
      ),
    );
  }
}
