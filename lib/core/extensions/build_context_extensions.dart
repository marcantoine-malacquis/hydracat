import 'package:flutter/material.dart';
import 'package:hydracat/l10n/app_localizations.dart';

/// Extensions for BuildContext to provide convenient access to app services
extension BuildContextExtensions on BuildContext {
  /// Access to app localizations
  ///
  /// Usage: `context.l10n.welcomeTitle`
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
