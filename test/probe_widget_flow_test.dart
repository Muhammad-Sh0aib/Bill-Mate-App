import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/app/bill_mate_app.dart';
import 'package:bill_mate/features/bills/application/bill_draft_provider.dart';
import 'package:bill_mate/features/company_settings/application/company_settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/in_memory_repositories.dart';

Future<void> _openNewBill(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        companySettingsRepositoryProvider.overrideWithValue(
          MemoryCompanySettingsRepository(),
        ),
      ],
      child: const BillMateApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Create New Bill').first);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('probe save flow updates provider snapshot and route', (
    tester,
  ) async {
    await _openNewBill(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Atlas Printing');
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('Edit'),
      find.byType(ListView).first,
      const Offset(0, 300),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Atlas Workshop');
    await tester.enterText(find.byType(TextFormField).at(1), '0300-0000000');
    await tester.dragUntilVisible(
      find.text('Save Company Details'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.tap(find.text('Save Company Details'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BillMateApp)),
      listen: false,
    );
    final draftBefore = container.read(billDraftProvider);
    expect(draftBefore.companySnapshot.name, 'Atlas Workshop');
  });
}
