# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Core Flutter Commands
- **Run App**: `flutter run`
- **Run Tests**: `flutter test`
- **Code Analysis**: `flutter analyze`
- **Generate Code**: `flutter packages pub run build_runner build`
- **Clean Build**: `flutter clean && flutter pub get`

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

### State Management
- **Riverpod**: Primary state management solution
- **Provider Pattern**: Service layer abstraction
- **Repository Pattern**: Data access layer with Firebase integration

### Firebase Integration
- **Project**: `hydracattest`
- **Services**: Auth, Firestore, Analytics, Crashlytics, Messaging, Storage
- **Configuration**: Single environment setup using `lib/firebase_options.dart`

## Code Standards

### Analysis Rules
- Uses `very_good_analysis` for strict linting
- Custom rules configured in `analysis_options.yaml`
- Run `flutter analyze` before committing

### Data Models
- **Freezed**: Immutable data classes with JSON serialization
- **Code Generation**: Run `flutter packages pub run build_runner build` after model changes

### Feature Structure
Each feature follows domain-driven design:
```
features/[feature]/
├── screens/               # UI screens
├── widgets/               # Feature-specific UI components
├── models/                # Data models
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
3. **Code Generation**: Run build_runner after model changes
4. **Testing**: Execute `flutter test` before commits
5. **Analysis**: Run `flutter analyze` to check for issues

## Important Notes

- **Security**: Firebase config files are committed for development project
- **Single Environment**: App uses `hydracattest` Firebase project
- **Entry Point**: Main app starts from `lib/main.dart`

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.