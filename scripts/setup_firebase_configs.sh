#!/bin/bash

# Firebase Configuration Setup Script
# This script helps set up Firebase configuration files for both environments

echo "🔥 Setting up Firebase configurations for both environments..."
echo ""

# Check if flutterfire is installed
if ! command -v flutterfire &> /dev/null; then
    echo "❌ FlutterFire CLI is not installed."
    echo "Please install it with: dart pub global activate flutterfire_cli"
    exit 1
fi

echo "✅ FlutterFire CLI is installed"
echo ""

# Development environment setup
echo "🔧 Setting up DEVELOPMENT environment (hydracattest)..."
cd .firebase/dev

echo "📱 Generating Firebase config for development..."
flutterfire configure --project=hydracattest --out=.

if [ $? -eq 0 ]; then
    echo "✅ Development Firebase config generated successfully"
else
    echo "⚠️  Development Firebase config generation had issues, but continuing..."
fi

cd ../..

# Production environment setup
echo ""
echo "🔧 Setting up PRODUCTION environment (myckdapp)..."
cd .firebase/prod

echo "📱 Generating Firebase config for production..."
flutterfire configure --project=myckdapp --out=.

if [ $? -eq 0 ]; then
    echo "✅ Production Firebase config generated successfully"
else
    echo "⚠️  Production Firebase config generation had issues, but continuing..."
fi

cd ../..

echo ""
echo "🔍 Checking generated files..."

# Check development environment
if [ -f ".firebase/dev/google-services.json" ]; then
    echo "✅ Development Android config: .firebase/dev/google-services.json"
else
    echo "❌ Development Android config missing: .firebase/dev/google-services.json"
fi

if [ -f ".firebase/dev/GoogleService-Info.plist" ]; then
    echo "✅ Development iOS config: .firebase/dev/GoogleService-Info.plist"
else
    echo "❌ Development iOS config missing: .firebase/dev/GoogleService-Info.plist"
fi

# Check production environment
if [ -f ".firebase/prod/google-services.json" ]; then
    echo "✅ Production Android config: .firebase/prod/google-services.json"
else
    echo "❌ Production Android config missing: .firebase/prod/google-services.json"
fi

if [ -f ".firebase/prod/GoogleService-Info.plist" ]; then
    echo "✅ Production iOS config: .firebase/prod/GoogleService-Info.plist"
else
    echo "❌ Production iOS config missing: .firebase/prod/google-services.json"
fi

echo ""
echo "📋 Next steps:"
echo "1. If any config files are missing, manually download them from Firebase Console"
echo "2. Place them in the appropriate .firebase/<env>/ directories"
echo "3. Test both environments with: ./scripts/run_dev.sh and ./scripts/run_prod.sh"
echo ""
echo "🎉 Firebase configuration setup complete!"
