import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bill_mate/core/widgets/app_section_header.dart';

void main() {
  testWidgets('debug app section header', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppSectionHeader(title: 'Bill Items')));
    print('header texts: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').toList()}');
    expect(find.text('Bill Items'), findsOneWidget);
  });
}
