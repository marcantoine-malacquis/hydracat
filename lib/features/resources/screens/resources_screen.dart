import 'package:flutter/material.dart';

/// A screen that displays resources and tips for users.
class ResourcesScreen extends StatelessWidget {
  /// Creates a resources screen.
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources & Tips'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('Resources Screen - Coming Soon'),
      ),
    );
  }
}
