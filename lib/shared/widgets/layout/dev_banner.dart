import 'package:flutter/material.dart';
import 'package:hydracat/core/config/flavor_config.dart';

/// A banner widget that displays "DEV" in development builds only.
class DevBanner extends StatelessWidget {
  /// Creates a dev banner.
  const DevBanner({required this.child, super.key});

  /// The child widget to wrap with the banner.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!FlavorConfig.isDevelopment) {
      return child;
    }

    return Banner(
      message: 'DEV',
      location: BannerLocation.topEnd,
      color: Colors.red,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      child: child,
    );
  }
}
