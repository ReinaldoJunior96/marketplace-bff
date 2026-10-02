import 'package:flutter/animation.dart';

/// Durações e curvas padronizadas do app.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 450);
  static const slow = Duration(milliseconds: 750);

  /// Intervalo entre itens de uma entrada escalonada.
  static const stagger = Duration(milliseconds: 60);

  /// Desacelera forte no fim: entrada de elementos.
  static const emphasized = Cubic(0.05, 0.7, 0.1, 1);

  /// Transições de tela.
  static const standard = Curves.easeInOutCubic;
}
