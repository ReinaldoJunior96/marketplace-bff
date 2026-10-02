import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../domain/models/product.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/animations/fade_slide_in.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/illustration.dart';
import '../../../core/widgets/state_message.dart';
import '../view_models/home_view_model.dart';
import 'widgets/home_banner.dart';
import 'widgets/home_search_field.dart';
import 'widgets/product_card.dart';
import 'widgets/product_card_skeleton.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _skeletonCount = 6;

  /// Depois disso os cards entram juntos, para a cascata não ficar lenta.
  static const _maxStaggeredCards = 8;

  HomeViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    // A splash já pode ter carregado (ou estar carregando) a vitrine.
    if (_viewModel.state is HomeLoading) _viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Em telas largas o conteúdo fica centralizado com largura máxima.
            final gutter = math.max(
              AppSpacing.lg,
              (constraints.maxWidth - AppSpacing.maxContentWidth) / 2,
            );

            return ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => RefreshIndicator(
                onRefresh: _viewModel.load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        AppSpacing.lg,
                        gutter,
                        AppSpacing.xl,
                      ),
                      sliver: SliverList.list(
                        children: [
                          const FadeSlideIn(child: _Header()),
                          const SizedBox(height: AppSpacing.lg),
                          FadeSlideIn(
                            delay: AppMotion.stagger * 2,
                            child: HomeSearchField(
                              onChanged: _viewModel.search,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FadeSlideIn(
                            delay: AppMotion.stagger * 4,
                            child: const HomeBanner(),
                          ),
                        ],
                      ),
                    ),
                    ..._buildContent(gutter),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildContent(double gutter) {
    return switch (_viewModel.state) {
      HomeLoading() => [
        _ProductGrid(
          gutter: gutter,
          itemCount: _skeletonCount,
          itemBuilder: (index) => FadeSlideIn(
            delay: AppMotion.stagger * index,
            offset: Offset.zero,
            child: const ProductCardSkeleton(),
          ),
        ),
      ],
      HomeFailure(:final message) => [
        _StateSliver(
          child: StateMessage(
            illustration: AppIllustration.connectionLost,
            title: 'Não conseguimos carregar a vitrine',
            message: message,
            actionLabel: 'Tentar de novo',
            onAction: _viewModel.load,
          ),
        ),
      ],
      HomeLoaded() => _buildProducts(_viewModel.visibleProducts, gutter),
    };
  }

  List<Widget> _buildProducts(List<Product> products, double gutter) {
    if (products.isEmpty) {
      final query = _viewModel.query.trim();
      return [
        _StateSliver(
          child: query.isEmpty
              ? const StateMessage(
                  illustration: AppIllustration.emptyOrders,
                  title: 'Vitrine vazia por enquanto',
                  message: 'Logo chegam novidades por aqui.',
                )
              : StateMessage(
                  illustration: AppIllustration.notFound,
                  title: 'Nada encontrado',
                  message: 'Nenhum produto corresponde a "$query".',
                ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.md),
        sliver: SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: AppMotion.stagger * 3,
            child: _SectionHeader(productCount: products.length),
          ),
        ),
      ),
      _ProductGrid(
        gutter: gutter,
        itemCount: products.length,
        // Cada card entra em cascata; a chave pelo id faz os resultados de
        // uma nova busca entrarem animados também.
        itemBuilder: (index) => FadeSlideIn(
          key: ValueKey(products[index].id),
          delay: AppMotion.stagger * math.min(index, _maxStaggeredCards),
          offset: const Offset(0, 40),
          child: ProductCard(
            product: products[index],
            backgroundColor:
                AppColors.pastels[index % AppColors.pastels.length],
          ),
        ),
      ),
    ];
  }
}

/// Estados de erro/vazio rolam junto com o cabeçalho, sem depender do
/// espaço que sobra na tela.
class _StateSliver extends StatelessWidget {
  const _StateSliver({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      sliver: SliverToBoxAdapter(child: FadeSlideIn(child: child)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.terracotta,
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.bagShopping,
                size: 20,
                color: AppColors.cream,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TerraShop', style: textTheme.titleLarge),
                  Text(
                    'Achados com afeto',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.mocha,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('O que vamos encontrar hoje?', style: textTheme.headlineSmall),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.productCount});

  final int productCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = productCount == 1 ? '1 produto' : '$productCount produtos';

    return Row(
      children: [
        Expanded(child: Text('Para você', style: textTheme.titleLarge)),
        AnimatedSwitcher(
          duration: AppMotion.fast,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            label,
            key: ValueKey(label),
            style: textTheme.bodyMedium?.copyWith(color: AppColors.mocha),
          ),
        ),
      ],
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.gutter,
    required this.itemCount,
    required this.itemBuilder,
  });

  final double gutter;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    // A área de texto do card cresce com a fonte do sistema.
    final textArea = MediaQuery.textScalerOf(context).scale(92);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppSpacing.xxl),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          mainAxisExtent: 160 + textArea,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => itemBuilder(index),
      ),
    );
  }
}
