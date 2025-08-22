# HydraCat - Tech Stack Documentation

## Overview
HydraCat is built using Flutter with Firebase as the backend-as-a-service platform and Riverpod for state management. The app targets both iOS and Android platforms with a focus on offline-first functionality and medical precision.

## Core Framework
- **Flutter**: Latest stable version
- **Dart**: No specific version constraints (use Flutter's bundled Dart)
- **Target Platforms**: iOS (App Store) + Android (Play Store)

## State Management
- **Primary**: `flutter_riverpod` (manual providers, no code generation)
- **Architecture**: Repository pattern with Riverpod providers
- **Async State**: AsyncValue for handling loading/error states
- **Local State**: StateProvider for simple UI state

## Backend & Cloud Services
### Firebase Suite
- **Authentication**: Firebase Auth (email/password, anonymous upgrade)
- **Database**: Cloud Firestore (offline persistence enabled)
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Analytics**: Firebase Analytics (user engagement, feature usage)
- **Crash Reporting**: Firebase Crashlytics
- **Cloud Functions**: Firebase Cloud Functions (for backend logic, email notifications)
- **Storage**: Firebase Storage (conditional - only if cat profile photos are implemented)

**Note**: Firebase Storage decision pending - only needed for cat profile photos. Consider trade-off between feature value and implementation complexity.

## Navigation & Routing
- **Router**: `go_router`
- **Route Structure**: Declarative routing with type-safe navigation. GoRouter’s declarative routes allow easy testing and type-safe arguments.
- **Deep Linking**: Support for notification deep links
- **Guards**: Authentication-based route protection

## UI & Design
- **Design System**: Material Design 3 (Flutter built-in)
- **Theme**: Dynamic Material You theming where available
- **Responsive Design**: Adaptive layouts for different screen sizes
- **Accessibility**: Built-in Material 3 accessibility support

## Key Dependencies

### Core Functionality
```yaml
# State Management
flutter_riverpod:

# Navigation
go_router:

# Firebase Services
firebase_core: 
firebase_auth: 
cloud_firestore:
firebase_messaging:
firebase_analytics:
firebase_crashlytics:
firebase_functions:
# firebase_storage: ^11.2.0  # Conditional - only for cat photos

# Notifications
flutter_local_notifications:

# Image Handling
cached_network_image:

# PDF Generation
pdf:
printing:

# Device & Permissions
device_info_plus:
permission_handler:

# Animations
flutter_animate:
# lottie: ^2.6.0  # Future enhancement for celebration animations
```

### Development & Code Generation
```yaml
dev_dependencies:
  # Testing
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail:

  # Code Generation
  build_runner:
  freezed:
  json_serializable:
  json_annotation:

  # Linting
  very_good_analysis:

  # Build Tools
  flutter_launcher_icons:
  flutter_native_splash
```

## Architecture Patterns

### Data Layer
- **Repository Pattern**: Abstract data sources behind repository interfaces
- **Models**: Freezed data classes with JSON serialization
- **Error Handling**: Centralized error handling with custom exceptions

### Presentation Layer
- **MVVM Pattern**: Views consume ViewModels through Riverpod providers
- **Reactive UI**: AsyncValue for async state management
- **Form Handling**: Reactive forms with validation

### Service Layer
- **Firebase Service**: Centralized Firebase operations
- **Notification Service**: Combined local + FCM notification handling
- **PDF Service**: Report generation and sharing

## Project Structure
```
lib/
├── main.dart
├── app/
│   ├── app.dart              # Main app widget
│   └── router.dart           # Go_router configuration
├── core/
│   ├── constants/            # Colors, strings, dimensions
│   ├── extensions/           # Dart extensions
│   ├── utils/                # Helpers
│   └── exceptions/           # Custom exceptions
├── features/
│   ├── auth/                 # Login, signup, user auth
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── logging/              # Session logging
│   ├── progress/             # Analytics & trends
│   ├── profile/              # Pet & user profiles
│   └── resources/            # Guides & tips
├── shared/
│   ├── models/               # Used across features
│   ├── services/             # Firebase, API, storage
│   ├── repositories/         # Central data repositories
│   └── widgets/              # Truly reusable widgets
└── l10n/                     # For future localization

## Testing Strategy

### Unit Tests
- **Framework**: `flutter_test`
- **Mocking**: `mocktail` for Firebase services and repositories
- **Coverage**: Repository logic, business logic, utility functions
- **Location**: `test/unit/`

### Widget Tests
- **Framework**: `flutter_test` with testWidgets
- **Scope**: Individual widgets and their interactions
- **Mocking**: Mock providers with Riverpod testing utilities
- **Location**: `test/widget/`

### Integration Tests
- **Framework**: `integration_test`
- **Scope**: Critical user flows (login, session logging, streak tracking)
- **Environment**: Test Firebase project with seeded data
- **Location**: `integration_test/`

## Development Workflow

### Code Generation
```bash
# Run code generation for freezed and json_serializable
dart run build_runner build --delete-conflicting-outputs

# Watch for changes during development
dart run build_runner watch --delete-conflicting-outputs
```

### Testing Commands
```bash
# Run all unit and widget tests
flutter test

# Run integration tests
flutter test integration_test/

# Run specific test file
flutter test test/unit/repositories/fluid_repository_test.dart
```

### Firebase Configuration
- **Development**: Separate Firebase project for development/testing
- **Production**: Production Firebase project with security rules
- **Local**: Firebase emulators for offline development (optional)

## Performance Considerations

### Firebase Optimization
- **Firestore**: Efficient queries with proper indexing
- **Offline Persistence**: Enabled for critical data
- **Caching**: Leverage Firestore's built-in caching
- **Bundle Size**: Conditional Firebase Storage import

### Flutter Performance
- **Image Caching**: cached_network_image for profile photos
- **List Performance**: ListView.builder for large datasets
- **State Management**: Efficient provider dependencies
- **Build Optimization**: const constructors where possible

## Security & Privacy

### Firebase Security
- **Security Rules**: Firestore rules preventing cross-user access
- **Authentication**: Secure token handling
- **Analytics**: Privacy-compliant event tracking
- **Crashlytics**: No sensitive data in crash reports

### Data Protection
- **GDPR Compliance**: Minimal data collection
- **Local Storage**: Encrypted preferences for sensitive data
- **User Consent**: Opt-in analytics and crash reporting

## Payments & Monetisation
- **In-App Purchase**: use in_app_purchase (official Flutter plugin for iOS/Android billing) for the subscription

## Deployment

### Build Configuration
- **iOS**: Xcode project configuration for App Store
- **Android**: Gradle configuration for Play Store
- **Signing**: Separate debug/release signing configurations
- **Obfuscation**: Enable code obfuscation for release builds

### CI/CD Considerations
- **Testing**: Automated test runs on PR/merge
- **Code Quality**: Linting with very_good_analysis
- **Firebase**: Environment-specific configuration
- **Deployment**: Automated builds for staging/production

## Development Environment

### IDE Setup
- **Primary IDE**: Cursor AI
- **Extensions**: Error Lens for inline error display, Flutter Widget Snippets to boost speed with boilerplate widgets.
- **Formatting**: Dart formatter with very_good_analysis rules
- **Debugging**: Flutter inspector and Firebase debugging tools

### Required Tools
- **Flutter SDK**: Latest stable channel
- **Firebase CLI**: For project management and Cloud Functions
- **Xcode**: For iOS development and deployment
- **Android Studio**: For Android SDK and emulators

## Future Considerations

### Planned Additions
- **Lottie Animations**: For fancier, celebratory animations
- **Localization**: i18n support for multiple languages
- **Accessibility**: Enhanced screen reader support
- **Performance**: Advanced caching strategies

### Potential Integrations
- **Firebase Storage**: Cat profile photo storage
- **Firebase Remote Config**: Feature flags and A/B testing
- **Firebase App Check**: Enhanced security for API calls
- **In-App Purchases**: Subscription management

---

*This tech stack documentation should be referenced for all architectural decisions and dependency choices. Keep it updated as the project evolves.*