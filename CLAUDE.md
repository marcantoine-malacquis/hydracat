# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Core Flutter Commands
- **Run App (Development)**: `flutter run --flavor development -t lib/main_development.dart`
- **Run App (Production)**: `flutter run --flavor production -t lib/main_production.dart`
- **Run Tests**: `flutter test`
- **Code Analysis**: `flutter analyze`
- **Generate Code**: `dart run build_runner build`
- **Clean Build**: `flutter clean && flutter pub get`

### Build Commands
- **Build APK**: `flutter build apk --flavor [development|production] -t lib/main_[flavor].dart`
- **Build iOS**: `flutter build ios --flavor [development|production] -t lib/main_[flavor].dart`

## Architecture Overview

### Project Structure
```
lib/
├── app/                    # App shell, routing, main entry point
├── core/                   # Infrastructure (config, theme, constants, utils)
├── features/               # Domain-driven feature modules
├── shared/                 # Reusable services, repositories, widgets
├── providers/              # Riverpod state management
└── l10n/                   # Internationalization
```

**Ideal Structure Reference**: `ideal_archi.md` (updated regularly)

### State Management
- **Riverpod**: Primary state management solution
- **Provider Pattern**: Service layer abstraction
- **Repository Pattern**: Data access layer with Firebase integration

### Flavors & Firebase
- **Development**: Firebase project `hydracattest`, app name "Hydracat Dev"
- **Production**: Firebase project `myckdapp`, app name "Hydracat"
- **Services**: Auth, Firestore, Analytics, Crashlytics, Messaging, Storage
- **Config**: Environment-specific via `lib/firebase_options.dart` with `FlavorConfig`

### Analytics
- **Reference Documentation**: `.cursor/reference/analytics_list.md` - **MUST be updated** when adding/modifying/removing analytics events
- **Service Location**: `lib/providers/analytics_provider.dart`
- **Privacy**: No PII, sanitize sensitive data

## Code Standards

### Naming Conventions
**Critical**: Follow semantic naming rules defined in `.cursor/code reviews/semantic_rules.md`
- Boolean variables: Use `is`, `has`, `should`, `can`, `was` prefixes
- Methods: Use clear action verbs (`get`, `fetch`, `save`, `update`, `delete`)
- Variables: Avoid generic names (`data`, `value`, `temp`) - use context-specific names
- See semantic_rules.md for real-world examples and safe refactoring process

### Analysis & Testing
- Uses `very_good_analysis` for strict linting
- Custom rules in `analysis_options.yaml`
- Run `flutter analyze` before committing
- **Widget Tests**: Located in `test/`
- **Test Command**: `flutter test`
- **Important**: Update `test/tests_index.md` when creating new tests

### Data Models
- **Standard Dart Classes**: Manual data classes with optional JSON serialization
- **Code Generation**: Run `dart run build_runner build` after model changes

### Localization
- **All user-facing text must be localized**: Never use hardcoded strings for text displayed to users. All labels, titles, messages, buttons, placeholders, and error messages must use localization keys from `lib/l10n/app_en.arb`.
- **Access localization**: Use `AppLocalizations.of(context)!` or `context.l10n` extension to access localized strings.
- **Add new keys**: When adding new text, add the key-value pair to `lib/l10n/app_en.arb` following existing naming conventions (e.g., `medicationLoggingTitle`, `errorSavingMedicalInfo`).
- **Key naming**: Use descriptive, context-specific names (e.g., `medicationLoggingTitle` not `title1`).
- **Placeholders**: Use Flutter's ARB format for parameterized strings (e.g., `"message": "Hello {name}"` with `@message` metadata).
- **Example**:
  - ❌ `Text('Medication')`
  - ✅ `Text(l10n.medicationLoggingTitle)`

### Flutter Performance Best Practices
- **Widget Classes Over Methods**: Extract widget-returning methods into dedicated widget classes (StatelessWidget/StatefulWidget). This allows Flutter's reconciliation algorithm to optimize rebuilds and enables const constructors.
  - ❌ `Widget _buildHeader() => Container(...)`
  - ✅ `class _Header extends StatelessWidget { ... }`
- **ListView.builder() for Lists**: Always use `ListView.builder()` instead of `ListView(children: [...])` for dynamic lists. Builder pattern enables lazy loading and widget recycling, critical for lists with 10+ items.
  - ❌ `ListView(children: items.map((i) => ItemWidget(i)).toList())`
  - ✅ `ListView.builder(itemCount: items.length, itemBuilder: (context, index) => ItemWidget(items[index]))`
- **Minimize calculations in build()**: The build() method can be called frequently. Avoid repeated expensive operations within the same build() call by computing values once and storing them in local variables.
- **Lifecycle-scoped caching**: For StatefulWidgets, move calculations that don't depend on changing parameters to `initState()` when possible. Note: values from InheritedWidgets (Theme, MediaQuery) cannot be computed in `initState()`.
- **Const constructors**: Use `const` wherever possible - Flutter can skip rebuilding const widgets entirely.
- **Isolates for CPU-Intensive Operations**: Isolates run code in separate memory spaces, preventing UI blocking. Use for operations that take >16ms of CPU time (image processing, large JSON parsing, complex calculations).
- **Use `compute()` for simplicity**: Flutter's `compute()` function simplifies one-off isolate tasks without manual management.
- **Don't use Isolates for async I/O**: Network requests and file operations are already non-blocking via async/await - they don't need Isolates.
- **Mind the overhead**: Data serialization between isolates has cost. Profile to ensure the benefit outweighs the overhead.
- **Profile first**: Use Flutter DevTools to identify actual bottlenecks before optimizing.

### Image Optimization
- **Multi-density assets**: Provide 1x, 2x, 3x variants for raster images in assets/images/ subfolders. Flutter automatically selects based on devicePixelRatio.
- **Format selection**:
  - SVG for icons/logos (use flutter_svg package) - scalable and smallest file size
  - PNG for images requiring transparency
  - JPEG (quality: 85) for photos and complex images
  - WebP when file size is critical (test cross-platform compatibility first)
- **Size appropriately**: Match image resolution to display size at 3x density (e.g., 100px display → provide 100px @1x, 200px @2x, 300px @3x). Avoid loading oversized images that get downscaled.
- **Compress**: Use tools like TinyPNG, ImageOptim, or squoosh.app to reduce file size without quality loss.
- **Lazy loading**: Use FadeInImage or cached_network_image for network images to improve initial load time.

### Feature Structure
Each feature follows domain-driven design:
```
features/[feature]/
├── screens/               # UI screens
├── widgets/               # Feature-specific UI components
├── exceptions/            # Exceptions
├── models/                # Data models
├── mixins/                # Reusable UI behavior (if needed)
└── services/              # Business logic
```

## Development Workflow

1. **Setup**: Run `flutter pub get` to install dependencies
2. **Development**: Use `flutter run --flavor development` to start the app
3. **Code Generation**: Run `dart run build_runner build` after model changes (when needed)
4. **Testing**: Execute `flutter test` before commits
5. **Analysis**: Run `flutter analyze` to check for issues

## Important Planning Files

- **Initial project setup**: `~PLANNING/DONE/SETUP.md`
- **Authentication**: `~PLANNING/auth_implementation_plan.md`
- **Onboarding & Pet profile**: `~PLANNING/onboarding_profile_plan.md`
- **Logging**: `~PLANNING/logging_plan.md`
- **Notifications & Reminders**: `~PLANNING/reminder_plan.md`

*Completed planning files are moved from `~PLANNING` to `~PLANNING/DONE`*

## Important Notes

- **Security**: API keys stored in Firebase configuration files
- **Entry Points**: Development (`main_development.dart`), Production (`main_production.dart`), Default (`main.dart` → development)
- **iOS Setup**: Requires manual Xcode configuration for build schemes
- **Internationalization**: All user-facing text must be localized using `lib/l10n/app_en.arb`. See Code Standards > Localization for best practices.

## Important Instruction Reminders
- Do what has been asked; nothing more, nothing less.
- NEVER create files unless absolutely necessary for achieving your goal.
- ALWAYS prefer editing an existing file to creating a new one.
- NEVER proactively create documentation files (*.md) or README files unless explicitly requested.