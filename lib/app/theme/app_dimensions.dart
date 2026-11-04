/// Spacing, sizing, and radius constants for BillMate.
///
/// Import this class instead of scattering raw pixel values throughout
/// widget files. All values are in logical pixels.
abstract class AppSpacing {
  AppSpacing._();

  // ── Base unit: 4 dp ──────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ── Page / screen padding ─────────────────────────────────────
  static const double pagePadding = 16.0;
  static const double pageHorizontal = 16.0;
  static const double pageVertical = 20.0;

  // ── Card / list item internals ────────────────────────────────
  static const double cardPaddingH = 16.0;
  static const double cardPaddingV = 14.0;
  static const double listItemPaddingV = 12.0;

  // ── Section gaps ──────────────────────────────────────────────
  static const double sectionGap = 24.0;
  static const double itemGap = 12.0;
  static const double inlineGap = 8.0;

  // ── Minimum touch targets ─────────────────────────────────────
  /// 48 dp — Android accessibility recommendation.
  static const double touchTarget = 48.0;

  /// Compact touch target for dense contexts.
  static const double touchTargetSm = 40.0;

  // ── Bottom navigation bar ─────────────────────────────────────
  static const double bottomNavHeight = 64.0;
}

/// Corner radius tokens.
abstract class AppRadius {
  AppRadius._();

  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double full = 999.0;
}

/// Icon and avatar size tokens.
abstract class AppIconSize {
  AppIconSize._();

  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
}

/// Elevation tokens.
abstract class AppElevation {
  AppElevation._();

  static const double none = 0.0;
  static const double low = 1.0;
  static const double medium = 3.0;
  static const double high = 6.0;
}
