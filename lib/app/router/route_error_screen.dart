import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_app_bar.dart';
import '../../core/widgets/app_error_view.dart';
import 'route_names.dart';

/// Fallback screen displayed when an invalid or unknown route is requested.
class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Page Not Found', showBackButton: false),
      body: SafeArea(
        child: AppErrorView(
          title: 'Route Not Found',
          message:
              'The requested screen "$location" does not exist or has been moved.',
          retryLabel: 'Return to Home',
          onRetry: () => context.goNamed(RouteNames.homeName),
        ),
      ),
    );
  }
}
