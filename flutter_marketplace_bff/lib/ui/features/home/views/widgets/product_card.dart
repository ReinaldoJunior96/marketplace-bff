import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../domain/models/product.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/formatters/currency_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../../product/views/product_detail_screen.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.backgroundColor = AppColors.peach,
    this.onTap,
    this.onAdd,
  });

  final Product product;

  /// Tom pastel atrás da foto.
  final Color backgroundColor;
  final VoidCallback? onTap;

  /// Adiciona direto ao carrinho, sem abrir o detalhe.
  final VoidCallback? onAdd;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final product = widget.product;
    final price = formatBrl(product.priceInCents);

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: AppMotion.fast,
      curve: Curves.easeOut,
      child: Card(
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: widget.backgroundColor,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Hero(
                    tag: productHeroTag(product.id),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: NetworkPhoto(
                        url: product.thumbnailUrl,
                        semanticLabel: product.name,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(height: 1.25),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              price,
                              maxLines: 1,
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.terracotta,
                              ),
                            ),
                          ),
                        ),
                        if (widget.onAdd != null)
                          SizedBox.square(
                            dimension: 34,
                            child: IconButton.filled(
                              tooltip: 'Adicionar ${product.name} ao carrinho',
                              padding: EdgeInsets.zero,
                              onPressed: widget.onAdd,
                              icon: const FaIcon(
                                FontAwesomeIcons.plus,
                                size: 13,
                              ),
                            ),
                          ),
                      ],
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
