#!/bin/bash

# Script to copy the correct GoogleService-Info.plist based on configuration
# This script should be run as a Build Phase in Xcode

# Determine environment from the configuration
if [ "${CONFIGURATION}" == "Debug-development" ] || [ "${CONFIGURATION}" == "Release-development" ] || [ "${CONFIGURATION}" == "Profile-development" ]; then
    ENVIRONMENT="Development"
elif [ "${CONFIGURATION}" == "Debug-production" ] || [ "${CONFIGURATION}" == "Release-production" ] || [ "${CONFIGURATION}" == "Profile-production" ]; then
    ENVIRONMENT="Production"
else
    # Default to development for standard configurations
    ENVIRONMENT="Development"
fi

# Source and destination paths
SOURCE_FILE="${SRCROOT}/Runner/GoogleService-Info-${ENVIRONMENT}.plist"
DEST_FILE="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

# Copy the appropriate GoogleService-Info.plist
if [ -f "$SOURCE_FILE" ]; then
    echo "Copying GoogleService-Info.plist for ${ENVIRONMENT} environment"
    cp "$SOURCE_FILE" "$DEST_FILE"
else
    echo "ERROR: GoogleService-Info.plist file not found for ${ENVIRONMENT} environment at $SOURCE_FILE"
    exit 1
fi