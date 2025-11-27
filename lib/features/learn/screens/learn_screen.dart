import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A screen that displays resources and tips for users.
class ResourcesScreen extends StatelessWidget {
  /// Creates a learn screen.
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final body = buildBody(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HydraAppBar(
        title: const Text('Learn'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: body,
    );
  }

  /// Builds the body content for the learn screen.
  /// This static method can be used by AppShell to get body-only content.
  static Widget buildBody(BuildContext context) {
    return const Center(
      child: Text('Learn Screen - Coming Soon'),
    );
  }
}
