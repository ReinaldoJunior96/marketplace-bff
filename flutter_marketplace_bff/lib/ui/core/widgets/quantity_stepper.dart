import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../animations/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Seletor `– 2 +` com a quantidade trocando animada.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 44.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.linen,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.stone),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: FontAwesomeIcons.minus,
            size: size,
            tooltip: 'Diminuir quantidade',
            onPressed: onDecrement,
          ),
          SizedBox(
            width: compact ? 28 : 36,
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          _StepButton(
            icon: FontAwesomeIcons.plus,
            size: size,
            tooltip: 'Aumentar quantidade',
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.size,
    required this.tooltip,
    required this.onPressed,
  });

  final FaIconData icon;
  final double size;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        color: AppColors.terracotta,
        icon: FaIcon(icon, size: size * 0.32),
      ),
    );
  }
}
