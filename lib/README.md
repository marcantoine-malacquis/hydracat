# HydraCat - Clean Architecture

This project follows Clean Architecture principles to ensure maintainability, testability, and readability.

## Architecture Overview

```
lib/
├── core/               # Core functionality, constants, themes, utilities
│   ├── constants/      # App-wide constants (colors, strings, dimensions)
│   ├── theme/          # App theming and styling
│   └── utils/          # Utility functions and helpers
├── domain/             # Business logic layer (independent of UI/data)
│   ├── entities/       # Core business objects
│   └── usecases/      # Business logic use cases
├── data/               # Data layer (repositories, services, models)
│   ├── models/         # Data transfer objects (DTOs)
│   └── services/       # External data sources (API, database)
├── presentation/       # UI layer (screens, widgets, state management)
│   ├── screens/        # Full screen widgets
│   ├── widgets/        # Reusable UI components
│   └── state/          # State management (Bloc, Provider, Riverpod)
└── main.dart           # App entry point
```

## Layer Responsibilities

### Core Layer
- **Constants**: Centralized app configuration
- **Theme**: Consistent styling across the app
- **Utils**: Helper functions and extensions

### Domain Layer
- **Entities**: Pure business objects (no dependencies)
- **Use Cases**: Business logic orchestration

### Data Layer
- **Models**: Data structures for API/database
- **Services**: External data access

### Presentation Layer
- **Screens**: Full page widgets
- **Widgets**: Reusable components
- **State**: UI state management

## Best Practices

1. **Dependencies flow inward**: Domain → Data → Presentation
2. **Use constants**: Never hardcode strings, colors, or dimensions
3. **Separate concerns**: Keep business logic separate from UI
4. **Testable**: Each layer should be independently testable
5. **Consistent naming**: Follow established naming conventions

## Adding New Features

1. **Domain**: Define entities and use cases
2. **Data**: Create models and services
3. **Presentation**: Build UI components
4. **Core**: Add constants/themes as needed

## Example Usage

```dart
// ✅ Good: Using constants
AppBar(title: Text(AppStrings.homeTitle))

// ❌ Bad: Hardcoded values
AppBar(title: Text('Home'))

// ✅ Good: Using theme colors
color: AppColors.primaryBackground

// ❌ Bad: Hardcoded colors
color: Colors.blue
```
