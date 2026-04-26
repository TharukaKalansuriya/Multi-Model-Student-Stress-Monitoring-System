# 🚀 Mobile App Connection Error - QUICK START FIX

## ⚡ Immediate Fix (2 Minutes)

### Step 1: Start the Python Backend
```powershell
cd "d:\FYP\New folder\python"
python main.py
```

**Wait for this message:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Step 2: Run the Flutter App
```bash
flutter run
```

**Done!** ✅ The app should now connect successfully.

---

## 🔧 If Still Not Working

### 1. Verify Backend is Actually Running
```powershell
curl http://localhost:8000/health
```
Should return a response, not "Connection refused"

### 2. Check Port 8000 is Free
```powershell
netstat -ano | findstr :8000
```

If something is using it:
```powershell
taskkill /PID <PID> /F
```

### 3. Test Backend Connection
```powershell
cd "d:\FYP\New folder\python"
python test_mobile_app_connection.py
```

---

## 📱 Different Devices

| Device | URL | Steps |
|--------|-----|-------|
| **Android Emulator** | `http://10.0.2.2:8000` | Just run `flutter run` |
| **Physical Android** | `http://192.168.1.100:8000` | See "Physical Device" below |
| **iOS Simulator** | `http://localhost:8000` | Just run `flutter run` |
| **Remote/ngrok** | `https://your-url.ngrok.io` | See "Remote Backend" below |

### Physical Device Setup

1. **Find your PC's IP:**
   ```powershell
   ipconfig
   # Look for "IPv4 Address" like 192.168.1.100
   ```

2. **Allow port 8000 through firewall:**
   - Windows Defender Firewall → Allow an app → Python

3. **In the app, go to Settings and enter:**
   ```
   http://192.168.1.100:8000
   ```

### Remote Backend (ngrok)

1. **Download ngrok:** https://ngrok.com/download

2. **Create tunnel:**
   ```powershell
   ngrok http 8000
   ```

3. **Copy the URL and enter in app settings:**
   ```
   https://abc123.ngrok.io
   ```

---

## 📋 Troubleshooting Checklist

- [ ] Backend python service is running (`python main.py`)
- [ ] Port 8000 is free (check: `netstat -ano | findstr :8000`)
- [ ] Firewall allows port 8000
- [ ] All Python dependencies installed (`pip install -r requirements.txt`)
- [ ] Correct device type (emulator uses `10.0.2.2`, physical uses IP)
- [ ] App has internet permission in `AndroidManifest.xml`

---

## 📱 Configure Backend URL from App

#### Add to Settings Screen:
```dart
import 'package:student_stress_app/widgets/backend_configuration_sheet.dart';

FloatingActionButton(
  onPressed: () => showBackendConfigurationSheet(context),
  child: const Icon(Icons.settings),
)
```

---

## 📝 What Changed in Mobile App

✅ **Handles connection failures gracefully**
- No more crashes when backend offline
- Uses cached data or local analysis as fallback

✅ **Configurable backend URL**
- Set via UI settings
- Persistent across app restarts
- Support for all environments

✅ **Retry logic**
- Automatically retries up to 2 times
- Exponential backoff between attempts

✅ **Better error messages**
- Console shows exactly what's happening
- Easier to debug issues

---

## 🧪 Test Connection

### Quick Test
```powershell
curl http://localhost:8000/health
```

### Full Test
```powershell
cd "d:\FYP\New folder\python"
python test_mobile_app_connection.py
```

Expected output:
```
✅ Health check PASSED
✅ Digital habits analysis PASSED  
✅ Recommendations endpoint PASSED

🎉 All tests PASSED! Backend is working correctly.
```

---

## 📚 More Information

- **Full Guide**: [MOBILE_APP_CONNECTION_FIX_GUIDE.md](MOBILE_APP_CONNECTION_FIX_GUIDE.md)
- **Implementation Summary**: [MOBILE_APP_FIX_SUMMARY.md](MOBILE_APP_FIX_SUMMARY.md)
- **Python Backend**: [python/main.py](python/main.py)

---

## ⚠️ Common Errors & Solutions

### `Connection refused`
→ Backend not running. Start it: `python main.py`

### `10.0.2.2: connection refused`
→ You're on physical device. Use your PC's IP instead.

### `Cannot resolve host`
→ Firewall blocking. Allow port 8000 in Windows Firewall.

### `Timeout`
→ Backend is slow. Check: `python test_mobile_app_connection.py`

---

## ✅ Success Indicators

- [ ] Backend console shows `Uvicorn running on http://0.0.0.0:8000`
- [ ] `curl http://localhost:8000/health` returns response
- [ ] App launches without errors
- [ ] App doesn't crash when generating stress score
- [ ] Console shows `[DigitalHabits] Analysis complete`

---

## 🆘 Still Need Help?

1. Check **MOBILE_APP_CONNECTION_FIX_GUIDE.md** - Comprehensive troubleshooting
2. Run **test_mobile_app_connection.py** - Automated testing
3. Check backend logs for errors
4. View app logs: `flutter run -v`

---

**That's it!** 🎉 Your mobile app should now connect successfully.
