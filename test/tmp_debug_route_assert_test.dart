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

  testWidgets('route to new bill has bill items section', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BillMateApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create New Bill').first);
    await tester.pumpAndSettle();
    print('texts after tap: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').toList()}');
    expect(find.text('Bill Items'), findsOneWidget);
  });
}
