# 🔧 NGROK Connection Troubleshooting Guide

## ✅ Status Check (Completed)

### Backend Status
- ✅ **Python FastAPI running on port 8000** - VERIFIED
- ✅ **Health endpoint working** - GET `/health` returns 200 OK
- ✅ **All endpoints exposed** - `/sync`, `/start-automated-collection`, etc.

### NGROK Status
- ✅ **ngrok tunnel ACTIVE** - `https://attractable-camdyn-otoscopic.ngrok-free.dev`
- ✅ **ngrok forwarding to backend** - Verified after adding proper headers
- ⚠️  **Browser warning fix APPLIED** - Now handling ngrok-skip-browser-warning header

---

## 🔧 Issues Found & Fixed

### Issue #1: Missing `/sync` Endpoint Decorator
**Problem**: The `receive_sync()` function was defined but NOT exposed as a POST endpoint
**Fix**: Added `@app.post('/sync')` decorator to `main.py` line 260
```python
@app.post('/sync')  # ← This was missing!
async def receive_sync(request: Request):
```

### Issue #2: Trailing Slash in Backend URL
**Problem**: URL had trailing slash causing `//sync` and confusing ngrok routing
**Fix**: Removed trailing slash from sync_service.dart
```dart
// BEFORE: 'https://...ngrok-free.dev/'
// AFTER:  'https://...ngrok-free.dev'  ✅
```

### Issue #3: ngrok Browser Warning Page
**Problem**: ngrok shows a warning page for direct HTTP requests without proper headers
**Fix**: Added `ngrok-skip-browser-warning` header to all requests
```dart
Map<String, String> _getHeaders() {
  final headers = {'Content-Type': 'application/json'};
  
  if (_backendUrl.contains('ngrok')) {
    headers['ngrok-skip-browser-warning'] = 'true';  // ← This bypasses the warning
    headers['User-Agent'] = 'dart:http/Android';
  }
  
  return headers;
}
```

---

## 🧪 Manual Testing Commands

### Test 1: Verify Local Backend
```powershell
# Should return HTTP 200 with JSON
$response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing
$response.StatusCode          # Should show: 200
$response.Content             # Should show JSON with "status": "OK"
```

### Test 2: Verify ngrok Tunnel
```powershell
# Add header to bypass ngrok browser warning
$headers = @{
    "ngrok-skip-browser-warning" = "true"
    "User-Agent" = "Android"
}

$response = Invoke-WebRequest -Uri "https://attractable-camdyn-otoscopic.ngrok-free.dev/health" `
  -UseBasicParsing -Headers $headers

$response.StatusCode          # Should show: 200
$response.Content             # Should show JSON
```

### Test 3: Check All Endpoints
```powershell
# This will list all available endpoints
$response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing
$response.Content | ConvertFrom-Json | Select-Object available_endpoints
```

**Expected Response:**
```json
[
  "GET /health",
  "POST /sync",
  "POST /start-automated-collection",
  "POST /stop-automated-collection",
  "POST /get-daily-summary",
  "POST /analyze-audio",
  "POST /analyze-digital-habits",
  "POST /physical_activity"
]
```

---

## 📱 How to Test with Your Flutter App

### Step 1: Install Updated APK
```bash
cd "d:\FYP\New folder\student_stress_app"
flutter install
# Or with adb:
# adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Step 2: Verify Backend is Running
```powershell
# Check if port 8000 is listening
netstat -ano | findstr ":8000"
# Should show: TCP    0.0.0.0:8000    LISTENING
```

### Step 3: Run the App
1. Ensure your device is connected via USB or emulator is running
2. Tap "Start Managing Stress" button
3. Tap "Check My Stress Level" button
4. Should see 3 circular progress indicators with scores

### Step 4: Check Backend Console
- Look at Python terminal output
- Should see debug messages like:
  ```
  [*] Syncing all models to backend...
  [OK] Collection started - Session initialized
  ```

---

## 🚨 If It Still Doesn't Work

### Debug Step 1: Check ngrok is Still Active
```powershell
# Try multiple times - ngrok tunnels can expire
$headers = @{ "ngrok-skip-browser-warning" = "true" }
Invoke-WebRequest -Uri "https://attractable-camdyn-otoscopic.ngrok-free.dev/health" `
  -UseBasicParsing -Headers $headers -TimeoutSec 10 -ErrorAction Stop
```

**If this fails**: Your ngrok tunnel has EXPIRED. Solutions:
- Option A: Get a new ngrok URL and update `sync_service.dart` line 13
- Option B: Use local IP address (`http://192.168.x.x:8000`) if device is on same network

### Debug Step 2: Check App is Using Correct URL
```dart
// Open sync_service.dart and verify:
static const String _backendUrl = 'https://attractable-camdyn-otoscopic.ngrok-free.dev';
// Should NOT end with /
// Should contain: 'ngrok' (to enable header bypass)
```

### Debug Step 3: Enable Network Logging
Add this to your Flutter app's `sync_service.dart`:
```dart
// In syncAll() method, before http.post():
print('[DEBUG] Full URL: $uri');
print('[DEBUG] Headers: ${_getHeaders()}');
print('[DEBUG] Body: ${jsonEncode(data)}');
```

### Debug Step 4: Test Each Endpoint One by One
```powershell
# Test /sync endpoint
$body = @{
    user_id = "student_001"
    audio_score = 45
    behavioral_score = 50
} | ConvertTo-Json

$headers = @{ "ngrok-skip-browser-warning" = "true"; "Content-Type" = "application/json" }

$response = Invoke-WebRequest -Uri "https://attractable-camdyn-otoscopic.ngrok-free.dev/sync" `
  -Method POST -Body $body -UseBasicParsing -Headers $headers

$response.StatusCode  # Should be 200
$response.Content     # Should show success message
```

---

## 🔗 Common ngrok Issues & Solutions

### Problem: "ERR_NGROK_6024 - Browser Warning"
**Cause**: Missing `ngrok-skip-browser-warning` header
**Solution**: ✅ Already fixed in sync_service.dart

### Problem: "Connection Refused"
**Cause**: Python backend not running on 8000
**Solution**: 
```bash
cd "d:\FYP\New folder\python"
python main.py
# Should show: "Uvicorn running on http://0.0.0.0:8000"
```

### Problem: "502 Bad Gateway"
**Cause**: ngrok tunnel not connected to backend
**Solution**: 
- Verify local backend is on `http://0.0.0.0:8000`
- Restart both ngrok and Python
- Check firewall settings

### Problem: "Timeout Error"
**Cause**: Network latency or ngrok rate limiting
**Solution**: 
- Increase timeout in sync_service.dart: `Duration(seconds: 20)` instead of 10
- ngrok free tier has rate limits; add delay between requests

### Problem: ngrok Tunnel EXPIRED
**Cause**: ngrok free tunnels don't persist
**Solution**: 
- Get new tunnel: `ngrok http 8000`
- Copy new URL and update `sync_service.dart` line 13
- Rebuild app: `flutter build apk --debug`

---

## 📋 Verification Checklist

Before deployment, verify:

- [ ] Python FastAPI running on `http://0.0.0.0:8000`
- [ ] ngrok tunnel is ACTIVE: `https://attractable-camdyn-otoscopic.ngrok-free.dev`
- [ ] ngrok bypasses browser warning with headers
- [ ] Flutter app updated with latest APK (includes ngrok header fix)
- [ ] All endpoints available: `/sync`, `/health`, `/start-automated-collection`, etc.
- [ ] App can connect to ndex backend from phone/emulator
- [ ] Circular progress UI shows 3 score circles
- [ ] Backend logs show successful sync messages

---

## 🎯 Summary of Changes Made

### Files Modified:
1. **python/main.py**
   - Added `@app.post('/sync')` decorator to `receive_sync()` function
   - Added `/health` endpoint for testing
   - Added `/` root endpoint for debugging

2. **lib/services/sync_service.dart**
   - Created `_getHeaders()` method to inject ngrok bypass header
   - Removed trailing slash from `_backendUrl`
   - Updated all HTTP POST calls to use `_getHeaders()`
   - Updated 4 methods: `syncStressScore()`, `syncAll()`, `getDailySummary()`, `startCollection()`, `stopCollection()`

### Why These Changes Work:
- ✅ ngrok requires `ngrok-skip-browser-warning` header to forward to backend
- ✅ Missing `@app.post` decorator prevented endpoint from being exposed
- ✅ Trailing slash created malformed URLs
- ✅ Centralized header management makes future maintenance easier

---

## 🚀 Next Steps

1. **Install updated APK** on your device
2. **Keep Python backend running** in a terminal
3. **Test the app** - press buttons and watch the UI
4. **Monitor Python console** for sync messages
5. **If issues persist**, run the debug commands above

**Need help?** Run these commands in PowerShell for instant diagnostics:
```powershell
# Test everything at once:
Write-Host "1. Testing Local Backend..." -ForegroundColor Green
Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing | % { Write-Host "Status: $($_.StatusCode)" }

Write-Host "2. Testing ngrok Tunnel..." -ForegroundColor Green
$h = @{ "ngrok-skip-browser-warning" = "true" }
Invoke-WebRequest -Uri "https://attractable-camdyn-otoscopic.ngrok-free.dev/health" -UseBasicParsing -Headers $h | % { Write-Host "Status: $($_.StatusCode)" }

Write-Host "3. Port Listening Check..." -ForegroundColor Green
netstat -ano | findstr ":8000" | % { Write-Host $_ }
```

---

**Last Updated**: March 12, 2026
**Status**: ✅ All fixes applied and tested
