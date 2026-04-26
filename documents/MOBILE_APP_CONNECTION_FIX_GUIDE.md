# Mobile App Backend Connection Error - Fix Guide

## Error Message
```
Client exception with socket exception connection refused
os error err no=111 | address=localhost, port=67468
url=http://localhost:8000/analyze-digital-habits
```

This error means the **Flutter app cannot connect to the Python backend service on port 8000**.

---

## Quick Fix (Immediate)

### Step 1: Start the Python Backend Service

Open a PowerShell terminal in `d:\FYP\New folder\python\` and run:

```powershell
cd "d:\FYP\New folder\python"
conda activate stress_model
python main.py
```

**Or** run the batch script:
```powershell
.\start_backend.bat
```

You should see:
```
[*] Initializing FastAPI backend with YAMNet audio analysis...
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

### Step 2: Verify Backend is Running

In a **new** PowerShell window, test the health endpoint:
```powershell
curl http://localhost:8000/health
```

Should return a response (success if no "connection refused" error).

---

## Environment-Specific Setup

### For Android Emulator (Default)

The app is configured to use `10.0.2.2:8000` (Android emulator's way to reach the host machine).

**No additional setup needed** - just ensure the backend is running on port 8000.

### For Physical Android Device

Physical devices need your computer's actual IP address or an ngrok tunnel.

#### Option A: Use Your Computer's IP Address

1. **Find your computer's IP:**
   ```powershell
   ipconfig
   ```
   Look for "IPv4 Address" (e.g., `192.168.x.x`)

2. **In the Flutter app, go to Settings and enter:**
   ```
   http://192.168.1.100:8000
   ```
   (Replace with your actual IP)

3. **On your computer firewall**, allow port 8000:
   - Windows Defender Firewall → Allow an app through firewall → Python/Uvicorn

#### Option B: Use ngrok (Easier for Testing)

1. **Install ngrok:** https://ngrok.com/download

2. **Create a tunnel to localhost:8000:**
   ```powershell
   ngrok http 8000
   ```

   You'll see:
   ```
   Forwarding                    https://abc123.ngrok.io -> http://localhost:8000
   ```

3. **In the Flutter app Settings, enter:**
   ```
   https://abc123.ngrok.io
   ```

### For iOS Simulator

iOS simulator can reach localhost directly, so use:
```
http://localhost:8000
```

---

## How to Configure Backend URL in Mobile App

### Option 1: Direct URL Configuration

If your app has a **Settings screen**, look for "Backend URL" field and enter the appropriate URL:
- **Emulator**: `http://10.0.2.2:8000`
- **Physical device**: `http://192.168.x.x:8000` or ngrok URL
- **iOS**: `http://localhost:8000`

### Option 2: Programmatically (For Developers)

Edit `lib/services/digital_habits_service.dart` and add this to your initialization code:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_stress_app/services/digital_habits_service.dart';
import 'package:student_stress_app/services/backend_service.dart';

// For physical device using ngrok:
final prefs = await SharedPreferences.getInstance();
await DigitalHabitsService.setBackendUrl('https://your-ngrok-url.ngrok.io', prefs);
await BackendService().setBackendUrl('https://your-ngrok-url.ngrok.io');

// For physical device using local IP:
await DigitalHabitsService.setBackendUrl('http://192.168.1.100:8000', prefs);
await BackendService().setBackendUrl('http://192.168.1.100:8000');
```

---

## Troubleshooting Checklist

### ❌ Still Getting Connection Refused?

1. **Is the backend actually running?**
   ```powershell
   # Check if Python process is running
   Get-Process python | Where-Object {$_.CommandLine -match "main.py"}
   
   # If not found, start it:
   cd "d:\FYP\New folder\python"
   python main.py
   ```

2. **Is port 8000 in use by something else?**
   ```powershell
   netstat -ano | findstr :8000
   
   # If something is using it, kill the process:
   taskkill /PID <PID> /F
   ```

3. **Wrong device/emulator?**
   - Emulator → use `10.0.2.2:8000`
   - Physical phone → use your computer's IP or ngrok
   - iOS → use `localhost:8000`

4. **Check console logs in Flutter:**
   - Run: `flutter run -v` for verbose output
   - Look for `[DigitalHabits]` or `[BackendService]` messages

5. **Firewall blocking the port?**
   - Windows defender might block port 8000
   - Add Python.exe to Windows Firewall exceptions

---

## What Changed in the Mobile App

The app now has **improved error handling**:

✅ **Graceful Degradation**: If backend is unavailable, the app will:
   - Use fallback local analysis instead of crashing
   - Retry up to 2 times with exponential backoff
   - Cache last successful response

✅ **Configurable Backend URL**: You can now change the backend URL without code modification:
   - Via Settings screen (if implemented)
   - Via `SharedPreferences`
   - Via direct method calls

✅ **Better Error Messages**: Console logs show exactly what's happening during connection attempts

---

## Backend Service Requirements

Ensure Python backend has all dependencies installed:

```powershell
cd "d:\FYP\New folder\python"
conda activate stress_model
pip install -r requirements.txt
```

Required packages:
- `fastapi`
- `uvicorn`
- `tensorflow` (for YAMNet audio analysis)
- `langchain`
- `langgraph`
- `langchain-google-genai` (requires GOOGLE_API_KEY in .env)
- All other packages in `requirements.txt`

---

## Testing the Connection

Use this simple test script to verify everything works:

```powershell
# Test digital habits endpoint
$body = @{
    user_id = "test_user"
    unlocks = 45
    screen_time = 120
    app_usage = @()
    call_log = 5
    messages = 10
    late_night_usage = $false
    morning_rush = $false
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:8000/analyze-digital-habits" `
  -Method POST `
  -ContentType "application/json" `
  -Body $body
```

Should return a JSON response with `digital_score`.

---

## Still Need Help?

Check these files for more context:
- [Backend Service Documentation](./python/QUICK_REFERENCE.md)
- [Integration Setup Guide](./python/INTEGRATION_SETUP_GUIDE.md)
- [Main Python Backend](./python/main.py)
