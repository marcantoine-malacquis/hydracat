#!/bin/bash

# iOS Configuration Setup Script
# This script copies the appropriate GoogleService-Info.plist file based on environment

ENVIRONMENT=${1:-dev}

echo "🔧 Setting up iOS configuration for environment: $ENVIRONMENT"

# Define source and destination paths
SOURCE_FILE=".firebase/$ENVIRONMENT/GoogleService-Info.plist"
DEST_FILE="ios/Runner/GoogleService-Info.plist"

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "❌ Error: $SOURCE_FILE not found!"
    echo "Please run 'flutterfire configure --project=<project_id>' in .firebase/$ENVIRONMENT/ first."
    exit 1
fi

# Copy the configuration file
cp "$SOURCE_FILE" "$DEST_FILE"
echo "✅ Copied $SOURCE_FILE to $DEST_FILE"

# Update Info.plist with environment-specific app name
if [ "$ENVIRONMENT" = "prod" ]; then
    # Update app name for production
    sed -i '' 's/<string>Hydracat<\/string>/<string>HydraCat<\/string>/g' ios/Runner/Info.plist
    echo "✅ Updated app name to 'HydraCat' for production"
else
    # Update app name for development
    sed -i '' 's/<string>Hydracat<\/string>/<string>HydraCat Dev<\/string>/g' ios/Runner/Info.plist
    echo "✅ Updated app name to 'HydraCat Dev' for development"
fi

echo "🎉 iOS configuration setup complete for $ENVIRONMENT environment!"
