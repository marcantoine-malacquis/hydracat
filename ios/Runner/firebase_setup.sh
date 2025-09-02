#!/bin/bash

# Script to copy the correct GoogleService-Info.plist based on configuration
# This script should be run as a Build Phase in Xcode

echo "=== Firebase Setup Script Debug ==="
echo "CONFIGURATION: ${CONFIGURATION}"
echo "SRCROOT: ${SRCROOT}"
echo "BUILT_PRODUCTS_DIR: ${BUILT_PRODUCTS_DIR}"
echo "PRODUCT_NAME: ${PRODUCT_NAME}"

# Determine environment from the configuration
if [ "${CONFIGURATION}" == "Debug-development" ] || [ "${CONFIGURATION}" == "Release-development" ] || [ "${CONFIGURATION}" == "Profile-development" ]; then
    ENVIRONMENT="Development"
elif [ "${CONFIGURATION}" == "Debug-production" ] || [ "${CONFIGURATION}" == "Release-production" ] || [ "${CONFIGURATION}" == "Profile-production" ]; then
    ENVIRONMENT="Production"
else
    # Default to development for standard configurations
    ENVIRONMENT="Development"
fi

echo "Determined ENVIRONMENT: ${ENVIRONMENT}"

# Source and destination paths
SOURCE_FILE="${SRCROOT}/Runner/GoogleService-Info-${ENVIRONMENT}.plist"
# Copy to Runner directory so Resources build phase will include the correct one
DEST_FILE="${SRCROOT}/Runner/GoogleService-Info.plist"

echo "SOURCE_FILE: ${SOURCE_FILE}"
echo "DEST_FILE: ${DEST_FILE}"
echo "Source file exists: $([ -f "$SOURCE_FILE" ] && echo "YES" || echo "NO")"

# Copy the appropriate GoogleService-Info.plist
if [ -f "$SOURCE_FILE" ]; then
    echo "Copying GoogleService-Info.plist for ${ENVIRONMENT} environment to Runner directory"
    cp "$SOURCE_FILE" "$DEST_FILE"
    echo "Copy completed. Verifying destination file..."
    if [ -f "$DEST_FILE" ]; then
        echo "SUCCESS: Destination file exists in Runner directory"
        echo "Destination file bundle ID: $(grep -A1 BUNDLE_ID "$DEST_FILE" | tail -1 | sed 's/<[^>]*>//g' | xargs)"
    else
        echo "ERROR: Destination file was not created in Runner directory"
    fi
else
    echo "ERROR: GoogleService-Info.plist file not found for ${ENVIRONMENT} environment at $SOURCE_FILE"
    echo "Available files in source directory:"
    ls -la "${SRCROOT}/Runner/GoogleService-Info"*
    exit 1
fi