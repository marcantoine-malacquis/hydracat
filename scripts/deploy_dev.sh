#!/bin/bash

# Development Environment Firebase Deployment Script
# This script deploys Firebase services to the development project

echo "🚀 Deploying to DEVELOPMENT Firebase project..."
echo "📱 Project: hydracatTest"
echo "🔧 Environment: Development"
echo ""

# Change to the development Firebase directory
cd .firebase/dev

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
echo "✅ Development deployment completed successfully!"
echo "🌐 Hosting URL: https://hydracattest.web.app"
echo "📊 Firestore: https://console.firebase.google.com/project/hydracattest/firestore"
