import 'package:bill_mate/features/bills/domain/bill_discount.dart';
import 'package:bill_mate/features/voice_entry/voice_entry_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceEntryParser', () {
    test(
      'extracts customer name and item amounts from a natural transcript',
      () {
        const parser = VoiceEntryParser();
        final proposal = parser.parse(
          'Customer is Ali. Add shampoo for 250 and paint for 300.',
        );

        expect(proposal.customerName, 'Ali');
        expect(proposal.items, hasLength(2));
        expect(
          proposal.items.map((item) => item.description).toList(),
          containsAll(['shampoo', 'paint']),
        );
        expect(
          proposal.items.map((item) => item.amountInput).toList(),
          containsAll(['250', '300']),
        );
      },
    );

    test('detects a whole-bill percentage discount', () {
      const parser = VoiceEntryParser();
      final proposal = parser.parse(
        'Bill for Jamal. Whole bill discount 10 percent. Add repair for 1500.',
      );

      expect(proposal.customerName, 'Jamal');
      expect(proposal.billDiscount.type, DiscountType.percentage);
      expect(proposal.billDiscount.percentageInput, '10');
      expect(proposal.items, hasLength(1));
    });

    test('stops customer parsing at the first instruction phrase', () {
      const parser = VoiceEntryParser();
      final proposal = parser.parse(
        'Customer name is Sara and add item bulb 120 and fan 250.',
      );

      expect(proposal.customerName, 'Sara');
      expect(
        proposal.items.map((item) => item.description).toList(),
        containsAll(['bulb', 'fan']),
      );
    });
  });
}
