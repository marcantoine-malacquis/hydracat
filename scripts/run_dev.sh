#!/bin/bash

# Development Environment Launch Script
# This script runs the app in development mode with the correct Firebase project

echo "🚀 Launching HydraCat in DEVELOPMENT mode..."
echo "📱 Firebase Project: hydracatTest"
echo "🔧 Environment: Development"
echo ""

# Setup iOS configuration for development
echo "🔧 Setting up iOS configuration..."
./scripts/setup_ios_config.sh dev

# Check if device is connected
if ! flutter devices | grep -q "connected"; then
    echo "❌ No device connected. Please connect a device or start an emulator."
    exit 1
fi

# Run the app in development mode
# Note: --flavor only works on Android, iOS will ignore it
flutter run \
    --flavor dev \
    --dart-define=FLAVOR=dev \
    --target lib/main.dart

echo ""
echo "✅ Development environment launched successfully!"
