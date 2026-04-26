# Firebase Database Setup Guide

## ✅ Step 1: Create Firestore Database

### 1.1 Create Database
- Go to **Firebase Console** → `student-stress-app` project
- Click **Firestore Database** (left menu)
- Click **Create Database**
- Select:
  - **Start in test mode** (for development)
  - **Location**: Choose closest region
- Click **Create**

### 1.2 Create `users` Collection
1. In Firestore, click **+ Start collection**
2. Collection ID: `users`
3. Click **Auto-ID** 
4. Click **Save**

---

## ✅ Step 2: Set Firestore Security Rules

### Important: Update Rules for Development
The default test mode has rules that expire in 30 days. Let's update them:

1. Go to **Firestore Database** → **Rules** tab
2. Replace all content with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Allow reads for all authenticated users (for finding other users)
    match /users/{userId} {
      allow read: if request.auth != null;
    }
  }
}
```

3. Click **Publish**

---

## ✅ Step 3: Configure Authentication

### 3.1 Enable Email/Password Auth
1. Go to **Authentication** (left menu)
2. Click **Sign-in method** tab
3. Find **Email/Password** and click the toggle to enable
4. Enable **Email/Password + password** option
5. Click **Save**

### 3.2 Disable reCAPTCHA (For Development)
1. In **Authentication** → **Sign-in method**
2. Scroll down to **reCAPTCHA Enterprise**
3. Click the toggle to disable (temporary for dev)
4. Click **Save**

---

## ✅ Step 4: Database Structure

### Collection: `users`

Each user document contains:

```
{
  "uid": "firebase-auth-id",
  "email": "user@example.com",
  "fullName": "John Doe",
  "createdAt": Timestamp(2026-04-07),
  "department": "Engineering",  // optional
  "year": "2nd Year",           // optional
  "bio": "Student bio",         // optional
  "profileImageUrl":            // optional
}
```

---

## ✅ Step 5: Test the Setup

### Test Sign Up
1. Open the app on your phone
2. Go to **Sign Up**
3. Enter:
   - Email: `test@gmail.com`
   - Full Name: `Test User`
   - Password: `Test@123`
   - Confirm: `Test@123`
4. Click **Sign Up**

**Expected Result:**
- ✅ Account created in Firebase Auth
- ✅ User document created in Firestore `users` collection
- ✅ Redirected to Home Screen
- ✅ Login works with created credentials

### Test Sign In
1. Click **Sign In** on login screen
2. Enter credentials from sign up
3. Click **Sign In**

**Expected Result:**
- ✅ Successfully logged in
- ✅ User data loaded from Firestore
- ✅ Profile screen shows user information

---

## 🔧 Troubleshooting

### "CONFIGURATION_NOT_FOUND" Error
**Cause**: reCAPTCHA misconfiguration or missing Firestore database
**Solution**: 
- Ensure Firestore database is created
- Disable reCAPTCHA for development (Step 3.2)
- Rebuild app: `flutter clean && flutter run`

### "Permission denied" Error
**Cause**: Firestore security rules too restrictive
**Solution**:
- Update rules as shown in Step 2
- Wait 1-2 minutes for rules to propagate
- Rebuild app

### "User collection not found" Error
**Cause**: `users` collection not created
**Solution**:
- Create `users` collection manually (Step 1.2)
- OR first sign-up will create it automatically

---

## ✅ Verification Checklist

- [ ] Firestore Database created in `student-stress-app` region
- [ ] `users` collection exists
- [ ] Email/Password authentication enabled
- [ ] reCAPTCHA disabled (development only)
- [ ] Firestore security rules updated
- [ ] App rebuilt after Firebase setup

Once all ✅ are complete, sign up and sign in should work perfectly!
