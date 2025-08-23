# Environment Configuration

This directory contains environment-specific configuration files for Firebase API keys and other sensitive data.

## Files

- `env.template` - Template showing required environment variables
- `env.dev` - Development environment configuration (contains actual API keys)
- `env.prod` - Production environment configuration (contains actual API keys)

## Setup Instructions

1. **Copy the template file:**
   ```bash
   cp config/env.template config/env.dev
   cp config/env.template config/env.prod
   ```

2. **Fill in your actual Firebase configuration values:**
   - Replace `your_android_api_key_here` with your actual Android API key
   - Replace `your_ios_api_key_here` with your actual iOS API key
   - And so on for all other variables

3. **Never commit the actual env files:**
   - The `config/env.*` files are already in `.gitignore`
   - Only commit `env.template` to version control

## Environment Variables

The following environment variables are required:

### Android Configuration
- `FIREBASE_API_KEY_ANDROID` - Firebase API key for Android
- `FIREBASE_APP_ID_ANDROID` - Firebase app ID for Android
- `FIREBASE_MESSAGING_SENDER_ID_ANDROID` - Firebase messaging sender ID for Android
- `FIREBASE_PROJECT_ID_ANDROID` - Firebase project ID for Android
- `FIREBASE_STORAGE_BUCKET_ANDROID` - Firebase storage bucket for Android

### iOS Configuration
- `FIREBASE_API_KEY_IOS` - Firebase API key for iOS
- `FIREBASE_APP_ID_IOS` - Firebase app ID for iOS
- `FIREBASE_MESSAGING_SENDER_ID_IOS` - Firebase messaging sender ID for iOS
- `FIREBASE_PROJECT_ID_IOS` - Firebase project ID for iOS
- `FIREBASE_STORAGE_BUCKET_IOS` - Firebase storage bucket for iOS
- `FIREBASE_IOS_BUNDLE_ID_IOS` - iOS bundle identifier

## Usage

The app automatically detects the environment based on the `ENV` build-time define:

- Development: `flutter run --dart-define=ENV=dev`
- Production: `flutter run --dart-define=ENV=prod`

The build scripts (`scripts/run_dev.sh` and `scripts/run_prod.sh`) automatically set this value.

## Google Services Configuration

The app also requires Google Services JSON files for Android:

- `.firebase/dev/google-services.json` - Development Firebase project configuration
- `.firebase/prod/google-services.json` - Production Firebase project configuration

These files are automatically copied to `android/app/` by the build scripts.

## Security Notes

- ✅ Environment files are excluded from version control
- ✅ API keys are no longer hardcoded in source code
- ✅ Different configurations for dev/prod environments
- ✅ Template file shows required variables without exposing secrets
- ✅ Google Services files are automatically managed by build scripts
