import 'package:flutter/material.dart';

/// Paleta del sistema de diseño (micro-aprendizaje gamificado).
abstract final class AppColors {
  static const Color primary = Color(0xFF5A5BD6);
  static const Color primaryLight = Color(0xFF9B9CFF);
  static const Color accent = Color(0xFF19B394);
  static const Color success = Color(0xFF1F9D63);
  static const Color warning = Color(0xFFF5A524);
  static const Color danger = Color(0xFFE5484D);

  static const Color backgroundLight = Color(0xFFF6F6FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0F0F16);
  static const Color surfaceDark = Color(0xFF1A1A24);

  static const Color successSoftLight = Color(0xFFDDF6E9);
  static const Color successSoftDark = Color(0xFF123528);
  static const Color dangerSoftLight = Color(0xFFFFE4E4);
  static const Color dangerSoftDark = Color(0xFF3A1618);
  static const Color warningSoftLight = Color(0xFFFFF1D6);
  static const Color warningSoftDark = Color(0xFF3A2A10);

  /// Fondo suave de acierto según el brillo activo.
  static Color successSoft(Brightness brightness) =>
      brightness == Brightness.dark ? successSoftDark : successSoftLight;

  /// Fondo suave de error según el brillo activo.
  static Color dangerSoft(Brightness brightness) =>
      brightness == Brightness.dark ? dangerSoftDark : dangerSoftLight;

  /// Fondo suave de advertencia según el brillo activo.
  static Color warningSoft(Brightness brightness) =>
      brightness == Brightness.dark ? warningSoftDark : warningSoftLight;
}

/// Escala de espaciado y radios compartidos.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 26;
}

/// Tema Material 3 con soporte claro/oscuro.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: isDark ? AppColors.primaryLight : AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.danger,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}
