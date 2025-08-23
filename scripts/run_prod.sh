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

# Check if device is connected
if ! flutter devices | grep -q "connected"; then
    echo "❌ No device connected. Please connect a device or start an emulator."
    exit 1
fi

# Run the app in production mode
# Note: --flavor only works on Android, iOS will ignore it
flutter run \
    --flavor prod \
    --dart-define=FLAVOR=prod \
    --target lib/main.dart

echo ""
echo "✅ Production environment launched successfully!"
