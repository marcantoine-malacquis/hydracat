import 'package:flutter/material.dart';

/// A screen that displays schedule information.
class ScheduleScreen extends StatelessWidget {
  /// Creates a schedule screen.
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('Schedule Screen - Coming Soon'),
      ),
    );
  }
}
