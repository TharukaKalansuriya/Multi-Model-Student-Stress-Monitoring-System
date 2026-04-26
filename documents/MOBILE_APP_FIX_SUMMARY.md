# Mobile App Connection Error - Resolution Summary

## Problem Solved ✅

**Error**: 
```
Client exception with socket exception connection refused
os error err no=111 | address=localhost, port=67468
url=http://localhost:8000/analyze-digital-habits
```

**Root Cause**: The Python backend service on port 8000 was not running, and the mobile app had no fallback mechanism.

---

## Changes Made to Mobile App

### 1. **Improved Error Handling** (digital_habits_service.dart)
- **Before**: App would crash if backend was unavailable
- **After**: 
  - ✅ Gracefully handles connection failures
  - ✅ Retries up to 2 times with exponential backoff
  - ✅ Falls back to local analysis if backend unavailable
  - ✅ Uses cached data from previous successful requests

### 2. **Configurable Backend URL** (Both Services)
- **New Methods**:
  - `DigitalHabitsService.setBackendUrl(url, prefs)` - Set custom URL
  - `BackendService.setBackendUrl(url)` - Set custom URL
  - `BackendService.getBackendUrl()` - Get current URL
  - `DigitalHabitsService.getBackendUrl()` - Get current URL

- **Stored in SharedPreferences** - Persists across app restarts
- **Supports all environments**:
  - Android Emulator: `http://10.0.2.2:8000`
  - Physical Device: `http://192.168.x.x:8000` or ngrok URL
  - iOS: `http://localhost:8000`

### 3. **Backend Configuration UI Widget** (NEW FILE)
- **File**: `lib/widgets/backend_configuration_sheet.dart`
- **Features**:
  - User-friendly config interface
  - Quick preset buttons for common scenarios
  - Connection test functionality
  - URL validation
  - Error feedback with color-coded messages

---

## How to Use

### For Immediate Fix

1. **Start the Python backend**:
   ```powershell
   cd "d:\FYP\New folder\python"
   python main.py
   ```

2. **Run the Flutter app** - It will now:
   - Connect to `http://10.0.2.2:8000` (emulator) or configured URL
   - If connection fails, use fallback local analysis
   - Show better error messages in console

### To Configure Backend URL

#### Option 1: From Mobile App (Recommended)
Add this button to your settings screen:
```dart
FloatingActionButton(
  onPressed: () => showBackendConfigurationSheet(context),
  child: const Icon(Icons.settings),
)
```

#### Option 2: Programmatically
```dart
import 'package:student_stress_app/widgets/backend_configuration_sheet.dart';

// Show config sheet
showBackendConfigurationSheet(context);
```

#### Option 3: Direct Method Call
```dart
import 'package:student_stress_app/services/digital_habits_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final prefs = await SharedPreferences.getInstance();

// For ngrok
await DigitalHabitsService.setBackendUrl('https://abc123.ngrok.io', prefs);

// For physical device  
await DigitalHabitsService.setBackendUrl('http://192.168.1.100:8000', prefs);
```

---

## Testing the Fix

### Test 1: Backend Connection
```powershell
# Windows PowerShell
curl http://localhost:8000/health

# Should return: {"status":"ok"} or similar
```

### Test 2: Digital Habits Analysis
```powershell
$body = @{
    user_id = "test"
    unlocks = 45
    screen_time = 120
    app_usage = @()
    call_log = 5
    messages = 10
    late_night_usage = $false
    morning_rush = $false
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:8000/analyze-digital-habits" `
  -Method POST -ContentType "application/json" -Body $body
```

### Test 3: Mobile App Tests
- ✅ App loads without crashing when backend is offline
- ✅ Digital score is calculated locally (fallback)
- ✅ Shows appropriate messages in console
- ✅ Retries and recovers when backend comes back online

---

## Files Modified

### Flutter/Dart Files
1. `lib/services/digital_habits_service.dart`
   - Added retry logic with exponential backoff
   - Added local fallback analysis
   - Made backend URL configurable and persistent

2. `lib/services/backend_service.dart`
   - Made backend URL configurable
   - Added URL persistence via SharedPreferences
   - Added URL getter method

### New Files
3. `lib/widgets/backend_configuration_sheet.dart` (NEW)
   - UI widget for backend configuration
   - Connection testing
   - Quick presets for different environments

### Documentation
4. `MOBILE_APP_CONNECTION_FIX_GUIDE.md` (NEW)
   - Comprehensive troubleshooting guide
   - Setup instructions for different environments
   - Firewall configuration guide
   - Testing procedures

---

## Fallback Digital Habits Analysis

When backend is unavailable, the app calculates score locally based on:

```
Base Score: 30 points

+ Unlocks Analysis:
  - > 80 unlocks: +30 points
  - > 50 unlocks: +15 points
  - > 30 unlocks: +5 points

+ Screen Time Analysis:
  - > 240 mins: +35 points
  - > 120 mins: +15 points
  - > 60 mins: +5 points

+ Late Night Usage: +20 points

+ High Communication (calls + messages > 100): +15 points

Maximum Score: 100
```

This ensures the app remains functional even without backend access.

---

## Logging for Debugging

Console logs now include detailed information:

```
[DigitalHabits] Preparing analysis:
[DigitalHabits] Sending to backend (attempt 1/3): http://10.0.2.2:8000/analyze-digital-habits
[DigitalHabits] Attempt 1 failed: Connection refused
[DigitalHabits] Sending to backend (attempt 2/3): http://10.0.2.2:8000/analyze-digital-habits
[DigitalHabits] Analysis complete: Score = 65
```

View logs with:
```bash
flutter run -v
```

---

## Environment Setup Quick Reference

| Environment | URL | Use Case |
|---|---|---|
| **Android Emulator** | `http://10.0.2.2:8000` | Development (default) |
| **iOS Simulator** | `http://localhost:8000` | iOS development |
| **Physical Android** | `http://192.168.1.100:8000` | On-device testing |
| **Physical iOS** | `http://localhost:8000` or IP | On-device testing |
| **Remote Server** | `https://abc123.ngrok.io` | Testing with remote backend |

---

## Next Steps

1. ✅ **Apply these changes** to your Flutter project
2. ✅ **Start the Python backend**: `python main.py`
3. ✅ **Test the app** - should work even if backend disconnects
4. ✅ **Add config UI** to settings screen if needed
5. ✅ **Reference the fix guide** for troubleshooting

---

## Support

If you still encounter issues:

1. Check **MOBILE_APP_CONNECTION_FIX_GUIDE.md** (comprehensive troubleshooting)
2. Verify backend is running: `curl http://localhost:8000/health`
3. Check firewall allows port 8000
4. View app logs: `flutter run -v`
5. Verify correct URL in settings/code

---

## Summary

The connection error is now **resolved** through:
- ✅ Robust error handling
- ✅ Retry logic
- ✅ Fallback local analysis
- ✅ Persistent URL configuration
- ✅ User-friendly config UI
- ✅ Better logging

**The app will no longer crash when the backend is unavailable!**
