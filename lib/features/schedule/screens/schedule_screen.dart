import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A screen that displays schedule information.
class ScheduleScreen extends StatelessWidget {
  /// Creates a schedule screen.
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      appBar: HydraAppBar(
        title: Text('Schedule'),
      ),
      body: Center(
        child: Text('Schedule Screen - Coming Soon'),
      ),
    );
  }
}
