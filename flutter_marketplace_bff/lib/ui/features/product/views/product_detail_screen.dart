import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../domain/models/product.dart';
import '../../../../domain/models/product_detail.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/animations/fade_slide_in.dart';
import '../../../core/app_scope.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/shimmer.dart';
import '../../cart/views/cart_button.dart';
import '../view_models/product_detail_view_model.dart';

/// Tag do Hero que leva a foto do card até o detalhe.
String productHeroTag(String productId) => 'product-photo-$productId';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  /// Dados da vitrine, exibidos enquanto o detalhe carrega.
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductDetailViewModel? _viewModel;
  bool _justAdded = false;
  Timer? _addedTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel != null) return;
    final scope = AppScope.of(context);
    _viewModel = ProductDetailViewModel(
      preview: widget.product,
      repository: scope.productRepository,
      cart: scope.cart,
    )..load();
  }

  @override
  void dispose() {
    _addedTimer?.cancel();
    _viewModel?.dispose();
    super.dispose();
  }

  void _addToCart() {
    if (!_viewModel!.addToCart()) return;
    HapticFeedback.mediumImpact();
    setState(() => _justAdded = true);
    _addedTimer?.cancel();
    _addedTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _justAdded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel!;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final detail = switch (viewModel.state) {
          ProductDetailLoaded(:final product) => product,
          _ => null,
        };

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _PhotoAppBar(product: widget.product),
              SliverToBoxAdapter(
                child: _DetailBody(
                  preview: widget.product,
                  detail: detail,
                  state: viewModel.state,
                  onRetry: viewModel.load,
                ),
              ),
            ],
          ),
          bottomNavigationBar: _AddToCartBar(
            enabled: detail?.inStock ?? false,
            quantity: viewModel.quantity,
            priceInCents: widget.product.priceInCents * viewModel.quantity,
            justAdded: _justAdded,
            onIncrement: viewModel.quantity < viewModel.maxSelectable
                ? viewModel.incrementQuantity
                : null,
            onDecrement: viewModel.quantity > 1
                ? viewModel.decrementQuantity
                : null,
            onAdd: _addToCart,
          ),
        );
      },
    );
  }
}

class _PhotoAppBar extends StatelessWidget {
  const _PhotoAppBar({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.45;

    return SliverAppBar(
      expandedHeight: height.clamp(280, 460),
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: IconButton(
          tooltip: 'Voltar',
          style: IconButton.styleFrom(backgroundColor: AppColors.linen),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const FaIcon(
            FontAwesomeIcons.arrowLeft,
            size: 16,
            color: AppColors.espresso,
          ),
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.md),
          child: CartButton(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Hero(
          tag: productHeroTag(product.id),
          child: ColoredBox(
            color: AppColors.sand,
            child: NetworkPhoto(
              url: product.thumbnailUrl,
              semanticLabel: product.name,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.preview,
    required this.detail,
    required this.state,
    required this.onRetry,
  });

  final Product preview;
  final ProductDetail? detail;
  final ProductDetailState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detail = this.detail;

    return Container(
      // Sobe sobre a foto com cantos arredondados.
      transform: Matrix4.translationValues(0, -AppSpacing.xl, 0),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg + 8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: detail == null
                ? const SizedBox(height: 28)
                : _CategoryChip(label: detail.category),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(preview.name, style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatBrl(preview.priceInCents),
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.terracotta,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (detail != null) _StockLabel(stock: detail.stock),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Sobre o produto', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          switch (state) {
            ProductDetailLoaded(:final product) => FadeSlideIn(
              offset: const Offset(0, 12),
              child: Text(
                product.description,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.mocha,
                  height: 1.5,
                ),
              ),
            ),
            ProductDetailFailure(:final message) => _InlineError(
              message: message,
              onRetry: onRetry,
            ),
            ProductDetailLoading() => const _DescriptionSkeleton(),
          },
          const SizedBox(height: AppSpacing.xl),
          const _Perks(),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppColors.olive, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StockLabel extends StatelessWidget {
  const _StockLabel({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;
    final color = inStock ? AppColors.olive : AppColors.terracotta;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(
          inStock ? FontAwesomeIcons.boxOpen : FontAwesomeIcons.ban,
          size: 14,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(
          inStock ? '$stock em estoque' : 'Esgotado',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _Perks extends StatelessWidget {
  const _Perks();

  @override
  Widget build(BuildContext context) {
    const perks = [
      (FontAwesomeIcons.truckFast, 'Entrega', 'em até 3 dias'),
      (FontAwesomeIcons.arrowsRotate, 'Troca', 'grátis em 30 dias'),
      (FontAwesomeIcons.shieldHalved, 'Compra', '100% segura'),
    ];
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        for (final (index, (icon, title, subtitle)) in perks.indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.pastels[index],
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FaIcon(icon, size: 16, color: AppColors.espresso),
                  const SizedBox(height: AppSpacing.sm),
                  Text(title, style: textTheme.labelLarge),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.mocha,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DescriptionSkeleton extends StatelessWidget {
  const _DescriptionSkeleton();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final widthFactor in const [1.0, 0.92, 0.6])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: Container(height: 14, color: AppColors.stone),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.terracotta),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Tentar de novo')),
      ],
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.enabled,
    required this.quantity,
    required this.priceInCents,
    required this.justAdded,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAdd,
  });

  final bool enabled;
  final int quantity;
  final int priceInCents;
  final bool justAdded;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback onAdd;

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
          child: Row(
            children: [
              QuantityStepper(
                quantity: quantity,
                onIncrement: enabled ? onIncrement : null,
                onDecrement: enabled ? onDecrement : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: justAdded ? AppColors.olive : null,
                  ),
                  // Durante o "Adicionado!" o botão segue habilitado (para
                  // manter a cor), mas ignora toques.
                  onPressed: enabled ? (justAdded ? () {} : onAdd) : null,
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: justAdded
                        ? const Row(
                            key: ValueKey('added'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.check, size: 16),
                              SizedBox(width: AppSpacing.sm),
                              Text('Adicionado!'),
                            ],
                          )
                        : FittedBox(
                            key: const ValueKey('add'),
                            child: Text(
                              'Adicionar · ${formatBrl(priceInCents)}',
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
