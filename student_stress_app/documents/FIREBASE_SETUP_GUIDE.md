# Firebase Setup Guide for Student Stress App

## Overview
This guide will walk you through setting up Firebase Authentication and Firestore Database for your Student Stress App.

---

## Step 1: Create a Firebase Project

### 1.1 Go to Firebase Console
- Visit [Firebase Console](https://console.firebase.google.com/)
- Click **"Create a project"** (or select an existing project)
- Enter project name: `student-stress-app`
- Accept terms and click **"Create project"**
- Wait for project creation to complete

### 1.2 Enable Google Analytics (Optional)
- When prompted, you can enable or disable Google Analytics
- It's optional but useful for monitoring app usage

---

## Step 2: Set Up Firebase Authentication

### 2.1 Enable Email/Password Authentication
1. Go to **Authentication** panel (left sidebar)
2. Click **"Get started"**
3. Click **Sign-in method** tab
4. Click **Email/Password**
5. Enable **Email/Password** and **Email link (passwordless sign-in)**
6. Click **Save**

### 2.2 Configure Email Templates (Optional)
1. Stay in **Authentication** → **Templates** tab
2. Customize the email templates for password reset and verification
3. Update sender name and email if desired

---

## Step 3: Set Up Cloud Firestore Database

### 3.1 Create Database
1. Go to **Firestore Database** (left sidebar)
2. Click **"Create database"**
3. Choose location (closest to your users)
4. For development, select **"Start in test mode"** (for easier testing)
5. Click **"Enable"**

### 3.2 Configure Firestore Security Rules
1. Go to **Firestore Database** → **Rules** tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // Allow users to read/write their own documents
      allow read, write: if request.auth.uid == userId;
      
      // Allow public profile reads
      allow read: if true;
    }
    
    // Other collections
    match /{document=**} {
      // Deny all by default (secure by default)
      allow read, write: if false;
    }
  }
}
```

3. Click **"Publish"**

---

## Step 4: Configure Android

### 4.1 Register Android App with Firebase

1. In Firebase Console, click **Project Settings** (⚙️) at top
2. Click **"Add app"** → Select **Android**
3. Enter app details:
   - **Android package name**: `com.example.student_stress_app`
     - (You can find this in `android/app/build.gradle` under `applicationId`)
   - **App nickname**: `Student Stress App Android`
4. Click **"Register app"**
5. Download `google-services.json`
6. Place it in: `android/app/google-services.json`

### 4.2 Add Google Services Plugin to Android

1. Open `android/build.gradle` and add to **buildscript** section:
   ```gradle
   dependencies {
     classpath 'com.google.gms:google-services:4.3.15'
   }
   ```

2. Open `android/app/build.gradle` and add at the **bottom**:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

3. In the same file, find `compileSdkVersion` and ensure it's 31 or higher

### 4.3 Update Android Minimum SDK

In `android/app/build.gradle`:
- Find `minSdkVersion` and ensure it's **21 or higher**

---

## Step 5: Configure iOS

### 5.1 Register iOS App with Firebase

1. In Firebase Console, click **Project Settings** (⚙️)
2. Click **"Add app"** → Select **iOS**
3. Enter app details:
   - **iOS bundle ID**: `com.example.studentStressApp`
     - (Or your custom bundle ID from Xcode)
   - **App nickname**: `Student Stress App iOS`
   - **App Store ID**: (leave empty for now)
4. Click **"Register app"**
5. Download `GoogleService-Info.plist`
6. Open Xcode and add it to the `ios/Runner` directory

### 5.1 Update iOS Deployment Target

1. Open `ios/Podfile`
2. Find the line starting with `platform :ios`
3. Ensure it's **11.0 or higher**:
   ```ruby
   platform :ios, '11.0'
   ```

---

## Step 6: Update Flutter Firebase Options

### 6.1 Option 1: Use FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Run setup command (in your project directory)
flutterfire configure
```

This will automatically generate `lib/firebase_options.dart` with your Firebase credentials.

### 6.2 Option 2: Manual Configuration

If FlutterFire CLI doesn't work, manually update `lib/firebase_options.dart`:

1. In Firebase Console → **Project Settings** (⚙️)
2. Scroll to **"Your apps"** section
3. Find your Android and iOS app registrations
4. Copy the configuration values to `firebase_options.dart`

**For Android:**
- Find `apiKey`, `appId`, `messagingSenderId`, `projectId`, `storageBucket`

**For iOS:**
- Find same values plus `iosBundleId`

---

## Step 7: Test Firebase Connection

### 7.1 Run the app:

```bash
flutter clean
flutter pub get
flutter run
```

### 7.2 Test Sign Up:
1. Open the app
2. Go to Sign Up screen
3. Create an account with email and password
4. If successful, you'll be taken to the Home screen

### 7.3 Verify in Firebase Console:
1. Go to **Authentication** tab
2. You should see your new user in the **Users** list
3. Go to **Firestore Database** → **Collections**
4. You should see a `users` collection with your user's data

---

## Step 8: Create Firestore Collections (Manual Setup)

If needed, you can manually create collections in Firestore:

1. **Users Collection** (auto-created when users sign up):
   ```
   users/
     {uid}/
       uid: string
       email: string
       fullName: string
       profileImageUrl: string (optional)
       createdAt: timestamp
       department: string (optional)
       year: string (optional)
       bio: string (optional)
   ```

---

## Troubleshooting

### Error: "Firebase app not initialized"
- Make sure `Firebase.initializeApp()` is called in `main.dart` before `runApp()`
- Verify `google-services.json` is in `android/app/`
- Verify `GoogleService-Info.plist` is in `ios/Runner/`

### Error: "User not found" or "Wrong password"
- These are expected Firebase Auth errors
- AuthProvider converts them to user-friendly messages

### Error: "Permission denied" when writing to Firestore
- Check your Firestore security rules
- Ensure `allow write:` rule includes authenticated users
- Verify the user is authenticated before writing

### Error: "Invalid API key"
- Re-run `flutterfire configure`
- Or manually update `firebase_options.dart` with correct credentials

### Android Build Error
- Ensure `minSdkVersion` is **21 or higher**
- Ensure `compileSdkVersion` is **31 or higher**
- Run `flutter clean` and try again

### iOS Build Error
- Run `flutter clean`
- Delete `ios/Pods` folder
- Delete `ios/Podfile.lock`
- Run `flutter pub get` and `flutter run` again

---

## Security Best Practices

1. **Never commit credentials** to version control
2. **Use environment variables** for sensitive data
3. **Enable two-factor authentication** for Firebase Console
4. **Review Firestore rules** regularly
5. **Monitor Firebase usage** in console for suspicious activity
6. **Use strong passwords** (6+ characters, mix of letters & numbers)
7. **Implement rate limiting** for auth attempts (Firebase does this automatically)

---

## Database Schema

### Users Collection
```
users/
  {uid}/
    uid: string (Firebase Auth UID)
    email: string
    fullName: string
    profileImageUrl: string (optional, for future profile photos)
    createdAt: timestamp (account creation date)
    department: string (e.g., "Computer Science")
    year: string (e.g., "3rd Year")
    bio: string (user bio/about section)
```

### Example User Document
```json
{
  "uid": "abc123xyz",
  "email": "student@university.edu",
  "fullName": "John Doe",
  "profileImageUrl": null,
  "createdAt": "2026-04-06T10:30:00Z",
  "department": "Computer Science",
  "year": "3rd Year",
  "bio": "Studying Computer Science, interested in mobile development"
}
```

---

## Next Steps

- ✅ Set up Firebase Authentication
- ✅ Configure Firestore Database
- ✅ Update app with Firebase credentials
- ✅ Test sign up/sign in functionality
- 🔄 Add password reset functionality (see AuthProvider)
- 🔄 Add profile image upload (requires Storage)
- 🔄 Implement email verification (Firebase built-in)
- 🔄 Add social login (Google, Facebook) - optional

---

## Useful Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase Plugin](https://firebase.flutter.dev/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Firebase Authentication Best Practices](https://firebase.google.com/docs/auth/best-practices)

---

## Support

For issues or questions:
1. Check [Firebase Status Dashboard](https://status.firebase.google.com/)
2. Review [Flutter Firebase FAQ](https://firebase.flutter.dev/docs/faq)
3. Search [Stack Overflow](https://stackoverflow.com/questions/tagged/firebase+flutter)

