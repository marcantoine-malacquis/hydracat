import 'package:flutter/material.dart';

/// A screen that displays session logging information.
class LoggingScreen extends StatelessWidget {
  /// Creates a logging screen.
  const LoggingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Logging'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('Logging Screen - Coming Soon'),
      ),
    );
  }
}
