import '../bills/domain/bill_discount.dart';
import 'voice_entry_models.dart';

class VoiceEntryParser {
  const VoiceEntryParser();

  RegExp _i(String pattern) => RegExp(pattern, caseSensitive: false);

  VoiceEntryProposal parse(String transcript) {
    final original = transcript.trim();
    if (original.isEmpty) {
      return const VoiceEntryProposal(
        transcript: '',
        customerName: '',
        items: <VoiceEntryItemProposal>[],
        billDiscount: BillDiscount(),
        warnings: <String>['No transcript was received for voice entry.'],
        issues: <String>['Transcript is empty.'],
      );
    }

    final warnings = <String>[];
    final issues = <String>[];

    final customerName = _extractCustomerName(original, warnings, issues);
    final cleanedTranscript = _removeCustomerPhrase(original, customerName);

    final billDiscount = _extractWholeBillDiscount(cleanedTranscript, warnings);
    final items = _extractItems(cleanedTranscript, warnings, issues);

    if (customerName.trim().isEmpty && items.isEmpty && billDiscount.isNone) {
      warnings.add('No bill details could be confidently understood.');
      issues.add(
        'Transcript does not contain recognizable billing instructions.',
      );
    }

    return VoiceEntryProposal(
      transcript: original,
      customerName: customerName.trim(),
      items: items,
      billDiscount: billDiscount,
      warnings: warnings,
      issues: issues,
    );
  }

  String _extractCustomerName(
    String transcript,
    List<String> warnings,
    List<String> issues,
  ) {
    final patterns = <RegExp>[
      _i(
        r'\bcustomer(?:\s+name)?\s+(?:is\s+|ka\s+naam\s+|naam\s+|should\s+be\s+)?(.{1,120})',
      ),
      _i(r'\bbill\s+for\s+(.{1,120})'),
      _i(r'\bcreate\s+bill\s+for\s+(.{1,120})'),
      _i(r'\bcustomer\s+ka\s+naam\s+(.{1,120})'),
      _i(r'\bcustomer\s+.*?\b(?:is|hai)\s+(.{1,120})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(transcript);
      if (match == null) continue;
      final value = _cleanCustomerValue(match.group(1) ?? '');
      if (value.isNotEmpty) return value;
    }

    if (transcript.toLowerCase().contains('customer')) {
      warnings.add('Customer name may need confirmation.');
    }
    return '';
  }

  String _cleanCustomerValue(String value) {
    final normalized = value
        .replaceAll(
          RegExp(
            r'\b(?:customer|bill|name|ka|naam|hai|is|for|should|be)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'[.!,;]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final segmented = normalized
        .split(
          RegExp(
            r'\s+(?=(?:whole|bill|total|discount|invoice|amount|cost|price|with|for|add|plus|then|next|item|items|and)\b)',
            caseSensitive: false,
          ),
        )
        .first
        .trim();

    return segmented
        .replaceAll(
          RegExp(
            r'^(?:whole|bill|total|discount|invoice|amount|cost|price)\b\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  String _truncateCustomerCandidate(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'^[^A-Za-z0-9]+|[^A-Za-z0-9]+$'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return '';
    final truncated = RegExp(
      r'^(.*?)(?:\s+(?:and|add|plus|then|next|item|items|with|for|total|discount|bill|invoice|amount|cost|price|rupees|rupay|rs|pkr))(?=\s|$).*$',
      caseSensitive: false,
    ).firstMatch(cleaned);

    if (truncated != null && truncated.group(1) != null) {
      final candidate = truncated.group(1)!.trim();
      if (candidate.isNotEmpty) return candidate;
    }

    return cleaned;
  }

  String _removeCustomerPhrase(String transcript, String customerName) {
    if (customerName.isEmpty) return transcript;

    final normalized = transcript.trim();
    final lower = normalized.toLowerCase();
    final customerLower = customerName.toLowerCase();
    final index = lower.indexOf(customerLower);
    if (index >= 0) {
      final afterName = normalized.substring(index + customerName.length);
      return afterName
          .replaceFirst(
            RegExp(
              r'^(?:\s*(?:and|plus|then|next|item|items|with|for)\b\s*)+',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
    }

    return normalized.replaceFirst(
      RegExp(
        r'(?:customer(?:\s+name)?\s+(?:is\s+|ka\s+naam\s+|naam\s+|should\s+be\s+)?|bill\s+for\s+|create\s+bill\s+for\s+)',
        caseSensitive: false,
      ),
      '',
    );
  }

  BillDiscount _extractWholeBillDiscount(
    String transcript,
    List<String> warnings,
  ) {
    final normalized = transcript.toLowerCase();
    final hasWholeBill =
        normalized.contains('whole bill') ||
        normalized.contains('total bill') ||
        normalized.contains('overall discount') ||
        normalized.contains('on the total') ||
        normalized.contains('on total') ||
        normalized.contains('whole-bill') ||
        normalized.contains('overall bill');
    if (!hasWholeBill) return const BillDiscount();

    final value = _extractDiscountValue(transcript);
    if (value == null) {
      warnings.add('The overall discount could not be interpreted clearly.');
      return const BillDiscount();
    }

    if (_containsPercentageKeyword(transcript)) {
      return BillDiscount(
        type: DiscountType.percentage,
        percentageInput: value
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'\.00$'), ''),
      );
    }

    return BillDiscount(
      type: DiscountType.fixed,
      fixedInput: value.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), ''),
    );
  }

  List<VoiceEntryItemProposal> _extractItems(
    String transcript,
    List<String> warnings,
    List<String> issues,
  ) {
    final phrases = _splitItemPhrases(transcript);
    final items = <VoiceEntryItemProposal>[];

    for (var index = 0; index < phrases.length; index++) {
      final itemPhrase = phrases[index].trim();
      if (itemPhrase.isEmpty) continue;
      if (_isDiscountPhrase(itemPhrase)) continue;

      final amount = _extractAmount(itemPhrase);
      final description = _extractDescription(
        itemPhrase,
        amount != null ? amount : null,
      );
      if (description.isEmpty) {
        if (itemPhrase.toLowerCase().contains('discount')) {
          continue;
        }
        warnings.add('One item description could not be read clearly.');
        continue;
      }

      if (amount == null) {
        warnings.add('Amount missing for "$description".');
        items.add(
          VoiceEntryItemProposal(
            id: 'voice-item-${DateTime.now().microsecondsSinceEpoch}-${index}',
            description: description,
            amountInput: '',
            warning: 'Amount required',
          ),
        );
        continue;
      }

      final discount = _extractItemDiscount(itemPhrase, description);
      items.add(
        VoiceEntryItemProposal(
          id: 'voice-item-${DateTime.now().microsecondsSinceEpoch}-${index}',
          description: description,
          amountInput: _formatAmountInput(amount),
          discount: discount,
        ),
      );
    }

    return items;
  }

  String _formatAmountInput(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  List<String> _splitItemPhrases(String transcript) {
    final compact = transcript.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) return const [];

    final separators = RegExp(
      r'(?:\b(?:also\s+add|another\s+item|next\s+item|then|plus|and)\b|[,;]|\.|\s+\b(?:item|work|repair|service|part|job)\s+is\b)',
      caseSensitive: false,
    );

    final rawParts = compact.split(separators);
    final result = <String>[];
    for (final part in rawParts) {
      final cleaned = part
          .replaceAll(
            RegExp(
              r'\b(?:add|also|another|next|then|plus|item|work|repair|service|part|job|charge|is|ka|karo|lagao|lo)\b',
              caseSensitive: false,
            ),
            ' ',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (cleaned.isNotEmpty) {
        result.add(cleaned);
      }
    }

    return result;
  }

  bool _isDiscountPhrase(String phrase) {
    final lower = phrase.toLowerCase();
    return lower.contains('discount') ||
        lower.contains('deduct') ||
        lower.contains('less');
  }

  String _extractDescription(String phrase, num? amount) {
    String cleaned = phrase.trim();
    if (_containsDiscountKeyword(cleaned)) {
      cleaned = cleaned.replaceAll(
        RegExp(
          r'(?:with|less|discount|deduct|give|amount|price|cost|rupees|rupay|rs|pkr|percent|%|of)\b.*$',
          caseSensitive: false,
        ),
        '',
      );
    }
    if (amount != null) {
      cleaned = cleaned.replaceAll(
        RegExp(
          r'(?:\d+(?:\.\d+)?|one|two|three|four|five|six|seven|eight|nine|ten|hundred|thousand|lakh|lac|crore|million|k|rupees|rupay|rs|pkr)\s*',
          caseSensitive: false,
        ),
        '',
      );
    }
    final cleanedDescription = cleaned
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[^A-Za-z0-9]+|[^A-Za-z0-9]+$'), '')
        .trim();

    return cleanedDescription
        .replaceAll(
          RegExp(
            r'(?:\s+\b(?:for|of|with|plus|and|then|next|item|items|discount|amount|price|cost|rupees|rs|pkr|is|ka|karo|lagao|lo)\b)+$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  bool _containsDiscountKeyword(String phrase) {
    final lower = phrase.toLowerCase();
    return lower.contains('discount') ||
        lower.contains('deduct') ||
        lower.contains('less') ||
        lower.contains('percent');
  }

  double? _extractAmount(String phrase) {
    final lower = phrase.toLowerCase();
    final hasNumeric = RegExp(r'\d').hasMatch(phrase);
    final hasWordAmount = _containsAmountKeyword(lower);
    if (!hasNumeric && !hasWordAmount) return null;

    final valueText = phrase
        .replaceAll(
          RegExp(
            r'\b(?:pkr|rs|rupees?|rupay|pakistani|amount|cost|price)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .trim();

    if (RegExp(r'\d+(?:\.\d+)?').hasMatch(valueText)) {
      final direct = double.tryParse(
        valueText.replaceAll(RegExp(r'[^0-9.\-]'), ''),
      );
      if (direct != null) return direct;
    }

    if (lower.contains('point')) {
      final parts = lower.split(RegExp(r'\bpoint\b'));
      if (parts.length == 2) {
        final left = _parseWordNumber(parts[0]);
        final right = _parseWordNumber(parts[1]);
        if (left != null && right != null) return left + (right / 100.0);
      }
    }

    final parsed = _parseWordNumber(lower);
    return parsed;
  }

  double? _parseWordNumber(String text) {
    final job = text
        .replaceAll(RegExp(r'[^a-z0-9\s\.-]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();

    if (job.isEmpty) return null;

    final numberWords = <String, int>{
      'zero': 0,
      'nill': 0,
      'ek': 1,
      'one': 1,
      'do': 2,
      'two': 2,
      'tin': 3,
      'three': 3,
      'char': 4,
      'four': 4,
      'panch': 5,
      'five': 5,
      'six': 6,
      'sat': 7,
      'seven': 7,
      'ath': 8,
      'eight': 8,
      'nau': 9,
      'nine': 9,
      'das': 10,
      'ten': 10,
      'gyarah': 11,
      'eleven': 11,
      'barah': 12,
      'twelve': 12,
      'terah': 13,
      'thirteen': 13,
      'chudah': 14,
      'fourteen': 14,
      'pandrah': 15,
      'fifteen': 15,
      'solah': 16,
      'sixteen': 16,
      'satrah': 17,
      'seventeen': 17,
      'atharah': 18,
      'eighteen': 18,
      'unnis': 19,
      'nineteen': 19,
      'bees': 20,
      'twenty': 20,
      'tees': 30,
      'thirty': 30,
      'chalis': 40,
      'forty': 40,
      'pachas': 50,
      'fifty': 50,
      'sath': 60,
      'sixty': 60,
      'sattar': 70,
      'seventy': 70,
      'assi': 80,
      'eighty': 80,
      'nawab': 90,
      'ninety': 90,
      'hundred': 100,
      'thousand': 1000,
      'k': 1000,
      'lakh': 100000,
      'lac': 100000,
      'crore': 10000000,
      'million': 1000000,
    };

    double total = 0;
    double current = 0;
    double lastScale = 1;

    for (final token in job) {
      final cleaned = token.trim();
      if (cleaned.isEmpty) continue;
      if (cleaned == 'and' || cleaned == '&' || cleaned == 'point') continue;
      if (RegExp(r'^\d+(?:\.\d+)?$').hasMatch(cleaned)) {
        current += double.parse(cleaned);
        continue;
      }
      final encoded = cleaned.toLowerCase();
      if (numberWords.containsKey(encoded)) {
        final value = numberWords[encoded]!;
        if (value >= 1000) {
          total += current * value;
          current = 0;
          lastScale = value.toDouble();
        } else if (value >= 100) {
          current *= value.toDouble();
        } else {
          current += value.toDouble();
        }
        continue;
      }
      if (cleaned.endsWith('%')) {
        current += double.parse(cleaned.replaceAll('%', ''));
      }
    }

    total += current;
    return total == 0 ? null : total;
  }

  bool _containsAmountKeyword(String text) {
    return text.contains('rupee') ||
        text.contains('rupay') ||
        text.contains('rs') ||
        text.contains('pkr') ||
        text.contains('thousand') ||
        text.contains('hundred') ||
        text.contains('lakh') ||
        text.contains('lac') ||
        text.contains('crore') ||
        text.contains('k') ||
        text.contains('million');
  }

  bool _containsPercentageKeyword(String text) {
    final lower = text.toLowerCase();
    return lower.contains('percent') || lower.contains('%');
  }

  double? _extractDiscountValue(String transcript) {
    final cleaned = transcript.replaceAll(
      RegExp(
        r'\b(?:whole|bill|overall|total|discount|percent|percentage|rupee|rupay|rs|pkr|less|give|apply|deduct)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    final match = RegExp(r'(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(cleaned);
    if (match == null) {
      final numeric = _parseWordNumber(cleaned);
      if (numeric == null) return null;
      return numeric;
    }
    final value = double.tryParse(match.group(1) ?? '');
    return value;
  }

  BillDiscount _extractItemDiscount(String phrase, String description) {
    final lower = phrase.toLowerCase();
    if (!lower.contains('discount') &&
        !lower.contains('deduct') &&
        !lower.contains('less')) {
      return const BillDiscount();
    }

    final numericValue = _extractDiscountValue(phrase);
    if (numericValue == null) return const BillDiscount();

    if (_containsPercentageKeyword(phrase)) {
      return BillDiscount(
        type: DiscountType.percentage,
        percentageInput: numericValue
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'\.00$'), ''),
      );
    }

    return BillDiscount(
      type: DiscountType.fixed,
      fixedInput: numericValue
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'\.00$'), ''),
    );
  }
}
