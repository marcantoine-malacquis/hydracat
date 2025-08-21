import 'package:flutter/material.dart';

/// A screen that displays user progress and analytics.
class ProgressScreen extends StatelessWidget {
  /// Creates a progress screen.
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress & Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('Progress Screen - Coming Soon'),
      ),
    );
  }
}
