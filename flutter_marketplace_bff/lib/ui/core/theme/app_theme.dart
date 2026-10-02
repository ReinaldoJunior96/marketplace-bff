import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.terracotta,
          surface: AppColors.linen,
        ).copyWith(
          primary: AppColors.terracotta,
          onPrimary: Colors.white,
          primaryContainer: AppColors.peach,
          onPrimaryContainer: AppColors.espresso,
          secondary: AppColors.olive,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.sage,
          onSecondaryContainer: AppColors.espresso,
          tertiaryContainer: AppColors.sand,
          onTertiaryContainer: AppColors.espresso,
          onSurface: AppColors.espresso,
          onSurfaceVariant: AppColors.mocha,
          outline: AppColors.mocha,
          outlineVariant: AppColors.stone,
        );

    final base = ThemeData(colorScheme: colorScheme);
    final textTheme = base.textTheme
        .apply(bodyColor: AppColors.espresso, displayColor: AppColors.espresso)
        .copyWith(
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.espresso,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.espresso,
          ),
        );

    final roundedMd = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.linen,
        hintStyle: const TextStyle(color: AppColors.mocha),
        prefixIconColor: AppColors.mocha,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.stone),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.stone),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: roundedMd,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.linen,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: AppColors.stone),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.terracotta,
      ),
    );
  }
}
