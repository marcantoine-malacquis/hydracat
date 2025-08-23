#!/bin/bash

# Production Environment Firebase Deployment Script
# This script deploys Firebase services to the production project

echo "🚀 Deploying to PRODUCTION Firebase project..."
echo "📱 Project: myckdapp"
echo "🔧 Environment: Production"
echo ""

# Confirm production deployment
read -p "⚠️  Are you sure you want to deploy to PRODUCTION? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Production deployment cancelled."
    exit 1
fi

# Change to the production Firebase directory
cd .firebase/prod

# Deploy Firebase services
echo "📤 Deploying Firestore rules..."
firebase deploy --only firestore

echo "📤 Deploying Storage rules..."
firebase deploy --only storage

echo "📤 Deploying Functions..."
firebase deploy --only functions

echo "📤 Deploying Hosting..."
firebase deploy --only hosting

echo ""
echo "✅ Production deployment completed successfully!"
echo "🌐 Hosting URL: https://myckdapp.web.app"
echo "📊 Firestore: https://console.firebase.google.com/project/myckdapp/firestore"
