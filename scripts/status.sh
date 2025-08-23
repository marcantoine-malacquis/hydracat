#!/bin/bash

# Environment Setup Status Script
# This script shows the current status of the environment setup

echo "🔍 HydraCat Environment Setup Status"
echo "====================================="
echo ""

# Check environment directories
echo "📁 Environment Directory Structure:"
if [ -d ".firebase/dev" ] && [ -d ".firebase/prod" ] && [ -d ".firebase/shared" ]; then
    echo "✅ .firebase/dev/ - Development environment"
    echo "✅ .firebase/prod/ - Production environment"
    echo "✅ .firebase/shared/ - Shared configurations"
else
    echo "❌ Environment directories missing"
fi
echo ""

# Check Firebase configuration files
echo "🔥 Firebase Configuration Files:"
if [ -f ".firebase/dev/google-services.json" ]; then
    echo "✅ Development Android config (google-services.json)"
else
    echo "❌ Development Android config missing"
fi

if [ -f ".firebase/dev/GoogleService-Info.plist" ]; then
    echo "✅ Development iOS config (GoogleService-Info.plist)"
else
    echo "❌ Development iOS config missing"
fi

if [ -f ".firebase/prod/google-services.json" ]; then
    echo "✅ Production Android config (google-services.json)"
else
    echo "❌ Production Android config missing"
fi

if [ -f ".firebase/prod/GoogleService-Info.plist" ]; then
    echo "✅ Production iOS config (GoogleService-Info.plist)"
else
    echo "❌ Production iOS config missing"
fi
echo ""

# Check shared configuration files
echo "🔗 Shared Configuration Files:"
if [ -f ".firebase/shared/firestore.rules" ]; then
    echo "✅ Firestore rules"
else
    echo "❌ Firestore rules missing"
fi

if [ -f ".firebase/shared/firestore.indexes.json" ]; then
    echo "✅ Firestore indexes"
else
    echo "❌ Firestore indexes missing"
fi

if [ -f ".firebase/shared/storage.rules" ]; then
    echo "✅ Storage rules"
else
    echo "❌ Storage rules missing"
fi
echo ""

# Check Flutter configuration
echo "📱 Flutter Configuration:"
if [ -f "lib/core/config/app_config.dart" ]; then
    echo "✅ Environment detection (AppConfig)"
else
    echo "❌ Environment detection missing"
fi

if [ -f "lib/core/config/firebase_options.dart" ]; then
    echo "✅ Firebase options factory"
else
    echo "❌ Firebase options factory missing"
fi

if [ -f "lib/core/config/firebase_options_dev.dart" ]; then
    echo "✅ Development Firebase options"
else
    echo "❌ Development Firebase options missing"
fi

if [ -f "lib/core/config/firebase_options_prod.dart" ]; then
    echo "✅ Production Firebase options"
else
    echo "❌ Production Firebase options missing"
fi
echo ""

# Check Android configuration
echo "🤖 Android Configuration:"
if grep -q "productFlavors" "android/app/build.gradle.kts"; then
    echo "✅ Flavor support configured"
else
    echo "❌ Flavor support not configured"
fi
echo ""

# Check scripts
echo "📜 Scripts:"
if [ -f "scripts/run_dev.sh" ] && [ -f "scripts/run_prod.sh" ]; then
    echo "✅ Run scripts"
else
    echo "❌ Run scripts missing"
fi

if [ -f "scripts/build_dev.sh" ] && [ -f "scripts/build_prod.sh" ]; then
    echo "✅ Build scripts"
else
    echo "❌ Build scripts missing"
fi

if [ -f "scripts/deploy_dev.sh" ] && [ -f "scripts/deploy_prod.sh" ]; then
    echo "✅ Deploy scripts"
else
    echo "❌ Deploy scripts missing"
fi

if [ -f "scripts/setup_firebase_configs.sh" ]; then
    echo "✅ Firebase config setup script"
else
    echo "❌ Firebase config setup script missing"
fi

if [ -f "scripts/setup_ios_config.sh" ]; then
    echo "✅ iOS config setup script"
else
    echo "❌ iOS config setup script missing"
fi
echo ""

# Summary
echo "📊 Summary:"
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Count total checks and passed checks
for file in .firebase/dev .firebase/prod .firebase/shared; do
    if [ -d "$file" ]; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
done

# Add other checks
TOTAL_CHECKS=$((TOTAL_CHECKS + 20)) # Approximate number of other checks

echo "Progress: $PASSED_CHECKS / $TOTAL_CHECKS checks passed"
echo ""

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo "🎉 All checks passed! Your environment setup is complete."
    echo "You can now run: ./scripts/run_dev.sh or ./scripts/run_prod.sh"
else
    echo "⚠️  Some checks failed. Please review the issues above."
    echo ""
    echo "🔧 To complete the setup, run:"
    echo "   ./scripts/setup_firebase_configs.sh"
    echo ""
    echo "📚 For detailed instructions, see: ENVIRONMENT_SETUP.md"
fi
