import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// A screen that displays discover content for users.
class DiscoverScreen extends StatelessWidget {
  /// Creates a discover screen.
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final body = buildBody(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const HydraAppBar(
        title: Text('Discover'),
        style: HydraAppBarStyle.accent,
      ),
      body: body,
    );
  }

  /// Builds the body content for the learn screen.
  /// This static method can be used by AppShell to get body-only content.
  static Widget buildBody(BuildContext context) {
    return const Center(
      child: Text('Discover Screen - Coming Soon'),
    );
  }
}
