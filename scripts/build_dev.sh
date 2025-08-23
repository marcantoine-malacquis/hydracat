#!/bin/bash

# Development Environment Build Script
# This script builds the app for development with the correct Firebase project

echo "🔨 Building HydraCat for DEVELOPMENT..."
echo "📱 Firebase Project: hydracatTest"
echo "🔧 Environment: Development"
echo ""

# Setup Android Google Services configuration for development
echo "🔧 Setting up Android Google Services..."
cp .firebase/dev/google-services.json android/app/

# Build for Android
echo "📱 Building Android APK..."
flutter build apk \
    --flavor dev \
    --dart-define=FLAVOR=dev \
    --dart-define=ENV=dev \
    --release

# Build for iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building iOS..."
    flutter build ios \
        --flavor dev \
        --dart-define=FLAVOR=dev \
        --dart-define=ENV=dev \
        --release
else
    echo "⚠️  iOS build skipped (not on macOS)"
fi

echo ""
echo "✅ Development build completed successfully!"
echo "📱 Android APK: build/app/outputs/flutter-apk/app-dev-release.apk"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 iOS: build/ios/iphoneos/Runner.app"
fi
