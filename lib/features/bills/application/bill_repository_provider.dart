import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bill_repository.dart';

final billRepositoryProvider = Provider<BillRepository>(
  (ref) => BillRepository(),
);
