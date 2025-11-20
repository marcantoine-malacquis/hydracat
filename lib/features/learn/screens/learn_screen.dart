import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';

/// A screen that displays resources and tips for users.
class ResourcesScreen extends StatelessWidget {
  /// Creates a learn screen.
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Learn'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('Learn Screen - Coming Soon'),
      ),
    );
  }
}
