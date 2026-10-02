import 'package:flutter/material.dart';

import '../animations/app_motion.dart';
import '../theme/app_colors.dart';

/// Ícone com contador que "pula" quando o número muda.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -6,
          child: AnimatedScale(
            scale: count > 0 ? 1 : 0,
            duration: AppMotion.fast,
            curve: Curves.easeOutBack,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(count),
              tween: Tween(begin: 1.5, end: 1),
              duration: AppMotion.medium,
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.linen, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
