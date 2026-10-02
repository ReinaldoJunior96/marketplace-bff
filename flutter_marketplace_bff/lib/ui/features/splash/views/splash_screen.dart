import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/animations/circular_reveal_route.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Abertura animada. Enquanto anima, executa [preload]; ao terminar, revela
/// a tela de [nextBuilder] num círculo a partir do logo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.preload,
    required this.nextBuilder,
    this.maxPreloadWait = const Duration(milliseconds: 2500),
  });

  final Future<void> Function() preload;
  final WidgetBuilder nextBuilder;

  /// Se a pré-carga demorar mais que isso, segue mesmo assim — a próxima
  /// tela mostra o próprio estado de carregamento.
  final Duration maxPreloadWait;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _introDuration = Duration(milliseconds: 1900);
  static const _wordmark = 'TerraShop';
  static const _blobs = [
    _Blob(offset: Offset(-120, -170), size: 130, color: AppColors.peach),
    _Blob(offset: Offset(125, -110), size: 90, color: AppColors.sage),
    _Blob(offset: Offset(-105, 150), size: 105, color: AppColors.sand),
    _Blob(offset: Offset(115, 185), size: 75, color: AppColors.blush),
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _introDuration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_run());
  }

  Future<void> _run() async {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final preload = widget.preload().timeout(
      widget.maxPreloadWait,
      onTimeout: () {},
    );

    await Future.wait([_playIntro(reduceMotion: reduceMotion), preload]);
    if (!mounted) return;

    unawaited(
      Navigator.of(
        context,
      ).pushReplacement(CircularRevealRoute<void>(builder: widget.nextBuilder)),
    );
  }

  Future<void> _playIntro({required bool reduceMotion}) async {
    if (reduceMotion) {
      _controller.value = 1;
      return;
    }
    try {
      await _controller.forward().orCancel;
    } on TickerCanceled {
      // Tela descartada no meio da animação.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Progresso de um trecho [begin]–[end] da animação, com [curve].
  double _phase(double begin, double end, [Curve curve = Curves.easeOutCubic]) {
    return curve.transform(Interval(begin, end).transform(_controller.value));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Semantics(
        label: 'TerraShop, carregando',
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              for (final (index, blob) in _blobs.indexed)
                _buildBlob(
                  blob,
                  _phase(0.12 + index * 0.07, 0.6 + index * 0.07),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildWordmark(textTheme),
                    const SizedBox(height: AppSpacing.xs),
                    Opacity(
                      opacity: _phase(0.72, 1),
                      child: Text(
                        'Achados com afeto',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.mocha,
                        ),
                      ),
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

  Widget _buildBlob(_Blob blob, double t) {
    // Os círculos crescem e se afastam levemente do centro.
    return Center(
      child: Transform.translate(
        offset: blob.offset * (0.7 + 0.3 * t),
        child: Transform.scale(
          scale: Curves.easeOutBack.transform(t),
          child: Container(
            width: blob.size,
            height: blob.size,
            decoration: BoxDecoration(
              color: blob.color.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final scale = _phase(0, 0.42, Curves.elasticOut);
    final spin = 1 - _phase(0, 0.5, Curves.easeOutBack);
    final ring = _phase(0.25, 0.85);

    return SizedBox.square(
      dimension: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Onda que se expande a partir do logo.
          Opacity(
            opacity: ring == 0 ? 0 : (1 - ring) * 0.5,
            child: Transform.scale(
              scale: 1 + ring * 0.85,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.terracotta, width: 2),
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: -spin * math.pi * 0.7,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.terracotta,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.terracotta.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordmark(TextTheme textTheme) {
    final style = textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      color: AppColors.espresso,
    );

    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, letter) in _wordmark.split('').indexed)
            _buildLetter(
              letter,
              style,
              _phase(0.36 + index * 0.035, 0.66 + index * 0.035),
            ),
        ],
      ),
    );
  }

  Widget _buildLetter(String letter, TextStyle? style, double t) {
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - t)),
        child: Text(letter, style: style),
      ),
    );
  }
}

class _Blob {
  const _Blob({required this.offset, required this.size, required this.color});

  final Offset offset;
  final double size;
  final Color color;
}
