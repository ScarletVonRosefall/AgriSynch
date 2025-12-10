# Firebase Setup for AgriSynch

## Prerequisites
1. Node.js (LTS version from https://nodejs.org/)
2. Flutter SDK
3. Firebase Account

## Step 1: Install Firebase CLI
After installing Node.js, run:
```bash
npm install -g firebase-tools
```

## Step 2: Login to Firebase
```bash
firebase login
```

## Step 3: Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click "Create a project"
3. Name it "agrisynch" or your preferred name
4. Enable Google Analytics (optional)

## Step 4: Configure Flutter for Firebase

### Install FlutterFire CLI (already done)
```bash
dart pub global activate flutterfire_cli
```

### Configure Firebase for your Flutter app
```bash
flutterfire configure
```

This will:
- Detect your Flutter app
- Connect to your Firebase project
- Generate `firebase_options.dart` with real configuration
- Configure platforms (Web, Android, iOS, etc.)

## Step 5: Enable Firebase Services

### In Firebase Console:
1. **Authentication**:
   - Go to Authentication > Sign-in method
   - Enable Email/Password
   - Configure authorized domains

2. **Firestore Database**:
   - Go to Firestore Database
   - Create database (start in test mode for development)
   - Set up security rules later

3. **Storage**:
   - Go to Storage
   - Get started
   - Configure for profile images

### Security Rules (Firestore)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Security Rules (Storage)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to upload profile images
    match /profile_images/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 6: Update Web Configuration
After running `flutterfire configure`, replace the placeholder values in `lib/firebase_options.dart` with the generated configuration.

## Step 7: Test the Setup
```bash
flutter pub get
flutter run -d chrome
```

## Troubleshooting

### Common Issues:
1. **Firebase CLI not found**: Make sure Node.js is installed and Firebase CLI is in PATH
2. **Permission denied**: Run `firebase login` and ensure you have access to the project
3. **Web build issues**: Ensure Firebase SDK is properly configured for web

### Useful Commands:
```bash
# Check Firebase CLI version
firebase --version

# List Firebase projects
firebase projects:list

# Check FlutterFire CLI version
dart pub global run flutterfire_cli:flutterfire --version

# Clean and rebuild
flutter clean && flutter pub get
```

## Next Steps After Setup:
1. Configure authentication UI
2. Set up Firestore collections
3. Implement real-time data sync
4. Deploy to Firebase Hosting