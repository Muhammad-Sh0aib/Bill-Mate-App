import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/bills/application/bill_draft_provider.dart';
import '../../features/bills/presentation/bill_draft_navigation_guard.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  Future<void> _onDestinationSelected(int index) async {
    final currentIndex = widget.navigationShell.currentIndex;
    if (index == currentIndex) {
      widget.navigationShell.goBranch(index, initialLocation: true);
      return;
    }

    final staysInBillWorkflow =
        (currentIndex == 1 && index == 3) || (currentIndex == 3 && index == 1);
    if (!staysInBillWorkflow && ref.read(billDraftProvider).hasUnsavedChanges) {
      final mayLeave = await confirmBillDraftExit(context, ref);
      if (!mounted || !mayLeave) return;
    }
    widget.navigationShell.goBranch(index);
  }

  Future<void> _handleSystemBack() async {
    final uri = GoRouter.of(context).routeInformationProvider.value.uri;
    if (widget.navigationShell.currentIndex == 3 &&
        uri.queryParameters['returnToBill'] == 'true') {
      ref.read(billDraftProvider.notifier).refreshDateIfUntouched();
      widget.navigationShell.goBranch(1);
      return;
    }

    final mayLeave = await confirmBillDraftExit(context, ref);
    if (mounted && mayLeave) widget.navigationShell.goBranch(0);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final hasUnsavedBill = ref.watch(billDraftProvider).hasUnsavedChanges;

    return PopScope(
      canPop: currentIndex == 0 && !hasUnsavedBill,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != 0) _handleSystemBack();
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
              tooltip: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline_rounded),
              selectedIcon: Icon(Icons.add_circle_rounded),
              label: 'New Bill',
              tooltip: 'Create New Bill',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'History',
              tooltip: 'Previous Bills',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
              tooltip: 'Company Settings',
            ),
          ],
        ),
      ),
    );
  }
}
