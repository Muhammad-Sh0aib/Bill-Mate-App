import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/app/bill_mate_app.dart';
import 'package:bill_mate/app/router/app_router.dart';
import 'package:bill_mate/features/bills/presentation/new_bill_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    databaseFactory = databaseFactoryFfi;
    AppRouter.reset();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('inspect new bill widget tree after route change', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BillMateApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create New Bill').first);
    await tester.pumpAndSettle();
    print('newbill count: ${tester.widgetList(find.byType(NewBillScreen)).length}');
    print('texts: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').take(60).toList()}');
    print('NewBillScreen widgets: ${tester.widgetList(find.byType(NewBillScreen)).toList()}');
    expect(find.byType(NewBillScreen), findsOneWidget);
  });
}
