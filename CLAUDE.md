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
- **Internationalization**: Use l10n in `lib/l10n`

## Important Instruction Reminders
- Do what has been asked; nothing more, nothing less.
- NEVER create files unless absolutely necessary for achieving your goal.
- ALWAYS prefer editing an existing file to creating a new one.
- NEVER proactively create documentation files (*.md) or README files unless explicitly requested.