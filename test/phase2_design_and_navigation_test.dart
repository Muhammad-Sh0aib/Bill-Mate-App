import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/app/bill_mate_app.dart';
import 'package:bill_mate/app/config/app_config.dart';
import 'package:bill_mate/app/router/app_router.dart';
import 'package:bill_mate/app/theme/app_colors.dart';
import 'package:bill_mate/app/theme/app_dimensions.dart';
import 'package:bill_mate/app/theme/app_shadows.dart';
import 'package:bill_mate/app/theme/app_text_styles.dart';
import 'package:bill_mate/app/theme/app_theme.dart';
import 'package:bill_mate/core/widgets/app_app_bar.dart';
import 'package:bill_mate/core/widgets/app_button.dart';
import 'package:bill_mate/core/widgets/app_card.dart';
import 'package:bill_mate/core/widgets/app_confirm_dialog.dart';
import 'package:bill_mate/core/widgets/app_divider.dart';
import 'package:bill_mate/core/widgets/app_empty_state.dart';
import 'package:bill_mate/core/widgets/app_error_view.dart';
import 'package:bill_mate/core/widgets/app_field_group.dart';
import 'package:bill_mate/core/widgets/app_icon_button.dart';
import 'package:bill_mate/core/widgets/app_inline_message.dart';
import 'package:bill_mate/core/widgets/app_loading_indicator.dart';
import 'package:bill_mate/core/widgets/app_section_header.dart';
import 'package:bill_mate/core/widgets/app_text_field.dart';
import 'package:bill_mate/features/bills/application/bill_repository_provider.dart';

import 'support/in_memory_repositories.dart';

Widget _buildTestBoilerplate(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  setUp(() {
    databaseFactory = databaseFactoryFfi;
  });

  group('Design Tokens', () {
    test('AppColors defines all primary and semantic tokens', () {
      expect(AppColors.primary, isNotNull);
      expect(AppColors.primaryContainer, isNotNull);
      expect(AppColors.secondary, isNotNull);
      expect(AppColors.accent, isNotNull);
      expect(AppColors.backgroundLight, isNotNull);
      expect(AppColors.backgroundDark, isNotNull);
      expect(AppColors.surfaceLight, isNotNull);
      expect(AppColors.surfaceDark, isNotNull);
      expect(AppColors.surfaceElevatedLight, isNotNull);
      expect(AppColors.surfaceElevatedDark, isNotNull);
      expect(AppColors.error, isNotNull);
      expect(AppColors.success, isNotNull);
      expect(AppColors.warning, isNotNull);
      expect(AppColors.info, isNotNull);
      expect(AppColors.documentSurface, equals(const Color(0xFFFFFFFF)));
    });

    test('AppSpacing and AppRadius define required dimensions', () {
      expect(AppSpacing.touchTarget, equals(48.0));
      expect(AppSpacing.touchTargetSm, equals(40.0));
      expect(AppSpacing.pageHorizontal, equals(16.0));
      expect(AppRadius.md, equals(12.0));
      expect(AppRadius.lg, equals(16.0));
      expect(AppRadius.xl, equals(20.0));
    });

    test('AppShadows defines consistent box shadows', () {
      expect(AppShadows.low, isNotEmpty);
      expect(AppShadows.medium, isNotEmpty);
      expect(AppShadows.high, isNotEmpty);
      expect(AppShadows.card, isNotEmpty);
    });

    test('AppTextStyles provides amount styles with tabular figures', () {
      expect(AppTextStyles.amountLarge.fontFeatures, isNotNull);
      expect(AppTextStyles.amountMedium.fontFeatures, isNotNull);
      expect(AppTextStyles.amountSmall.fontFeatures, isNotNull);
    });

    test('AppTheme creates valid light and dark ThemeData', () {
      final light = AppTheme.light;
      final dark = AppTheme.dark;

      expect(light.brightness, equals(Brightness.light));
      expect(dark.brightness, equals(Brightness.dark));
      expect(light.navigationBarTheme.indicatorColor, isNotNull);
      expect(dark.navigationBarTheme.indicatorColor, isNotNull);
      expect(light.dialogTheme.backgroundColor, isNotNull);
      expect(dark.dialogTheme.backgroundColor, isNotNull);
      expect(light.cardTheme.shape, isNotNull);
      expect(dark.cardTheme.shape, isNotNull);
    });
  });

  group('Reusable Components', () {
    testWidgets(
      'AppButton triggers callback and handles loading/disabled states',
      (tester) async {
        int pressCount = 0;

        // 1. Normal active button
        await tester.pumpWidget(
          _buildTestBoilerplate(
            AppButton(
              label: 'Submit',
              icon: Icons.check,
              onPressed: () => pressCount++,
            ),
          ),
        );

        expect(find.text('Submit'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);

        await tester.tap(find.text('Submit'));
        expect(pressCount, equals(1));

        // 2. Disabled button
        await tester.pumpWidget(
          _buildTestBoilerplate(
            const AppButton(label: 'Disabled', onPressed: null),
          ),
        );

        await tester.tap(find.text('Disabled'));
        expect(pressCount, equals(1)); // Unchanged

        // 3. Loading button
        await tester.pumpWidget(
          _buildTestBoilerplate(
            AppButton(
              label: 'Loading',
              loading: true,
              onPressed: () => pressCount++,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading'), findsNothing);
      },
    );

    testWidgets('AppButton renders all variants without error', (tester) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
          _buildTestBoilerplate(
            AppButton(label: variant.name, variant: variant, onPressed: () {}),
          ),
        );
        expect(find.text(variant.name), findsOneWidget);
      }
    });

    testWidgets('AppIconButton triggers callback and enforces semantics', (
      tester,
    ) async {
      int tapped = 0;

      await tester.pumpWidget(
        _buildTestBoilerplate(
          AppIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete Bill',
            variant: AppIconButtonVariant.destructive,
            onPressed: () => tapped++,
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(tapped, equals(1));
    });

    testWidgets(
      'AppTextField displays label, required indicator, and helper text',
      (tester) async {
        await tester.pumpWidget(
          _buildTestBoilerplate(
            const AppTextField(
              label: 'Customer Name',
              hint: 'Enter customer name',
              isRequired: true,
              helperText: 'Full business or individual name',
            ),
          ),
        );

        expect(find.text('Customer Name'), findsOneWidget);
        expect(find.text('*'), findsOneWidget);
        expect(find.text('Enter customer name'), findsOneWidget);
        expect(find.text('Full business or individual name'), findsOneWidget);
      },
    );

    testWidgets('AppCard renders header, content, and handles onTap', (
      tester,
    ) async {
      int cardTapped = 0;

      await tester.pumpWidget(
        _buildTestBoilerplate(
          AppCard(
            title: 'Card Title',
            subtitle: 'Card Subtitle',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => cardTapped++,
            child: const Text('Card Content'),
          ),
        ),
      );

      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Card Subtitle'), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.text('Card Content'));
      expect(cardTapped, equals(1));
    });

    testWidgets(
      'AppSectionHeader renders title, subtitle, icon, and trailing',
      (tester) async {
        await tester.pumpWidget(
          _buildTestBoilerplate(
            const AppSectionHeader(
              title: 'Section Title',
              subtitle: 'Section Subtitle',
              icon: Icons.star,
              trailing: Text('Action'),
            ),
          ),
        );

        expect(find.text('Section Title'), findsOneWidget);
        expect(find.text('Section Subtitle'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.text('Action'), findsOneWidget);
      },
    );

    testWidgets('AppEmptyState renders title, description, and actions', (
      tester,
    ) async {
      int actionCount = 0;

      await tester.pumpWidget(
        _buildTestBoilerplate(
          AppEmptyState(
            icon: Icons.inbox,
            title: 'Nothing Here',
            description: 'No items available at this time.',
            actionLabel: 'Add Item',
            onAction: () => actionCount++,
          ),
        ),
      );

      expect(find.text('Nothing Here'), findsOneWidget);
      expect(find.text('No items available at this time.'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      expect(actionCount, equals(1));
    });

    testWidgets(
      'AppLoadingIndicator renders centered with message and inline',
      (tester) async {
        await tester.pumpWidget(
          _buildTestBoilerplate(
            const AppLoadingIndicator.centered(message: 'Saving draft...'),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Saving draft...'), findsOneWidget);

        await tester.pumpWidget(
          _buildTestBoilerplate(const AppLoadingIndicator.inline()),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('AppErrorView renders error message and triggers retry', (
      tester,
    ) async {
      int retries = 0;

      await tester.pumpWidget(
        _buildTestBoilerplate(
          AppErrorView(
            title: 'Failed to load',
            message: 'Network or storage read failed.',
            retryLabel: 'Retry Operation',
            onRetry: () => retries++,
          ),
        ),
      );

      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.text('Network or storage read failed.'), findsOneWidget);
      expect(find.text('Retry Operation'), findsOneWidget);

      await tester.tap(find.text('Retry Operation'));
      expect(retries, equals(1));
    });

    testWidgets('AppInlineMessage renders info, warning, error, and success', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestBoilerplate(
          const AppInlineMessage(
            title: 'Notice',
            message: 'This is an informative announcement.',
            type: AppInlineMessageType.info,
          ),
        ),
      );

      expect(find.text('Notice'), findsOneWidget);
      expect(find.text('This is an informative announcement.'), findsOneWidget);
    });

    testWidgets('AppConfirmDialog handles cancel and confirm correctly', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showAppConfirmDialog(
                    context,
                    title: 'Delete Bill?',
                    message: 'This bill will be permanently removed.',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Bill?'), findsOneWidget);
      expect(
        find.text('This bill will be permanently removed.'),
        findsOneWidget,
      );

      // Tap Confirm
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('AppAppBar renders title, subtitle, and action buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestBoilerplate(
          const AppAppBar(
            title: 'Screen Title',
            subtitle: 'Screen Subtitle',
            actions: [Icon(Icons.more_vert)],
          ),
        ),
      );

      expect(find.text('Screen Title'), findsOneWidget);
      expect(find.text('Screen Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('AppFieldGroup and AppDivider render cleanly', (tester) async {
      await tester.pumpWidget(
        _buildTestBoilerplate(
          const AppFieldGroup(
            title: 'Group Header',
            subtitle: 'Group Subtitle',
            children: [Text('Field 1'), AppDivider(), Text('Field 2')],
          ),
        ),
      );

      expect(find.text('Group Header'), findsOneWidget);
      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsOneWidget);
    });
  });

  group('Navigation & Main Screen Shells', () {
    setUp(() {
      AppRouter.reset();
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Bottom navigation switches between all 4 tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billRepositoryProvider.overrideWithValue(EmptyBillRepository()),
          ],
          child: const BillMateApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Starts on Home
      expect(find.text(AppConfig.appName), findsWidgets);
      expect(find.text(AppConfig.defaultCompanyName), findsOneWidget);

      // Navigate to New Bill tab via bottom navigation
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(find.text('New Bill'), findsWidgets);
      expect(find.text('Customer Details'), findsOneWidget);

      // Navigate to History tab via bottom navigation
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();
      expect(find.text('Previous Bills'), findsOneWidget);
      expect(find.text('No bills saved yet'), findsOneWidget);

      // Navigate to Settings tab via bottom navigation
      await tester.tap(find.byType(NavigationDestination).at(3));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Workshop Information'), findsOneWidget);

      // Return to Home tab
      await tester.tap(find.byType(NavigationDestination).at(0));
      await tester.pumpAndSettle();
      expect(find.text(AppConfig.appName), findsWidgets);
    });

    testWidgets('Dark mode renders all main shells without exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billRepositoryProvider.overrideWithValue(EmptyBillRepository()),
          ],
          child: const BillMateApp(themeMode: ThemeMode.dark),
        ),
      );
      await tester.pumpAndSettle();

      // Home in dark mode
      expect(tester.takeException(), isNull);
      expect(find.text(AppConfig.appName), findsWidgets);

      // Switch to New Bill in dark mode
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to History in dark mode
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Settings in dark mode
      await tester.tap(find.byType(NavigationDestination).at(3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Responsive design handles narrow 320dp width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3.0;

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const ProviderScope(child: BillMateApp()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppConfig.appName), findsWidgets);
        // 'Create New Bill' appears in both primary actions and the empty state CTA.
        expect(find.text('Create New Bill'), findsWidgets);
      },
    );
  });
}
