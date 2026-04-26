# Quick Start Guide - Authentication System

## 🎯 What Was Created

Your app now has a complete authentication system with:
- ✅ Login screen
- ✅ Sign up screen  
- ✅ User profile screen
- ✅ Firebase authentication
- ✅ Firestore database integration

---

## ⚡ Quick Setup (5 Steps)

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"**
3. Name it: `student-stress-app`
4. Accept terms → Click **"Create project"**

### Step 2: Enable Authentication
1. In Firebase Console → **Authentication**
2. Click **"Get started"**
3. Click **Email/Password** method
4. Toggle it **ON**
5. Click **Save**

### Step 3: Create Firestore Database
1. In Firebase Console → **Firestore Database**
2. Click **"Create database"**
3. Choose location
4. Select **"Start in test mode"**
5. Click **"Enable"**

### Step 4: Add Firebase to Your App

#### For Android:
1. In Firebase Console → **Project Settings** ⚙️
2. Click **"Add App"** → **Android**
3. Enter package name from `android/app/build.gradle`
4. Download `google-services.json`
5. Place in: `android/app/google-services.json`

#### For iOS:
1. In Firebase Console → **Project Settings** ⚙️
2. Click **"Add App"** → **iOS**
3. Enter Bundle ID (usually `com.example.student_stress_app`)
4. Download `GoogleService-Info.plist`
5. Add to Xcode under `ios/Runner`

### Step 5: Update Firebase Config

Run this command in your project:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This auto-generates `firebase_options.dart` with your credentials.

**If that doesn't work**, manually edit `lib/firebase_options.dart` and add your Firebase credentials.

---

## 🚀 Test the App

```bash
flutter clean
flutter pub get
flutter run
```

### Test Sign Up:
1. App opens to **Login screen**
2. Click **"Sign Up"** link
3. Enter Name, Email, Password
4. Check **"I agree to Terms"**
5. Click **"Create Account"**
6. Should see **Home screen** ✅

### Test Sign In:
1. Click **Profile icon** (👤) on home screen
2. Click **"Sign Out"**
3. App goes back to **Login screen**
4. Click **"Sign In"** link
5. Enter email and password you just created
6. Should see **Home screen** ✅

### Test Profile Edit:
1. Click **Profile icon** on home screen
2. Click **Edit** button
3. Update any field
4. Click **"Save Changes"**
5. Should see update confirmation ✅

---

## 📱 New Screens in Your App

### 1. Login Screen (New!)
- Path: `lib/screens/login_screen.dart`
- Features: Email, password input, validation, forgot password link

### 2. Sign Up Screen (New!)
- Path: `lib/screens/signup_screen.dart`
- Features: Full name, email, password, confirmation, terms checkbox

### 3. User Profile Screen (New!)
- Path: `lib/screens/user_profile_screen.dart`
- Features: View/edit profile, sign out, delete account

### 4. Auth Wrapper (New!)
- Path: `lib/screens/auth_wrapper.dart`
- Features: Automatically routes to login or home based on auth state

---

## 🔑 Key Files

| File | Purpose |
|------|---------|
| `lib/services/firebase_auth_service.dart` | Handles Firebase operations |
| `lib/providers/auth_provider.dart` | Manages auth state with Provider |
| `lib/models/user_model.dart` | User data structure |
| `lib/firebase_options.dart` | Firebase configuration (TO BE FILLED) |
| `main.dart` | Updated with Firebase initialization |

---

## 🗂️ Database Structure

When a user signs up, this data is saved to Firestore:

```
users/
  {user_id}/
    - email: "student@university.edu"
    - fullName: "John Doe"
    - department: "Computer Science" (optional)
    - year: "3rd Year" (optional)
    - bio: "My bio here" (optional)
    - createdAt: timestamp
```

---

## ❌ Error Messages (User-Friendly)

The app shows clear error messages:
- "Email already in use" - Try a different email
- "User not found" - Check your email is correct
- "Incorrect password" - Check password is correct
- "Password is too weak" - Use at least 6 characters
- "Invalid email address" - Check email format

---

## 🔒 Security

- ✅ Passwords stored securely by Firebase
- ✅ Firestore rules restrict data access
- ✅ Users can only see their own profile
- ✅ Error messages don't expose sensitive info

---

## 📚 Full Documentation

For detailed setup instructions, see: **FIREBASE_SETUP_GUIDE.md**
For complete feature list, see: **AUTHENTICATION_SUMMARY.md**

---

## ⚠️ Common Issues

### "Command 'flutterfire' not found"
```bash
dart pub global activate flutterfire_cli
```

### Firebase credentials not working
1. Download files again from Firebase Console
2. Make sure `google-services.json` is in `android/app/`
3. Make sure `GoogleService-Info.plist` is in `ios/Runner/`

### App shows blank screen after login
- Most likely firebase_options.dart is missing credentials
- Run `flutterfire configure` to auto-generate it

### Can't see users in Firestore
- Go to Firestore Console → Collections
- Look for "users" collection
- Should appear after first sign up

---

## 🎨 UI Customization

Want to change colors? Edit:
```dart
lib/theme/app_colors.dart
```

Key colors you can customize:
- `accentBlue` - Primary button color
- `accentGreen` - Secondary button color
- `lightTextPrimary` - Text in light mode
- `darkTextPrimary` - Text in dark mode

---

## ✨ What's Next?

Optional features you can add:
- [ ] Password reset email
- [ ] Email verification
- [ ] Profile photo upload
- [ ] Google login
- [ ] Two-factor authentication

---

## 🆘 Need Help?

1. Check **FIREBASE_SETUP_GUIDE.md** for detailed setup
2. Check **AUTHENTICATION_SUMMARY.md** for feature details
3. Review error messages in the app
4. Check Firebase Console logs

---

## 📊 Testing Checklist

- [ ] App launches to login screen (no user logged in)
- [ ] Can create new account with Sign Up
- [ ] Can see account created in Firebase Authentication
- [ ] Can see user data in Firestore users collection
- [ ] After sign up, app shows home screen
- [ ] Can click profile icon and see User Profile screen
- [ ] Can edit profile and changes save
- [ ] Can sign out and app returns to login
- [ ] Can sign back in with saved credentials

---

**Status**: ✅ Ready to deploy and test!

Build and run on your Android 12 device:
```bash
flutter run
```

