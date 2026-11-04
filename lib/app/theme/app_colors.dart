import 'package:flutter/material.dart';

/// Central color palette and semantic color tokens for BillMate.
///
/// All colors are defined here. No widget should contain a hardcoded
/// color literal — import this class or consume [Theme.of(context).colorScheme].
abstract class AppColors {
  AppColors._();

  // ── Primary brand palette ──────────────────────────────────────
  /// Deep navy blue — primary brand color.
  static const Color primary = Color(0xFF0D2137);

  /// Primary container background for light highlights and badges.
  static const Color primaryContainer = Color(0xFFE8EEF4);
  static const Color onPrimaryContainer = Color(0xFF0D2137);

  /// Professional medium blue — secondary / interactive elements.
  static const Color secondary = Color(0xFF1A5276);
  static const Color secondaryContainer = Color(0xFFD4E6F1);
  static const Color onSecondaryContainer = Color(0xFF0E3A53);

  /// Restrained orange accent — highlights, active states, key actions.
  static const Color accent = Color(0xFFE67E22);
  static const Color accentLight = Color(0xFFF0A96F);
  static const Color accentContainer = Color(0xFFFDF2E9);
  static const Color onAccentContainer = Color(0xFF7E3B00);

  // ── Backgrounds ────────────────────────────────────────────────
  /// Main app background — soft off-white.
  static const Color backgroundLight = Color(0xFFF5F6FA);

  /// Dark mode background.
  static const Color backgroundDark = Color(0xFF0F1923);

  // ── Surfaces ───────────────────────────────────────────────────
  /// Card and surface background (light mode).
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Card and surface background (dark mode).
  static const Color surfaceDark = Color(0xFF1C2B3A);

  /// Elevated surface background for modals, cards, popups (light mode).
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);

  /// Elevated surface background for modals, cards, popups (dark mode).
  static const Color surfaceElevatedDark = Color(0xFF243447);

  /// Disabled surface background for disabled fields and controls.
  static const Color disabledSurface = Color(0xFFEAEDF1);

  // ── Text & Content ─────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF5D6D7E);
  static const Color textDisabled = Color(0xFFABB2B9);

  /// Inverted text used on dark/primary backgrounds.
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── Borders and dividers ───────────────────────────────────────
  static const Color border = Color(0xFFDDE1E7);
  static const Color borderFocused = Color(0xFF1A5276);
  static const Color divider = Color(0xFFEAEBEF);

  // ── Interaction / Focus states ─────────────────────────────────
  static const Color focus = Color(0xFF1A5276);

  // ── Semantic status colors ─────────────────────────────────────
  static const Color error = Color(0xFFE53935);
  static const Color errorBackground = Color(0xFFFFEBEE);

  static const Color success = Color(0xFF2E7D32);
  static const Color successBackground = Color(0xFFE8F5E9);

  static const Color warning = Color(0xFFF57F17);
  static const Color warningBackground = Color(0xFFFFFDE7);

  static const Color info = Color(0xFF0277BD);
  static const Color infoBackground = Color(0xFFE1F5FE);

  // ── Navigation ─────────────────────────────────────────────────
  static const Color navSelected = primary;
  static const Color navUnselected = Color(0xFF8395A7);
  static const Color navBackground = surfaceLight;

  // ── Bill / document area ───────────────────────────────────────
  /// Always white, regardless of theme — bills look like paper.
  static const Color documentSurface = Color(0xFFFFFFFF);
  static const Color documentBorder = Color(0xFFCFD8DC);
  static const Color documentTextPrimary = Color(0xFF1A1A2E);

  // ── Shimmer / skeleton loading ─────────────────────────────────
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
