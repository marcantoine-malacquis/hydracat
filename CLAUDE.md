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
- **Build APK (Development)**: `flutter build apk --flavor development -t lib/main_development.dart`
- **Build APK (Production)**: `flutter build apk --flavor production -t lib/main_production.dart`
- **Build iOS (Development)**: `flutter build ios --flavor development -t lib/main_development.dart`
- **Build iOS (Production)**: `flutter build ios --flavor production -t lib/main_production.dart`

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
### Ideal Structure reference

**Ideal Structure**: `ideal_archi.md` (updated regularily)


### State Management
- **Riverpod**: Primary state management solution
- **Provider Pattern**: Service layer abstraction
- **Repository Pattern**: Data access layer with Firebase integration

### Flavors Configuration
- **Development**: Uses `hydracattest` Firebase project
  - App name: "Hydracat Dev"
  - Bundle ID (iOS): `com.example.hydracatTest`
  - Application ID (Android): `com.example.hydracat_test.dev`
  - Entry point: `lib/main_development.dart`
- **Production**: Uses `myckdapp` Firebase project
  - App name: "Hydracat"
  - Bundle ID (iOS): `com.example.hydracat`
  - Application ID (Android): `com.example.hydracat_test`
  - Entry point: `lib/main_production.dart`

### Firebase Integration
- **Development Project**: `hydracattest`
- **Production Project**: `myckdapp`
- **Services**: Auth, Firestore, Analytics, Crashlytics, Messaging, Storage
- **Configuration**: Environment-specific setup using `lib/firebase_options.dart` with `FlavorConfig`

## Code Standards

### Analysis Rules
- Uses `very_good_analysis` for strict linting
- Custom rules configured in `analysis_options.yaml`
- Run `flutter analyze` before committing

### Data Models
- **Standard Dart Classes**: Manual data classes with optional JSON serialization
- **Code Generation**: Run `dart run build_runner build` after model changes (when using json_serializable)

### Feature Structure
Each feature follows domain-driven design:
```
features/[feature]/
├── screens/               # UI screens
├── widgets/               # Feature-specific UI components
├── exceptions/            # Exceptions
├── models/
├── mixins/                # Reusable UI behavior (if needed)
└── services/              # Business logic
```

### Testing
- **Widget Tests**: Located in `test/`
- **Unit Tests**: Co-located with implementation
- **Integration Tests**: Uses `integration_test` package
- **Test Command**: `flutter test`

## Development Workflow

1. **Setup**: Run `flutter pub get` to install dependencies
2. **Development**: Use `flutter run` to start the app
3. **Code Generation**: Run `dart run build_runner build` after model changes (when needed)
4. **Testing**: Execute `flutter test` before commits
5. **Analysis**: Run `flutter analyze` to check for issues

## Important reference planning files

- **Initial project setup**: `~PLANNING/DONE/SETUP.md`
- **Authentication**: `~PLANNING/auth_implementation_plan.md`
- **Onboarding & Pet profile**: `~PLANNING/onboarding_profile_plan.md`
- **Logging**: `~PLANNING/logging_plan.md`

Once planning files are completed, they are moved from `~PLANNING` to `~PLANNING/DONE`

## Important Notes

- **Security**: API keys are stored in Firebase configuration files
- **Dual Environment**: App supports both development and production environments
- **Entry Points**: 
  - Development: `lib/main_development.dart`
  - Production: `lib/main_production.dart`
  - Default: `lib/main.dart` (defaults to development)
- **iOS Setup**: Requires manual Xcode configuration for build schemes (see iOS flavor setup instructions)
- **Flavor Selection**: Use `--flavor` and `-t` flags when running or building the app
- **Internationalization**: Use l10n `lib/l10n`

# important-instruction-reminders
- Do what has been asked; nothing more, nothing less.
- NEVER create files unless they're absolutely necessary for achieving your goal.
- ALWAYS prefer editing an existing file to creating a new one.
- NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.