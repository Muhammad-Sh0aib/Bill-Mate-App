import 'package:flutter_riverpod/flutter_riverpod.dart';

final billHistoryRefreshProvider =
    NotifierProvider<BillHistoryRefreshController, int>(
      BillHistoryRefreshController.new,
    );

class BillHistoryRefreshController extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() => state++;
}
