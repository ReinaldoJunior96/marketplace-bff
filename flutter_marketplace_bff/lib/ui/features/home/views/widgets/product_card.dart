import 'package:flutter/material.dart';

import '../../../../../domain/models/product.dart';
import '../../../../core/formatters/currency_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.backgroundColor = AppColors.peach,
  });

  final Product product;

  /// Tom pastel atrás da imagem.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final price = formatBrl(product.priceInCents);

    return MergeSemantics(
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: backgroundColor,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Image.network(
                    product.thumbnailUrl,
                    fit: BoxFit.cover,
                    semanticLabel: product.name,
                    errorBuilder: (_, _, _) => const _ImageFallback(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                  Text(
                    price,
                    maxLines: 1,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.terracotta,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image_outlined, size: 40, color: AppColors.mocha),
    );
  }
}
