#!/bin/bash

# Production Environment Launch Script
# This script runs the app in production mode with the correct Firebase project

echo "🚀 Launching HydraCat in PRODUCTION mode..."
echo "📱 Firebase Project: myckdapp"
echo "🔧 Environment: Production"
echo ""

# Setup iOS configuration for production
echo "🔧 Setting up iOS configuration..."
./scripts/setup_ios_config.sh prod

# Setup Android Google Services configuration for production
echo "🔧 Setting up Android Google Services..."
cp .firebase/prod/google-services.json android/app/

# Source the production environment file
echo "🔧 Loading production environment configuration..."
if [ -f "config/env.prod" ]; then
    source config/env.prod
    echo "✅ Environment configuration loaded"
    
    # Export the variables so they're available to child processes
    export FIREBASE_API_KEY_IOS
    export FIREBASE_APP_ID_IOS
    export FIREBASE_MESSAGING_SENDER_ID_IOS
    export FIREBASE_PROJECT_ID_IOS
    export FIREBASE_STORAGE_BUCKET_IOS
    export FIREBASE_IOS_BUNDLE_ID_IOS
    export FIREBASE_API_KEY_ANDROID
    export FIREBASE_APP_ID_ANDROID
    export FIREBASE_MESSAGING_SENDER_ID_ANDROID
    export FIREBASE_PROJECT_ID_ANDROID
    export FIREBASE_STORAGE_BUCKET_ANDROID
    
    # Debug: show what we loaded
    echo "🔍 Loaded Firebase config:"
    echo "   API Key iOS: ${FIREBASE_API_KEY_IOS:0:10}..."
    echo "   Project ID: $FIREBASE_PROJECT_ID_IOS"
    
    # Test that variables are actually set
    if [ -z "$FIREBASE_API_KEY_IOS" ]; then
        echo "❌ Error: FIREBASE_API_KEY_IOS is empty or not set"
        exit 1
    fi
    
    echo "✅ All Firebase variables are properly loaded"
else
    echo "❌ Error: config/env.prod not found"
    exit 1
fi

# Check if device is connected
if ! flutter devices | grep -q "connected"; then
    echo "❌ No device connected. Please connect a device or start an emulator."
    exit 1
fi

# Run the app in production mode
# Note: --flavor only works on Android, iOS will ignore it
echo "🤖 Launching Android production build..."
flutter run \
    --flavor prod \
    --dart-define=FLAVOR=prod \
    --dart-define=ENV=prod \
    --target lib/main.dart

echo ""
echo "✅ Android production environment launched successfully!"

echo ""
echo "📱 Launching iOS production build..."
echo "🔍 Debug: Flutter command will include:"
echo "   FIREBASE_API_KEY_IOS: ${FIREBASE_API_KEY_IOS:0:10}..."
echo "   FIREBASE_PROJECT_ID_IOS: $FIREBASE_PROJECT_ID_IOS"

# Store the command in a variable to debug it
FLUTTER_CMD="flutter run \
    --dart-define=FLAVOR=prod \
    --dart-define=ENV=prod \
    --dart-define=FIREBASE_API_KEY_IOS=\"$FIREBASE_API_KEY_IOS\" \
    --dart-define=FIREBASE_APP_ID_IOS=\"$FIREBASE_APP_ID_IOS\" \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID_IOS=\"$FIREBASE_MESSAGING_SENDER_ID_IOS\" \
    --dart-define=FIREBASE_PROJECT_ID_IOS=\"$FIREBASE_PROJECT_ID_IOS\" \
    --dart-define=FIREBASE_STORAGE_BUCKET_IOS=\"$FIREBASE_STORAGE_BUCKET_IOS\" \
    --dart-define=FIREBASE_IOS_BUNDLE_ID_IOS=\"$FIREBASE_IOS_BUNDLE_ID_IOS\" \
    --target lib/main.dart"

echo "🔍 Debug: Full Flutter command:"
echo "$FLUTTER_CMD"

# Execute the command
eval "$FLUTTER_CMD"

echo ""
echo "✅ iOS production environment launched successfully!"
