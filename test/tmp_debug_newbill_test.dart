import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/features/bills/application/bill_draft_provider.dart';
import 'package:bill_mate/features/bills/presentation/new_bill_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('render new bill screen directly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: NewBillScreen())),
    );
    await tester.pumpAndSettle();
    print(
      'texts: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').toList()}',
    );
    await tester.dragUntilVisible(
      find.text('Bill Items'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    expect(find.text('Bill Items'), findsOneWidget);
  });
}
