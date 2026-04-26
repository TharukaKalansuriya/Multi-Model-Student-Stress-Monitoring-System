## 🎯 BACKEND STARTUP & FIX GUIDE - Complete Steps

**Your Issue**: Backend not starting, ngrok showing localhost:80 error, scores not generating

---

## ✅ Step 1: Fix ngrok Configuration (CRITICAL!)

### The Problem
```
ERR_NGROK_8012 - Connection refused at http://localhost:80
```

### The Solution
**ngrok needs port 8000, NOT port 80!**

```bash
# ❌ WRONG
ngrok http 80

# ✅ CORRECT
ngrok http 8000
```

When you run the correct command, you should see:
```
Forwarding                    https://xxxx-yyyy-zzzz.ngrok-free.dev -> http://localhost:8000
```

---

## ✅ Step 2: Check Python Environment

Open a terminal and run:

```bash
cd D:\FYP\after akilas model edit\python

# Check Python is installed
python --version

# Should show: Python 3.8+ (or similar)
```

---

## ✅ Step 3: Run Diagnostic

This checks if all dependencies are installed:

```bash
cd D:\FYP\after akilas model edit\python
python diagnose_backend.py
```

**Expected output:**
```
[TEST 1] Python Installation
  ✅ PASSED

[TEST 2] Required Packages
  ✅ fastapi
  ✅ uvicorn
  ✅ tensorflow
  ✅ tensorflow_hub
  ... (more packages)
  ✅ PASSED

[TEST 3] Environment Configuration (.env)
  ✅ .env file found
  ✅ GOOGLE_API_KEY is set
  ✅ PASSED

[TEST 4] Service Imports
  ✅ YAMNet Service
  ✅ Digital Habits Service
  ✅ Physical Activity Service
  ✅ Recommendation Service
  ✅ PASSED

✅ ALL TESTS PASSED!
```

**If diagnostic FAILS:**
```bash
# Install missing packages
pip install -r requirements.txt

# Then try diagnose again
python diagnose_backend.py
```

---

## ✅ Step 4: Start Backend

After diagnostic passes, start the backend:

### Option A: Double-click start script
```
Double-click: D:\FYP\after akilas model edit\python\start_backend.bat
```

### Option B: Manual startup
```bash
cd D:\FYP\after akilas model edit\python
python main.py
```

**Expected output:**
```
[*] Initializing FastAPI backend with YAMNet audio analysis...
[*] Initializing Digital Habits analyzer...
[*] Initializing Physical Activity analyzer (UCI HAR Dataset)...
[*] Initializing Recommendation Engine (LanGraph + Google Gemini)...
[OK] YAMNet Service initialized
[OK] Digital Habits Service initialized
[OK] Physical Activity Service initialized
[OK] Recommendation Service initialized with Google Gemini
INFO:     Uvicorn running on http://0.0.0.0:8000
```

**If it crashes or shows errors:**
1. Read the error message carefully
2. Check the **Troubleshooting** section below
3. Run `python diagnose_backend.py` again

---

## ✅ Step 5: Verify Backend is Running

Open another terminal (keep first one running):

```bash
# Test health check
curl http://localhost:8000/health

# Should return:
# {"status":"OK","message":"FastAPI backend is running successfully!","port":8000}
```

Or use the endpoint tester:
```bash
cd D:\FYP\after akilas model edit\python
python test_endpoints.py
```

---

## ✅ Step 6: Start ngrok (in another terminal)

Keep the backend running, open a NEW terminal:

```bash
# Navigate to ngrok (or add to PATH)
# Then run:
ngrok http 8000

# You should see:
# Forwarding     https://xxxx-yyyy-zzzz.ngrok-free.dev -> http://localhost:8000
```

---

## ✅ Step 7: Test Score Generation

The key issue is scores not generating. Test each score:

### Test 1: Recommendations (generates all 3 scores)
```bash
curl -X POST http://localhost:8000/get-recommendations \
  -H "Content-Type: application/json" \
  -d '{"audio_score": 45, "digital_score": 55, "physical_score": 40}'
```

### Test 2: Digital Habits Score
```bash
curl -X POST http://localhost:8000/analyze-digital-habits \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test",
    "unlocks": 15,
    "screen_time": 200,
    "call_log": 5,
    "messages": 20,
    "late_night_usage": false,
    "app_usage": [
      {"app": "YouTube", "time_ms": 600000, "category": "Entertainment"}
    ]
  }'
```

**Expected response:**
```json
{
  "status": "Success",
  "digital_score": 52.3,
  "components": {
    "app_usage_score": 45,
    "screen_time_score": 55,
    "unlock_frequency_score": 50,
    "time_pattern_score": 48
  }
}
```

### Test 3: Physical Activity Score
```bash
curl -X POST http://localhost:8000/analyze-movement \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test",
    "acc_x": 0.5,
    "acc_y": 9.8,
    "acc_z": 0.3,
    "activity_history": ["SITTING", "STANDING", "WALKING"]
  }'
```

**Expected response:**
```json
{
  "status": "Success",
  "activity": "WALKING",
  "physical_stress_score": 45,
  "movement_intensity": 65
}
```

---

## 🆘 Troubleshooting

### Problem: "ModuleNotFoundError: No module named 'tensorflow'"

**Fix:**
```bash
pip install tensorflow tensorflow-hub
```

### Problem: "ImportError: cannot import name 'CORSMiddleware'"

**Fix:**
```bash
pip install fastapi
```

### Problem: "ImportError: cannot import name 'ChatGoogleGenerativeAI'"

**Fix:**
```bash
pip install langchain-google-genai langchain langgraph
```

### Problem: "FileNotFoundError: .env"

**Fix:**
Create file: `D:\FYP\after akilas model edit\python\.env`

Content:
```
GOOGLE_API_KEY=AIzaSyBJa3K77pmPr6PpsScz7sQM0pn9yqPxX8o
```

### Problem: "KeyError: 'GOOGLE_API_KEY'"

**Fix:**
1. Make sure .env file exists (see above)
2. Restart backend: `python main.py`
3. If still fails, verify the key in .env file

### Problem: "Connection refused at localhost:8000"

**Fix:**
1. Make sure backend is running: `python main.py`
2. Check console doesn't have errors
3. Wait 5-10 seconds for services to initialize
4. Try health check: `curl http://localhost:8000/health`

### Problem: "ngrok tunnel not working"

**Fix:**
1. Make sure ngrok uses port 8000: `ngrok http 8000`
2. Make sure backend is running first
3. Check ngrok shows: `Forwarding ... -> http://localhost:8000`
4. Not port 80!

### Problem: Scores come back as 0 or empty

**Fix:**
1. Run diagnostic: `python diagnose_backend.py`
2. Check backend console for service initialization errors
3. Verify GOOGLE_API_KEY in .env is valid
4. Check if you're calling correct endpoint
5. Wait longer (Gemini API is slow - up to 45 seconds)

### Problem: "Timeout waiting for recommendations"

**Fix:**
This is normal! Gemini API is slow:
- First call: 5-40 seconds (normal)
- After that: Uses cache (instant)
- System automatically falls back to dynamic recommendations if timeout

---

## 📋 Complete Startup Sequence

### Terminal 1 - Backend
```bash
cd D:\FYP\after akilas model edit\python
python main.py
# Keep this running - don't close!
```

### Terminal 2 - Diagnostic (one-time check)
```bash
cd D:\FYP\after akilas model edit\python
python diagnose_backend.py
# Should show all ✅ PASSED
```

### Terminal 3 - ngrok Tunnel
```bash
ngrok http 8000
# Keep this running - copy the https URL
```

### Terminal 4 - Test Endpoints
```bash
cd D:\FYP\after akilas model edit\python
python test_endpoints.py
# Should show scores generating
```

### Terminal 5 - Mobile App
```
Run your Flutter app
Configure with ngrok URL from Terminal 3
```

---

## 🎯 Your Corrected ngrok Command

**WRONG:**
```bash
ngrok http 80
```

**RIGHT:**
```bash
ngrok http 8000
```

---

## 📊 Port Reference

| What | Port | Why |
|------|------|-----|
| FastAPI Backend | **8000** | Main API server |
| ngrok tunnel | **8000** | Forward to FastAPI |
| ❌ localhost:80 | 80 | System port (needs admin) |
| Android Emulator | 10.0.2.2:8000 | How emulator reaches PC |

---

## ✅ Success Indicators

✅ Backend started successfully when you see:
```
INFO: Uvicorn running on http://0.0.0.0:8000
```

✅ Health check works:
```bash
curl http://localhost:8000/health
# Returns: {"status":"OK",...}
```

✅ Scores generate:
```
digital_score: 52.3°
physical_stress_score: 45°
recommendations: 3 generated
```

✅ ngrok shows:
```
Forwarding https://xxxx-yyyy-zzzz.ngrok-free.dev -> http://localhost:8000
```

---

## 🎯 TL;DR - Just Do This

1. **Run diagnostic:**
   ```bash
   cd D:\FYP\after akilas model edit\python
   python diagnose_backend.py
   ```

2. **If it passes, start backend:**
   ```bash
   python main.py
   ```

3. **In another terminal, start ngrok:**
   ```bash
   ngrok http 8000    # NOT 80!
   ```

4. **Test endpoints:**
   ```bash
   python test_endpoints.py
   ```

5. **Configure mobile app:**
   ```dart
   await backend.switchToNgrok('https://[your-ngrok-url]');
   ```

That's it! 🎉

