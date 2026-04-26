## 🚨 CRITICAL FIXES - Backend Not Starting & ngrok Issues

### Problem 1: ngrok ERR_NGROK_8012 Error

**The Error:**
```
ERR_NGROK_8012
Traffic successfully made it to the ngrok agent, but the agent failed to 
establish a connection to the upstream web service at http://localhost:80
```

**Root Cause:**
- ❌ You're running: `ngrok http 80`
- ✅ You should run: `ngrok http 8000`
- FastAPI backend runs on **port 8000**, NOT port 80!

**Fix:**
```bash
# WRONG - Don't do this:
ngrok http 80

# CORRECT - Do this:
ngrok http 8000
```

---

### Problem 2: Backend Not Starting

**The Error:**
- Python crashes when you run `python main.py`
- Or it hangs and doesn't print anything
- Localhost:80 is empty (nothing running)

**Root Causes:**
1. Missing Python packages
2. TensorFlow not installed
3. .env file missing GOOGLE_API_KEY
4. Import errors in services

**Fix - Step 1: Run Diagnostic**
```bash
cd D:\FYP\after akilas model edit\python
python diagnose_backend.py
```

**This will check:**
- ✅ Python version
- ✅ All required packages
- ✅ .env file configuration
- ✅ Service imports
- ✅ FastAPI initialization

**If diagnostic FAILS:**
```bash
# Install missing packages
pip install -r requirements.txt

# Or install each manually
pip install fastapi uvicorn tensorflow tensorflow-hub langchain langgraph langchain-google-genai python-dotenv
```

**Fix - Step 2: Verify .env File**

File location: `D:\FYP\after akilas model edit\python\.env`

Contents should have:
```
GOOGLE_API_KEY=AIzaSyBJa3K77pmPr6PpsScz7sQM0pn9yqPxX8o
```

If missing, create it!

**Fix - Step 3: Start Backend**
```bash
cd D:\FYP\after akilas model edit\python

# Option 1: Double-click start script
start_backend.bat

# Option 2: Manual start
python main.py
```

Expected output:
```
[*] Initializing FastAPI backend with YAMNet audio analysis...
[*] Initializing Digital Habits analyzer...
[*] Initializing Physical Activity analyzer (UCI HAR Dataset)...
[*] Initializing Recommendation Engine (LanGraph + Google Gemini)...
INFO:     Uvicorn running on http://0.0.0.0:8000
```

---

### Problem 3: Scores Not Generating (Audio, Digital, Physical)

**The Error:**
- You call `/analyze-audio`, `/analyze-digital-habits`, `/analyze-movement`
- Scores come back as 0 or empty

**Root Causes:**
1. Services didn't initialize properly
2. Models didn't load
3. Missing model files

**Fix:**

1. **Check backend is actually running:**
   ```bash
   curl http://localhost:8000/health
   ```
   
   Should return:
   ```json
   {
     "status": "OK",
     "message": "FastAPI backend is running successfully!",
     "port": 8000
   }
   ```

2. **Check service initialization logs:**
   - Look for errors in the console where you started `python main.py`
   - Each service should print initialization message
   - If you see `[ERROR]`, service failed to load

3. **Common issues:**
   - **YAMNet not loading**: Need TensorFlow Hub internet connection
   - **Random Forest model missing**: Check if model file exists in assets/models/
   - **Gemini API key wrong**: Check .env file, regenerate at https://ai.google.dev/

---

## 🔧 Quick Checklist

Before debugging further, verify:

- [ ] Python installed: `python --version`
- [ ] In correct folder: `cd D:\FYP\after akilas model edit\python`
- [ ] .env file exists with GOOGLE_API_KEY
- [ ] All packages installed: `pip install -r requirements.txt`
- [ ] Diagnostic passes: `python diagnose_backend.py`
- [ ] Backend starts: `python main.py`
- [ ] Health check works: `curl http://localhost:8000/health`
- [ ] ngrok uses port 8000: `ngrok http 8000`

---

## 🚀 Correct Startup Sequence

### Terminal 1 - Start Backend
```bash
cd D:\FYP\after akilas model edit\python
python main.py

# Expected output:
# [*] Initializing FastAPI backend...
# [*] Initializing Digital Habits analyzer...
# [*] Initializing Physical Activity analyzer...
# [*] Initializing Recommendation Engine...
# INFO: Uvicorn running on http://0.0.0.0:8000
```

### Terminal 2 - Start ngrok (after backend is running)
```bash
ngrok http 8000

# Expected output:
# Session Status        online
# Forwarding            https://xxxx-yyyy-zzzz.ngrok-free.dev -> http://localhost:8000
```

### Terminal 3 - Test Backend
```bash
# Test health
curl http://localhost:8000/health

# Test recommendations
curl -X POST http://localhost:8000/get-recommendations \
  -H "Content-Type: application/json" \
  -d '{"audio_score": 45, "digital_score": 55, "physical_score": 40}'
```

---

## 📱 Mobile App Configuration

### After backend is running and ngrok is active:

```dart
import 'package:student_stress_app/services/backend_service.dart';

void main() async {
  final backend = BackendService();
  await backend.initialize();
  
  // Option 1: Localhost (emulator)
  // await backend.switchToLocalhost();  // Default for emulator
  
  // Option 2: ngrok
  await backend.switchToNgrok('https://xxxx-yyyy-zzzz.ngrok-free.dev');
  
  // Test connection
  bool healthy = await backend.isHealthy();
  print(healthy ? '✅ Connected' : '❌ Disconnected');
}
```

---

## 🆘 Still Broken? Troubleshooting

### Backend shows: `ModuleNotFoundError: No module named 'tensorflow'`
```bash
pip install tensorflow tensorflow-hub
```

### Backend shows: `ImportError: cannot import name 'CORSMiddleware'`
```bash
pip install fastapi
```

### Backend shows: `ImportError: cannot import name 'ChatGoogleGenerativeAI'`
```bash
pip install langchain-google-genai
```

### ngrok says "Failed to connect to backend"
1. Is backend running? Check Terminal 1
2. Backend on port 8000? Check `python main.py` output
3. Run: `ngrok http 8000` (NOT 80!)

### Mobile app gets "Connection refused"
1. Backend running? `curl http://localhost:8000/health`
2. ngrok tunnel active? Check Terminal 2
3. Using correct ngrok URL in app?

### Scores are 0 or empty
1. Check backend logs for service initialization errors
2. Is GOOGLE_API_KEY valid? Test at https://ai.google.dev/
3. Run diagnostic: `python diagnose_backend.py`

---

## 📋 Port Reference

| Service | Port | URL |
|---------|------|-----|
| FastAPI Backend | 8000 | http://localhost:8000 |
| Android Emulator sees as | 8000 | http://10.0.2.2:8000 |
| ngrok tunnel to | 8000 | ngrok http 8000 → https://xxxx.ngrok-free.dev |
| ❌ DO NOT use | 80 | This is system port, needs admin |

---

**Remember: The error message shows `localhost:80` but you need `localhost:8000`!**

