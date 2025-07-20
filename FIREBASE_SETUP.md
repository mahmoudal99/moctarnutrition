# Firebase Setup Guide for Champions Gym App

This guide will help you set up Firebase for the Champions Gym app authentication system.

## Prerequisites

1. A Firebase project (you mentioned you already have one)
2. Flutter development environment
3. Android Studio / Xcode for platform-specific setup

## Step 1: Firebase Project Configuration

### 1.1 Enable Authentication Methods

1. Go to your Firebase Console: https://console.firebase.google.com/
2. Select your project
3. Navigate to **Authentication** > **Sign-in method**
4. Enable the following providers:
   - **Email/Password**
   - **Google** (for Google Sign-In)
   - **Apple** (for Apple Sign-In, iOS only)
   - **Anonymous** (for guest mode)

### 1.2 Configure Google Sign-In

1. In the **Google** provider settings:
   - Enable Google Sign-In
   - Add your app's SHA-1 fingerprint (see platform-specific setup below)

### 1.3 Configure Apple Sign-In (iOS only)

1. In the **Apple** provider settings:
   - Enable Apple Sign-In
   - Add your Apple Developer Team ID
   - Configure the Service ID

### 1.4 Set up Firestore Database

1. Navigate to **Firestore Database**
2. Create a database in **test mode** (for development)
3. Set up security rules (see below)

## Step 2: Platform-Specific Configuration

### 2.1 Android Setup

#### Get SHA-1 Fingerprint

Run this command in your project directory:
```bash
cd android
./gradlew signingReport
```

Look for the SHA-1 fingerprint in the output and add it to your Firebase project.

#### Add google-services.json

1. In Firebase Console, go to **Project Settings** > **Your apps**
2. Add an Android app if not already added
3. Download the `google-services.json` file
4. Place it in `android/app/google-services.json`

#### Update android/app/build.gradle

Make sure your `android/app/build.gradle` includes:
```gradle
apply plugin: 'com.google.gms.google-services'
```

#### Update android/build.gradle

Make sure your `android/build.gradle` includes:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

### 2.2 iOS Setup

#### Add GoogleService-Info.plist

1. In Firebase Console, go to **Project Settings** > **Your apps**
2. Add an iOS app if not already added
3. Download the `GoogleService-Info.plist` file
4. Place it in `ios/Runner/GoogleService-Info.plist`

#### Update iOS Bundle ID

Make sure your iOS bundle ID matches the one in Firebase:
- Open `ios/Runner.xcodeproj` in Xcode
- Check the Bundle Identifier in project settings
- Update it to match your Firebase configuration

#### Configure Apple Sign-In

1. In Xcode, go to **Signing & Capabilities**
2. Add **Sign in with Apple** capability
3. Configure your Apple Developer account settings

### 2.3 Web Setup (if needed)

1. In Firebase Console, add a web app
2. Copy the Firebase config object
3. Create `web/firebase-config.js` with the config

## Step 3: Firestore Security Rules

Create the following security rules in your Firestore Database:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public read access for some collections (optional)
    match /public/{document=**} {
      allow read: if true;
    }
    
    // Admin access (optional)
    match /admin/{document=**} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Step 4: Environment Variables

Create a `.env` file in your project root (if not already exists):

```env
# Firebase Configuration (optional - most config is in platform files)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key

# Other existing variables...
OPENAI_API_KEY=your_openai_api_key_here
```

## Step 5: Testing the Setup

### 5.1 Test Authentication Methods

1. Run the app: `flutter run`
2. Test each authentication method:
   - Email/Password sign up and sign in
   - Google Sign-In
   - Apple Sign-In (iOS only)
   - Guest mode
   - Password reset

### 5.2 Test Firestore Integration

1. Sign up a new user
2. Check that a user document is created in Firestore
3. Verify the user data is properly stored

### 5.3 Test User Profile Updates

1. Update user profile information
2. Verify changes are saved to Firestore
3. Test sign out and sign back in

## Step 6: Production Considerations

### 6.1 Security Rules

Update Firestore security rules for production:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // More restrictive rules for production
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 6.2 Authentication Settings

1. Configure authorized domains in Firebase Console
2. Set up email templates for password reset
3. Configure OAuth consent screen for Google Sign-In

### 6.3 Error Handling

The app includes comprehensive error handling for:
- Network errors
- Invalid credentials
- User not found
- Email already in use
- Weak passwords
- Too many requests

## Troubleshooting

### Common Issues

1. **SHA-1 fingerprint mismatch**: Regenerate and update in Firebase Console
2. **Bundle ID mismatch**: Check iOS/Android bundle identifiers
3. **Google Sign-In not working**: Verify OAuth configuration
4. **Apple Sign-In issues**: Check Apple Developer account settings

### Debug Mode

Enable debug logging by checking the console output for:
- Firebase initialization messages
- Authentication state changes
- Firestore operation logs

## Support

If you encounter issues:
1. Check Firebase Console for error logs
2. Verify all configuration files are in place
3. Test with a clean build: `flutter clean && flutter pub get`
4. Check platform-specific logs in Android Studio/Xcode

## Next Steps

After completing this setup:
1. Test all authentication flows
2. Customize the UI to match your brand
3. Add additional user profile fields as needed
4. Implement role-based access control
5. Set up analytics and crash reporting 