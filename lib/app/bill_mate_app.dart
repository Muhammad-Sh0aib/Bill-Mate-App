import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';

/// Root application widget for BillMate.
///
/// Sets up the Riverpod [ProviderScope] (already done in main.dart),
/// theme, routing, and localization delegates.
class BillMateApp extends ConsumerWidget {
  const BillMateApp({super.key, this.themeMode = ThemeMode.light});

  /// The active theme mode (defaults to [ThemeMode.light]).
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      // ── Identity ──────────────────────────────────────────────
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,

      // ── Routing ───────────────────────────────────────────────
      routerConfig: AppRouter.router,

      // ── Theme ─────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // ── Localization ──────────────────────────────────────────
      // The localization delegates are included to support future
      // Urdu (ur) localization without requiring a structural change.
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'PK'),
        // Placeholder for future Urdu support:
        // Locale('ur', 'PK'),
      ],
    );
  }
}
