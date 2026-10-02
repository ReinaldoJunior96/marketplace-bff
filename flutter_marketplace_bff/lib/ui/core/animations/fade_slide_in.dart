import 'package:flutter/widgets.dart';

import 'app_motion.dart';

/// Faz o filho surgir com fade e deslize, após [delay].
///
/// O atraso é parte da própria animação (um `Interval`), sem timers —
/// assim a animação para junto com o widget. Dentro de uma rota que ainda
/// está em transição, espera a transição terminar.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.medium,
    this.offset = const Offset(0, 24),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Deslocamento inicial em pixels.
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    final start = total == Duration.zero
        ? 0.0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: AppMotion.emphasized),
    );
  }

  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
      return;
    }

    // Se a tela ainda está entrando (ex.: revelação circular), a cascata só
    // começa quando a transição termina — senão ela acontece escondida.
    // A animação da rota só fica ligada após o primeiro frame.
    final route = ModalRoute.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final routeAnimation = route?.animation;
      if (routeAnimation == null || routeAnimation.isCompleted) {
        _controller.forward();
      } else {
        _routeAnimation = routeAnimation..addStatusListener(_onRouteStatus);
      }
    });
  }

  void _onRouteStatus(AnimationStatus status) {
    if (!status.isCompleted) return;
    _stopWatchingRoute();
    _controller.forward();
  }

  void _stopWatchingRoute() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _routeAnimation = null;
  }

  @override
  void dispose() {
    _stopWatchingRoute();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _progress,
      child: AnimatedBuilder(
        animation: _progress,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: widget.offset * (1 - _progress.value),
          child: child,
        ),
      ),
    );
  }
}
