import 'package:flutter/painting.dart';

/// Paleta do app: base terrosa com acentos pastel.
///
/// Os tons de texto e a primária foram escolhidos para manter contraste
/// mínimo de 4.5:1 sobre [cream] e [linen].
abstract final class AppColors {
  // Terrosos
  static const espresso = Color(0xFF3B2A22); // texto principal
  static const mocha = Color(0xFF6E5A4E); // texto secundário
  static const terracotta = Color(0xFFA0533A); // primária
  static const clay = Color(0xFFD9967A);
  static const olive = Color(0xFF5E6B4E); // secundária
  static const stone = Color(0xFFE4D8CB); // bordas e divisores

  // Fundos
  static const cream = Color(0xFFF8F3EC);
  static const linen = Color(0xFFFFFCF8);

  // Pastéis
  static const peach = Color(0xFFF6DCCB);
  static const sage = Color(0xFFDDE5D3);
  static const sand = Color(0xFFEFE2C8);
  static const blush = Color(0xFFF1D5D3);

  /// Fundos alternados dos cards de produto.
  static const pastels = [peach, sage, sand, blush];
}
