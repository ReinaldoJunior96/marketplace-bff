import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// Transição padrão entre telas: a nova sobe levemente enquanto aparece, e a
/// anterior recua um pouco.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        transitionDuration: AppMotion.medium,
        reverseTransitionDuration: AppMotion.fast + AppMotion.stagger,
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final enter = CurvedAnimation(
            parent: animation,
            curve: AppMotion.emphasized,
            reverseCurve: Curves.easeInCubic,
          );
          final exit = CurvedAnimation(
            parent: secondaryAnimation,
            curve: AppMotion.standard,
          );
          return FadeTransition(
            opacity: enter,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(enter),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1, end: 0.96).animate(exit),
                child: child,
              ),
            ),
          );
        },
      );
}
