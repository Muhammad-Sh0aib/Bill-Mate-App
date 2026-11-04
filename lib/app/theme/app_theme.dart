import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_dimensions.dart';

/// BillMate Material 3 theme configuration.
///
/// Implements cohesive, accessible light and dark themes with complete
/// support for colors, typography, buttons, inputs, dialogs, cards,
/// and modern Material 3 navigation bars.
abstract class AppTheme {
  AppTheme._();

  // ── Input decoration theme ─────────────────────────────────────
  static InputDecorationTheme _inputDecorationTheme(bool isDark) {
    final borderColor = isDark ? const Color(0xFF2C3E50) : AppColors.border;
    final fillColor = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surfaceLight;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hintStyle: AppTextStyles.inputHint.copyWith(
        color: isDark ? const Color(0xFF7E93A8) : AppColors.textDisabled,
      ),
      labelStyle: AppTextStyles.formLabel.copyWith(
        color: isDark ? const Color(0xFFB0C4DE) : AppColors.textSecondary,
      ),
      helperStyle: AppTextStyles.caption.copyWith(
        color: isDark ? const Color(0xFF7E93A8) : AppColors.textSecondary,
      ),
      errorStyle: AppTextStyles.caption.copyWith(
        color: isDark ? const Color(0xFFEF9A9A) : AppColors.error,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF90CAF9) : AppColors.focus,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFFEF9A9A) : AppColors.error,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFFEF9A9A) : AppColors.error,
          width: 1.8,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E2D3D) : const Color(0xFFEAEDF1),
          width: 1.0,
        ),
      ),
    );
  }

  // ── Card theme ─────────────────────────────────────────────────
  static CardThemeData _cardTheme(bool isDark) => CardThemeData(
    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    elevation: AppElevation.low,
    shadowColor: AppColors.primary.withAlpha(isDark ? 50 : 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(
        color: isDark ? const Color(0xFF2C3E50) : AppColors.border,
        width: 1.0,
      ),
    ),
    margin: EdgeInsets.zero,
  );

  // ── Chip theme ─────────────────────────────────────────────────
  static ChipThemeData _chipTheme(bool isDark) => ChipThemeData(
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
    labelStyle: AppTextStyles.bodySmall.copyWith(
      color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
    ),
    side: BorderSide(
      color: isDark ? const Color(0xFF2C3E50) : AppColors.border,
      width: 1,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
  );

  // ── Button themes ──────────────────────────────────────────────
  static ElevatedButtonThemeData _elevatedButtonTheme(bool isDark) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textOnAccent,
          disabledBackgroundColor: isDark
              ? const Color(0xFF243447)
              : AppColors.disabledSurface,
          disabledForegroundColor: isDark
              ? const Color(0xFF5D6D7E)
              : AppColors.textDisabled,
          textStyle: AppTextStyles.buttonLarge,
          minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 4,
          ),
          elevation: AppElevation.low,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(bool isDark) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? const Color(0xFF90CAF9) : AppColors.primary,
          disabledForegroundColor: isDark
              ? const Color(0xFF5D6D7E)
              : AppColors.textDisabled,
          textStyle: AppTextStyles.buttonMedium,
          minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 4,
          ),
          side: BorderSide(
            color: isDark ? const Color(0xFF90CAF9) : AppColors.primary,
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );

  static TextButtonThemeData _textButtonTheme(bool isDark) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark
              ? const Color(0xFF90CAF9)
              : AppColors.secondary,
          disabledForegroundColor: isDark
              ? const Color(0xFF5D6D7E)
              : AppColors.textDisabled,
          textStyle: AppTextStyles.buttonMedium,
          minimumSize: const Size(48, AppSpacing.touchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );

  // ── Navigation Bar (Material 3) theme ──────────────────────────
  static NavigationBarThemeData _navigationBarTheme(bool isDark) =>
      NavigationBarThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        indicatorColor: isDark
            ? AppColors.secondary.withAlpha(90)
            : AppColors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? const Color(0xFF90CAF9) : AppColors.primary,
              size: 24,
            );
          }
          return IconThemeData(
            color: isDark ? const Color(0xFF9BB3C6) : AppColors.navUnselected,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF90CAF9) : AppColors.primary,
            );
          }
          return AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF9BB3C6) : AppColors.navUnselected,
          );
        }),
        elevation: AppElevation.low,
        height: AppSpacing.bottomNavHeight + 4,
      );

  // ── Legacy Bottom navigation theme (fallback compatibility) ─────
  static BottomNavigationBarThemeData _bottomNavTheme(bool isDark) =>
      BottomNavigationBarThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        selectedItemColor: isDark ? const Color(0xFF90CAF9) : AppColors.primary,
        unselectedItemColor: isDark
            ? const Color(0xFF9BB3C6)
            : AppColors.navUnselected,
        selectedLabelStyle: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.bodySmall,
        type: BottomNavigationBarType.fixed,
        elevation: AppElevation.high,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  // ── Dialog Theme ───────────────────────────────────────────────
  static DialogThemeData _dialogTheme(bool isDark) => DialogThemeData(
    backgroundColor: isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surfaceLight,
    elevation: AppElevation.medium,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
    titleTextStyle: AppTextStyles.headingSmall.copyWith(
      color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
    ),
    contentTextStyle: AppTextStyles.bodyMedium.copyWith(
      color: isDark ? const Color(0xFF9BB3C6) : AppColors.textSecondary,
    ),
  );

  // ── Bottom Sheet Theme ─────────────────────────────────────────
  static BottomSheetThemeData _bottomSheetTheme(bool isDark) =>
      BottomSheetThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceElevatedDark
            : AppColors.surfaceLight,
        modalBackgroundColor: isDark
            ? AppColors.surfaceElevatedDark
            : AppColors.surfaceLight,
        elevation: AppElevation.high,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      );

  // ── Color scheme builders ──────────────────────────────────────
  static ColorScheme _lightColorScheme() => const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.textOnPrimary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.accent,
    onTertiary: AppColors.textOnAccent,
    tertiaryContainer: AppColors.accentContainer,
    onTertiaryContainer: AppColors.onAccentContainer,
    error: AppColors.error,
    onError: AppColors.textOnPrimary,
    errorContainer: AppColors.errorBackground,
    onErrorContainer: AppColors.error,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.backgroundLight,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.border,
    outlineVariant: AppColors.divider,
    shadow: Color(0x190D2137),
    scrim: Color(0x5A0D2137),
    inverseSurface: AppColors.primary,
    onInverseSurface: AppColors.textOnPrimary,
    inversePrimary: AppColors.secondary,
  );

  static ColorScheme _darkColorScheme() => const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF90CAF9),
    onPrimary: AppColors.primary,
    primaryContainer: AppColors.secondary,
    onPrimaryContainer: AppColors.textOnPrimary,
    secondary: Color(0xFF7FB3D3),
    onSecondary: AppColors.primary,
    secondaryContainer: Color(0xFF1E3A52),
    onSecondaryContainer: Color(0xFFB0C4DE),
    tertiary: AppColors.accentLight,
    onTertiary: AppColors.primary,
    tertiaryContainer: Color(0xFF5E2B00),
    onTertiaryContainer: AppColors.accentLight,
    error: Color(0xFFEF9A9A),
    onError: Color(0xFF7F0000),
    errorContainer: Color(0xFF7F0000),
    onErrorContainer: Color(0xFFFFCDD2),
    surface: AppColors.surfaceDark,
    onSurface: Color(0xFFE8ECF0),
    surfaceContainerHighest: AppColors.backgroundDark,
    onSurfaceVariant: Color(0xFF9BB3C6),
    outline: Color(0xFF2C3E50),
    outlineVariant: Color(0xFF1E2D3D),
    shadow: Color(0x3C000000),
    scrim: Color(0x64000000),
    inverseSurface: Color(0xFFDEE3E9),
    onInverseSurface: AppColors.primary,
    inversePrimary: AppColors.secondary,
  );

  // ── Public theme accessors ─────────────────────────────────────
  static ThemeData get light => _buildTheme(isDark: false);
  static ThemeData get dark => _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final cs = isDark ? _darkColorScheme() : _lightColorScheme();
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      colorScheme: cs,
      scaffoldBackgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.appBarTitle,
        iconTheme: IconThemeData(color: AppColors.textOnPrimary),
      ),
      cardTheme: _cardTheme(isDark),
      inputDecorationTheme: _inputDecorationTheme(isDark),
      elevatedButtonTheme: _elevatedButtonTheme(isDark),
      outlinedButtonTheme: _outlinedButtonTheme(isDark),
      textButtonTheme: _textButtonTheme(isDark),
      navigationBarTheme: _navigationBarTheme(isDark),
      bottomNavigationBarTheme: _bottomNavTheme(isDark),
      dialogTheme: _dialogTheme(isDark),
      bottomSheetTheme: _bottomSheetTheme(isDark),
      chipTheme: _chipTheme(isDark),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF2C3E50) : AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: isDark ? const Color(0xFF9BB3C6) : AppColors.textSecondary,
        size: 24,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accent,
        circularTrackColor: isDark
            ? AppColors.surfaceDark
            : AppColors.accent.withAlpha(30),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppColors.surfaceElevatedDark
            : AppColors.primary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textOnPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headingLarge.copyWith(
          color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
        ),
        displayMedium: AppTextStyles.headingMedium.copyWith(
          color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
        ),
        displaySmall: AppTextStyles.headingSmall.copyWith(
          color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
        ),
        headlineLarge: AppTextStyles.headingLarge.copyWith(
          color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
        ),
        headlineMedium: AppTextStyles.headingMedium.copyWith(
          color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
        ),
        headlineSmall: AppTextStyles.headingSmall.copyWith(
          color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
        ),
        titleLarge: AppTextStyles.headingSmall.copyWith(
          color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
        ),
        titleMedium: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
        ),
        titleSmall: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? const Color(0xFF9BB3C6) : AppColors.textSecondary,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: isDark ? const Color(0xFF7E93A8) : AppColors.textSecondary,
        ),
        labelLarge: AppTextStyles.buttonLarge,
        labelMedium: AppTextStyles.buttonMedium,
        labelSmall: AppTextStyles.caption.copyWith(
          color: isDark ? const Color(0xFF7E93A8) : AppColors.textSecondary,
        ),
      ),
    );
  }
}
