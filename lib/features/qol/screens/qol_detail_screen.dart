import 'package:flutter/material.dart';
import 'package:hydracat/shared/widgets/layout/layout.dart';

/// Detail screen for viewing a single QoL assessment.
///
/// This is a placeholder implementation.
/// Full implementation will be added in Phase 4.3.
class QolDetailScreen extends StatelessWidget {
  /// Creates a [QolDetailScreen].
  ///
  /// [assessmentId] is the document ID (YYYY-MM-DD format) of the
  /// assessment to display.
  const QolDetailScreen({
    required this.assessmentId,
    super.key,
  });

  /// Assessment document ID to display.
  ///
  /// Format: YYYY-MM-DD
  final String assessmentId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'QoL Results',
      body: Center(
        child: Text('QoL Detail Screen ($assessmentId) - Coming Soon'),
      ),
    );
  }
}
