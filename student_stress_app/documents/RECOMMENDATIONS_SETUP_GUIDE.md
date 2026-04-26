# 📱 Mobile App Updates - Recommendations & Notifications Setup

## ✅ Completed Updates

### 1. **Notification System** (`services/notification_service.dart`)
- ✅ Flutter Local Notifications integration
- ✅ Periodic task scheduling with Workmanager
- ✅ 3-hour interval recommendations
- ✅ Background task execution
- ✅ Platform-specific (Android + iOS) support

### 2. **Backend Integration** (`services/backend_service.dart`)
- ✅ API endpoints for fetching recommendations
- ✅ Audio, digital, and physical analysis
- ✅ Caching mechanism for offline support
- ✅ Fallback recommendations
- ✅ Error handling with graceful degradation

### 3. **Recommendations Display** (`screens/recommendations_screen.dart`)
- ✅ Beautiful UI with stress analysis card
- ✅ Individual recommendation cards with priority levels
- ✅ Stress score visualization
- ✅ Loading and error states
- ✅ Retry functionality

### 4. **Home Screen Enhancements** (`screens/home_screen.dart`)
- ✅ "View Recommendations" button (✨)
- ✅ Automatic notification initialization on collection start
- ✅ Periodic notification scheduling (every 3 hours)
- ✅ Notification cleanup on collection end

### 5. **Permissions** (`android/app/src/main/AndroidManifest.xml`)
- ✅ POST_NOTIFICATIONS permission (Android 13+)
- ✅ SCHEDULE_EXACT_ALARM permission for periodic tasks

### 6. **Dependencies** (`pubspec.yaml`)
- ✅ flutter_local_notifications: ^17.1.2
- ✅ workmanager: ^0.5.2

---

## 🚀 Testing the New Features

### **Option A: Android Emulator/Device**

```bash
# Connect Android device or start emulator
adb devices

# Run the app
cd "D:\FYP\New folder\student_stress_app"
flutter run

# Or for debug mode:
flutter run -d emulator-5554  # Replace with your device ID
```

### **Option B: iOS Simulator**

```bash
# Start iOS simulator
open -a Simulator

# Run the app
cd "D:\FYP\New folder\student_stress_app"
flutter run -d booted
```

### **Option C: Running from VS Code**

1. Open the Flutter project in VS Code
2. Press `F5` or click "Run and Debug"
3. Select your target device/emulator
4. App will launch with debugging enabled

---

## 📋 Manual Testing Steps

### **Step 1: Start Data Collection**

1. Open the app
2. Tap **"Start Collection"** button
3. Grant microphone permissions if prompted
4. You should see: "Automated data collection is now active."
5. **Notification system now active** - will show recommendations every 3 hours

### **Step 2: Check Stress Level**

1. Once collection is running, tap **"Check Stress Level"** button
2. App fetches 3 stress scores:
   - 🎤 Audio/Environment stress
   - 📱 Digital/Phone usage stress
   - 🏃 Physical activity stress
3. Scores are displayed in circular progress bars

### **Step 3: View Recommendations**

1. Tap **"View Recommendations"** button (✨)
2. Screen shows:
   - **Stress Level Summary** (Low/Moderate/High/Critical)
   - **Primary Stressor** (Audio/Digital/Physical)
   - **Stress Scores** with progress bars
   - **3 Personalized Recommendations** from Gemini AI:
     - Title (e.g., "Take a Walking Break")
     - Action (specific task)
     - Duration (time required)
     - Benefit (how it helps)
     - Motivation (encouraging phrase)
     - Priority (High/Medium/Low)

### **Step 4: Test Notifications** (Simulation)

Since 3-hour intervals are long, you can test this way:

**For iOS/Android:**
- Notifications will appear:
  - Every 3 hours during collection
  - Shows "💡 Time for stress management!"
  - Triggers even if app is minimized/closed (background mode)
  - Tap notification to view recommendations

**For Immediate Testing:**
- Modify notification_service.dart temporarily:
```dart
// Change from Duration(hours: 3) to Duration(minutes: 1)
frequency: const Duration(minutes: 1),  // <- Change this for testing
```
- Then run: `flutter run --no-fast-start`

### **Step 5: End Collection**

1. Tap **"End Collection"** button (⏹️)
2. Confirm "End Data Capture?"
3. Notifications stop being scheduled
4. Collection status changes to "Inactive"

---

## 🔧 Configuration

### **Backend URL**

The app is configured to use:
```
https://attractable-camdyn-otoscopic.ngrok-free.dev
```

**To change the URL:**

1. Open `lib/services/backend_service.dart`
2. Find line: `static const String _baseUrl = '...';`
3. Update to your backend URL:
   ```dart
   static const String _baseUrl = 'https://your-backend-url.com';
   ```
4. Run: `flutter run --no-fast-start` (full restart required)

### **Notification Interval**

To change the 3-hour interval:

1. Open `lib/services/notification_service.dart`
2. Find: `frequency: const Duration(hours: 3),`
3. Change to desired interval:
   ```dart
   frequency: const Duration(hours: 1),  // Every 1 hour
   frequency: const Duration(minutes: 30),  // Every 30 minutes
   ```

### **API Key**

Backend uses Google Gemini API key:
- Stored in `.env` file: `D:\FYP\New folder\python\.env`
- Key: `AIzaSyBJa3K77pmPr6PpsScz7sQM0pn9yqPxX8o`
- Free tier: 60 requests/minute

---

## 📊 Data Flow Diagram

```
┌─────────────┐
│  HOME SCREEN   │
└────┬────────┘
     │ "Start Collection"
     ↓
┌──────────────────────┐
│ Initialize Services  │
│ - Notifications      │
│ - Backend Service    │
│ - Scheduler          │
└────┬─────────────────┘
     │
     ↓
┌────────────────────────┐
│ Schedule Periodic Task │
│ - Event: Every 3 hours │
│ - Service: Workmanager │
└────┬───────────────────┘
     │
     ↓
┌─────────────────────────┐
│ Collect Sensor Data     │
│ - Audio samples         │
│ - Digital habits        │
│ - Physical activity     │
└────┬────────────────────┘
     │
     ↓
┌──────────────────────────┐         ┌────────────────┐
│ "Check Stress Level" Tap │ ───────→│ Backend Server │
└────┬─────────────────────┘         │ (FastAPI)      │
     │                                └────────┬───────┘
     ↓                                         │
┌──────────────────────────┐                   ↓
│ Show 3 Scores in UI      │             ┌──────────────┐
│ - Audio 🎤               │             │ Gemini LLM   │
│ - Digital 📱             │             │ (Generate    │
│ - Physical 🏃           │             │  Recs)       │
└────┬─────────────────────┘             └──────────────┘
     │                                         │
     ↓                                         ↓
┌──────────────────────────┐         ┌────────────────┐
│ "View Recommendations"   │         │  3 Personalized│
│        (✨ button)        │ ←────── │  Recommendations│
│                          │         │                │
│ Show:                    │         └────────────────┘
│ - Stress Analysis        │
│ - Scores & Progress      │
│ - AI Recommendations     │
└──────────────────────────┘

Every 3 Hours:
    ↓
┌─────────────────────────┐
│  Background Notification │
│  "💡 Time for stress     │
│   management!"           │
│  → Tap → View Recs       │
└─────────────────────────┘
```

---

## 🎯 Key Features

### **Recommendations Screen**
- 📊 Real-time stress analysis
- 🎯 Personalized AI recommendations (from Google Gemini)
- ⏱️ Time estimates for each recommendation
- 🎨 Color-coded priority levels (High/Medium/Low)
- 💾 Caching for offline support
- 🔄 Retry functionality for network errors

### **Notification System**
- 🔔 Local notifications (no server needed)
- 🔄 Periodic scheduling every 3 hours
- 📱 Works in background (Android/iOS)
- 🎵 Sound + Vibration + Badge
- ✅ Successfully handles both foreground and background states

### **Backend Integration**
- 🌐 RESTful API calls to backend
- 🧠 AI-powered recommendations via Gemini
- ⚙️ Automatic fallback for network issues
- 💾 Smart caching for offline resilience
- 📊 Multiple analysis endpoints (audio, digital, physical)

---

## 🐛 Troubleshooting

### **Issue: "flutter run" fails on Windows**
**Solution:** 
- Use an Android emulator or iOS simulator instead
- Or use `flutter run -d chrome` for web testing

### **Issue: Notifications not appearing**
**Check:**
1. Device has notifications enabled
2. Android/iOS notification permissions granted
3. Backend service is running
4. Check logs: `flutter logs`

### **Issue: Backend service not responding**
**Check:**
1. Backend server is running: `python main.py` (in Python folder)
2. ngrok tunnel is active
3. URL is correct in `backend_service.dart`
4. Check network connectivity

### **Issue: Recommendations show generic fallback**
**Cause:** Backend couldn't reach Gemini LLM
**Solution:**
1. Verify Google API key in `.env`
2. Check internet connection
3. Verify API key quota (60 req/min)
4. Backend logs show detailed error

---

## 📝 File Summary

| File | Purpose |
|------|---------|
| `notification_service.dart` | Handles all notification scheduling |
| `backend_service.dart` | Communicates with FastAPI backend |
| `recommendations_screen.dart` | Beautiful recommendations UI |
| `home_screen.dart` | Updated with new buttons & initialization |
| `pubspec.yaml` | Added notification dependencies |
| `AndroidManifest.xml` | Added permissions for notifications |

---

## 🚀 Next Steps

1. **Build for Android:**
   ```bash
   flutter build apk --release
   ```

2. **Build for iOS:**
   ```bash
   flutter build ipa --release
   ```

3. **Deploy to Play Store/App Store** (future)

4. **Monitor Analytics** (add Firebase Analytics later)

---

## 💡 Tips

- **Hot Reload:** `r` during `flutter run` to reload code
- **Hot Restart:** `R` during `flutter run` for full app restart
- **View Logs:** `flutter logs` in another terminal
- **Check Devices:** `flutter devices` to see available targets
- **Clean Build:** `flutter clean && flutter pub get` if issues occur

---

**Version:** 1.0.0 | **Last Updated:** April 18, 2026 | **Status:** ✅ Ready for Testing
