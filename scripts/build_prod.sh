#!/bin/bash

# Production Environment Build Script
# This script builds the app for production with the correct Firebase project

echo "🔨 Building HydraCat for PRODUCTION..."
echo "📱 Firebase Project: myckdapp"
echo "🔧 Environment: Production"
echo ""

# Setup Android Google Services configuration for production
echo "🔧 Setting up Android Google Services..."
cp .firebase/prod/google-services.json android/app/

# Build for Android
echo "📱 Building Android APK..."
flutter build apk \
    --flavor prod \
    --dart-define=FLAVOR=prod \
    --dart-define=ENV=prod \
    --release

# Build for iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building iOS..."
    flutter build ios \
        --flavor prod \
        --dart-define=FLAVOR=prod \
        --dart-define=ENV=prod \
        --release
else
    echo "⚠️  iOS build skipped (not on macOS)"
fi

echo ""
echo "✅ Production build completed successfully!"
echo "📱 Android APK: build/app/outputs/flutter-apk/app-prod-release.apk"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 iOS: build/ios/iphoneos/Runner.app"
fi
