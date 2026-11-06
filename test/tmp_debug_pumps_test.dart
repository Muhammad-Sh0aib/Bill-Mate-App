import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/app/bill_mate_app.dart';
import 'package:bill_mate/app/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    databaseFactory = databaseFactoryFfi;
    AppRouter.reset();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('route pump sequence reveals bill items after extra rebuilds', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: BillMateApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create New Bill').first);
    for (var i = 0; i < 10; i++) {
      await tester.pump();
    }
    print(
      'texts after repeated pumps: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').toList()}',
    );
    await tester.dragUntilVisible(
      find.text('Bill Items'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    expect(find.text('Bill Items'), findsOneWidget);
  });
}
