# HydraCat Setup Guide

## Phase 1: Project Foundation & Configuration

### ✅ Completed
- [x] Flutter project structure with proper directory organization
- [x] All required dependencies in `pubspec.yaml`
- [x] Basic project structure following recommended architecture
- [x] Firebase service implementation (ready for configuration)
- [x] App structure with Riverpod provider scope
- [x] GoRouter configuration with placeholder screens
- [x] Core constants, exceptions, and utilities
- [x] Updated main.dart to use new app structure
- [x] Fixed Android Gradle configuration
- [x] Updated iOS deployment target to 15.0
- [x] **Verified: Both Android and iOS builds are working!**
- [x] **Dual environment setup with development and production flavors**
- [x] **Firebase configuration files in place for both environments**
- [x] **iOS flavor configuration complete with working schemes**
- [x] **Android flavor configuration complete with build variants**
- [x] **Environment-specific app names and bundle identifiers**

### 🔄 Next Steps

#### 1. Development Environment Setup
**✅ COMPLETE** - Firebase configuration is already set up for both environments:

**Development Environment (hydracattest project):**
- Firebase config files: `android/app/src/development/google-services.json` and `ios/Runner/GoogleService-Info-Development.plist`
- App name: "Hydracat Dev"
- Bundle ID (iOS): `com.example.hydracatTest`
- Application ID (Android): `com.example.hydracat_test.dev`
- Run command: `flutter run --flavor development -t lib/main_development.dart`

**Production Environment (myckdapp project):**
- Firebase config files: `android/app/src/production/google-services.json` and `ios/Runner/GoogleService-Info-Production.plist`
- App name: "Hydracat"
- Bundle ID (iOS): `com.example.hydracat`
- Application ID (Android): `com.example.hydracat_test`
- Run command: `flutter run --flavor production -t lib/main_production.dart`

#### 2. Running the App
**Choose your environment:**

**For Development:**
```bash
flutter run --flavor development -t lib/main_development.dart
```

**For Production:**
```bash
flutter run --flavor production -t lib/main_production.dart
```

**Default (Development):**
```bash
flutter run
```

### 📁 Project Structure Created
```
lib/
├── main.dart                 # Default entry point (development)
├── main_development.dart     # Development environment entry point
├── main_production.dart      # Production environment entry point
├── app/
│   ├── app.dart             # Main app widget with Firebase integration
│   ├── app_shell.dart       # App shell structure
│   └── router.dart          # GoRouter configuration
├── core/
│   ├── config/
│   │   └── flavor_config.dart # Environment configuration
│   ├── constants/
│   │   ├── app_colors.dart  # App color scheme
│   │   ├── app_strings.dart # App text constants
│   │   ├── app_icons.dart   # App icon constants
│   │   ├── app_accessibility.dart # Accessibility constants
│   │   └── constants.dart   # General constants
│   ├── exceptions/
│   │   └── app_exception.dart # Custom exception classes
│   ├── extensions/
│   │   └── string_extensions.dart # String utility methods
│   ├── theme/
│   │   ├── app_theme.dart   # Complete theme configuration
│   │   ├── app_text_styles.dart # Text styling
│   │   ├── app_layout.dart  # Layout constants
│   │   ├── app_shadows.dart # Shadow definitions
│   │   ├── app_spacing.dart # Spacing constants
│   │   └── theme.dart       # Theme exports
│   └── utils/
│       └── date_utils.dart  # Date formatting utilities
├── features/
│   ├── auth/               # Authentication feature
│   ├── home/               # Home screen feature
│   ├── logging/            # Session logging feature
│   ├── onboarding/         # User onboarding feature
│   ├── profile/            # User/cat profiles feature
│   ├── progress/           # Progress tracking feature
│   ├── resources/          # Guides and tips feature
│   └── schedule/           # Schedule management feature
├── l10n/                   # Internationalization
├── providers/              # Riverpod state providers
├── shared/
│   ├── models/             # Shared data models
│   ├── services/
│   │   └── firebase_service.dart # Firebase service wrapper
│   └── widgets/
│       └── widgets.dart    # Shared UI components
└── firebase_options.dart   # Firebase configuration with flavor support
```

### 🚀 Current Status
- **✅ Basic app structure**: Working and building successfully
- **✅ Navigation**: GoRouter configured with placeholder screens
- **✅ State management**: Riverpod provider scope ready
- **✅ Core utilities**: Constants, exceptions, and utilities implemented
- **✅ Firebase**: Fully configured for both development and production
- **✅ Environment management**: Dual flavor setup working on iOS and Android
- **✅ Build system**: Both development and production builds tested and working
- **⏳ Authentication**: Placeholder screens ready for implementation
- **⏳ Core features**: Ready for feature implementation

### 🔧 Development Commands

**Run Development Environment:**
```bash
flutter run --flavor development -t lib/main_development.dart
```

**Run Production Environment:**
```bash
flutter run --flavor production -t lib/main_production.dart
```

**Build for Development:**
```bash
# Android
flutter build apk --flavor development -t lib/main_development.dart

# iOS
flutter build ios --flavor development -t lib/main_development.dart
```

**Build for Production:**
```bash
# Android
flutter build apk --flavor production -t lib/main_production.dart

# iOS
flutter build ios --flavor production -t lib/main_production.dart
```

**Other Commands:**
```bash
# Run tests
flutter test

# Code analysis
flutter analyze

# Generate code (for Freezed models)
flutter packages pub run build_runner build

# Clean build
flutter clean && flutter pub get
```

### 🔧 Troubleshooting
- **Flavor errors**: Ensure you're using the correct `--flavor` and `-t` flags
- **Firebase errors**: Config files are automatically selected based on flavor
- **Import errors**: Run `flutter pub get` to install dependencies
- **iOS deployment target**: Already updated to 15.0 for Firebase compatibility
- **Build errors**: Try `flutter clean` first, then rebuild

### 📱 Next Phase: Core Feature Implementation
Now that the foundation is complete, next steps:
1. Implement authentication system with Firebase Auth
2. Create data models with Freezed for type safety
3. Set up repository pattern for data management
4. Implement core features (logging, progress tracking, profiles)
5. Add comprehensive testing
6. Implement CI/CD pipeline

### 🔐 Environment Configuration
**Development Environment:**
- Firebase Project: `hydracattest`
- App Name: "Hydracat Dev"
- Bundle ID: `com.example.hydracatTest` (iOS) / `com.example.hydracat_test.dev` (Android)

**Production Environment:**
- Firebase Project: `myckdapp`
- App Name: "Hydracat"
- Bundle ID: `com.example.hydracat` (iOS) / `com.example.hydracat_test` (Android)

---

**Note**: Firebase credentials are environment-specific and automatically managed by the flavor system.

**Current Status**: ✅ **FULLY OPERATIONAL** - Both development and production environments are configured and tested! Ready for feature development.
