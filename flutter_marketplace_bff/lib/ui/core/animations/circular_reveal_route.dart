import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// Rota que revela a nova tela num círculo que cresce a partir de [center].
class CircularRevealRoute<T> extends PageRouteBuilder<T> {
  CircularRevealRoute({
    required WidgetBuilder builder,
    Alignment center = Alignment.center,
    super.settings,
  }) : super(
         transitionDuration: AppMotion.slow,
         reverseTransitionDuration: AppMotion.medium,
         pageBuilder: (context, _, _) => builder(context),
         transitionsBuilder: (context, animation, _, child) {
           final progress = CurvedAnimation(
             parent: animation,
             curve: AppMotion.standard,
           );
           return AnimatedBuilder(
             animation: progress,
             child: child,
             builder: (context, child) {
               if (progress.value >= 1) return child!;
               return ClipPath(
                 clipper: CircularRevealClipper(
                   progress: progress.value,
                   center: center,
                 ),
                 child: child,
               );
             },
           );
         },
       );
}

/// Recorta um círculo que cobre a área toda quando [progress] chega a 1.
class CircularRevealClipper extends CustomClipper<Path> {
  const CircularRevealClipper({required this.progress, required this.center});

  final double progress;
  final Alignment center;

  @override
  Path getClip(Size size) {
    final origin = center.alongSize(size);
    // Distância até o canto mais longe garante cobertura total.
    final maxRadius = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((corner) => (corner - origin).distance).reduce(math.max);

    return Path()
      ..addOval(Rect.fromCircle(center: origin, radius: maxRadius * progress));
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) =>
      oldClipper.progress != progress || oldClipper.center != center;
}
