import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/illustration.dart';

/// Destaque editorial no topo da vitrine.
class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: ColoredBox(
        color: AppColors.peach,
        child: Stack(
          children: [
            const Positioned(
              right: -36,
              top: -36,
              child: _Circle(size: 140, color: AppColors.clay, delay: 0.3),
            ),
            const Positioned(
              right: 56,
              bottom: -48,
              child: _Circle(size: 110, color: AppColors.sage, delay: 0.45),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    Expanded(child: _buildCopy(textTheme)),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: (constraints.maxWidth * 0.38).clamp(110, 220),
                      child: const Illustration(AppIllustration.browsing),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopy(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.linen,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            'Novidades da semana',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.terracotta,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tecnologia que combina com o seu cantinho',
          style: textTheme.headlineSmall,
        ),
      ],
    );
  }
}

/// Círculo decorativo que surge com um "pop" elástico.
class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color, this.delay = 0});

  final double size;
  final Color color;

  /// Fração da animação antes do círculo começar a crescer.
  final double delay;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 1400),
      curve: Interval(delay, 1, curve: Curves.elasticOut),
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
