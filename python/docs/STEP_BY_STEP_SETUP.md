# 🎯 STEP-BY-STEP ACTION PLAN
**Student Stress App - Complete Integration**  
**Estimated Time: 15 minutes**

---

## ⏱️ PHASE 1: Get Gemini API Key (5 minutes)

### Task 1.1: Open Browser to Google AI Studio
```
👉 DO THIS NOW:
1. Open your browser (Chrome, Edge, Firefox)
2. Go to: https://ai.google.dev/
3. You should see: Google Gemini AI Studio
```

### Task 1.2: Click "Get API Key" Button
```
👉 LOOK FOR:
- Blue button labeled "Get API Key"
- In top right or center of page

👉 CLICK IT
- System will ask to sign in with Google account
- Use any Google account (personal or Gmail)
```

### Task 1.3: Create/Select Google Cloud Project
```
👉 CHOICE A - First Time:
- Click: "Create new project"
- Name: "Student Stress App" (or any name)
- Wait for project to create (~10 seconds)
- Gemini API auto-enables

👉 CHOICE B - Have Projects Before:
- Select: Your existing project OR create new
- Gemini API auto-enables
```

### Task 1.4: Copy Your API Key
```
👉 YOU'LL SEE:
- Section: "Your API Key"
- A long string starting with: AIzaSy...
- Copy button next to it

👉 ACTION:
- Click the "Copy" button
- Paste into Notepad to save temporarily
- Example format: AIzaSyD_mY_r3aL_kEy_ABC123XYZ789
```

### Task 1.5: Save API Key Securely
```
⚠️  IMPORTANT:
- Never share this key publicly
- Save it somewhere safe
- You'll use it in next step
```

✅ **Phase 1 Complete!** Got API key? Move to Phase 2.

---

## ⏱️ PHASE 2: Create .env File (1 minute)

### Task 2.1: Create File
```
👉 LOCATION:
D:\FYP\New folder\python\.env

👉 HOW TO CREATE:
1. Open Notepad
2. Type the content below
3. File → Save As
4. Name: .env
5. Save location: D:\FYP\New folder\python\
6. Type: All Files (not .txt!)
```

### Task 2.2: Add API Key Content
```
👉 COPY-PASTE THIS into Notepad:

GOOGLE_API_KEY=AIzaSy_YOUR_API_KEY_HERE_REPLACE_THIS

👉 REPLACE this part:
AIzaSy_YOUR_API_KEY_HERE_REPLACE_THIS

👉 WITH your actual key from Phase 1:
AIzaSyD_mY_r3aL_kEy_ABC123XYZ789
```

### Task 2.3: Verify File Created
```
👉 CHECK:
1. Open File Explorer
2. Navigate to: D:\FYP\New folder\python\
3. Look for file: .env
4. Double-click to verify it opens (should show your key)
```

✅ **Phase 2 Complete!** .env file ready. Move to Phase 3.

---

## ⏱️ PHASE 3: Verify System Setup (2 minutes)

### Task 3.1: Open PowerShell Terminal
```
👉 DO THIS:
1. Press: Windows + R
2. Type: powershell
3. Press: Enter

👉 YOU'LL SEE:
PowerShell window with blinking cursor
```

### Task 3.2: Run Verification Script
```
👉 IN POWERSHELL, TYPE:

cd "D:\FYP\New folder\python"
conda activate stress_model
python verify_setup.py

👉 PRESS: Enter

👉 YOU'LL SEE:
✅ Multiple green checkmarks for each component
```

### Task 3.3: Check Results
```
✅ ALL GREEN? Perfect! Go to Phase 4.

❌ ANY RED?
- .env file not found → Create it (Phase 2)
- Port 8000 in use → Kill process or restart PC
- Missing packages → Run pip install
- API key not set → Get new key (Phase 1)
```

✅ **Phase 3 Complete!** System verified. Move to Phase 4.

---

## ⏱️ PHASE 4: Start Backend Server (1 minute)

### Task 4.1: Launch Backend
```
👉 IN SAME POWERSHELL, TYPE:

python main.py

👉 YOU'LL SEE OUTPUT:
[*] Initializing FastAPI backend...
[*] Initializing Digital Habits analyzer...
[*] Initializing Physical Activity analyzer...
[*] Initializing Recommendation Engine (LanGraph + Gemini)...
INFO:     Uvicorn running on http://127.0.0.1:8000

👉 THIS MEANS: ✅ Backend is RUNNING!
```

### Task 4.2: DON'T CLOSE THIS TERMINAL
```
⚠️  IMPORTANT:
- Keep this PowerShell window OPEN
- Backend must keep running while you use the app
- Backend serves requests from your Flutter app
```

### Task 4.3: Keep Backend Running
```
👉 TO CHECK if backend is healthy:

Open NEW PowerShell window (don't close the backend one)

Type:
curl http://localhost:8000/health

You should see:
{
  "status": "Backend is running",
  "services": {...}
}
```

✅ **Phase 4 Complete!** Backend running. Move to Phase 5.

---

## ⏱️ PHASE 5: Get Your PC's Network IP (2 minutes)

### Task 5.1: Find Your PC's IP Address
```
👉 OPEN NEW POWERSHELL (keep backend running in other one)

Type:
ipconfig

👉 LOOK FOR:
"IPv4 Address . . . . . . . . . . : 192.168.x.x"

👉 COPY THIS ADDRESS
Example: 192.168.1.100

👉 THIS IS YOUR_PC_IP for mobile app connection
```

### Task 5.2: Note Important Info
```
Save for Flutter app configuration:
- Backend URL: http://192.168.1.100:8000
  (Replace 192.168.1.100 with YOUR_PC_IP from above)
  
- Available endpoints:
  • GET /health
  • POST /analyze-audio
  • POST /analyze-digital-habits  
  • POST /physical_activity
  • POST /get-recommendations ⭐ (NEW)
```

✅ **Phase 5 Complete!** IP address noted. Move to Phase 6.

---

## ⏱️ PHASE 6: Test Backend Endpoints (2 minutes)

### Task 6.1: Test Health Endpoint
```
👉 IN NEW POWERSHELL:

curl http://localhost:8000/health

👉 YOU'LL SEE:
{
  "status": "Backend is running",
  "services": {...}
}

✅ This confirms backend is responding
```

### Task 6.2: Test Recommendation Endpoint
```
👉 COPY THIS ENTIRE BLOCK:

$body = @{
    audio_score = 45
    digital_score = 60
    physical_score = 35
} | ConvertTo-Json

curl -Method Post `
  -Uri http://localhost:8000/get-recommendations `
  -ContentType "application/json" `
  -Body $body | ConvertTo-Json -Depth 10

👉 PASTE into PowerShell and press Enter

👉 YOU'LL SEE:
{
  "status": "Success",
  "scores": {...},
  "stress_analysis": {...},
  "recommendations": [
    {
      "title": "...",
      "action": "...",
      "duration": "...",
      "benefit": "...",
      "motivation": "...",
      "priority": "..."
    },
    {...},
    {...}
  ]
}

✅ This confirms recommendation engine working with Gemini!
```

✅ **Phase 6 Complete!** All endpoints tested. Move to Phase 7.

---

## ⏱️ PHASE 7: Configure Flutter App (3 minutes)

### Task 7.1: Update Backend URL in Flutter
```
👉 OPEN Flutter file:
lib/services/backend_service.dart

👉 ADD THIS CODE:
import 'package:http/http.dart' as http;
import 'dart:convert';

class BackendService {
  // UPDATE THIS with your PC's IP!
  static const String BACKEND_URL = 'http://192.168.1.100:8000';
  
  static Future<Map<String, dynamic>> getRecommendations({
    required int audioScore,
    required int digitalScore,
    required int physicalScore,
    String userId = 'student_001',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BACKEND_URL/get-recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'audio_score': audioScore,
          'digital_score': digitalScore,
          'physical_score': physicalScore,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get recommendations');
      }
    } catch (e) {
      print('Error: $e');
      return {'error': e.toString()};
    }
  }
}
```

### Task 7.2: Update Backend URL (IMPORTANT!)
```
👉 FIND THIS LINE:
static const String BACKEND_URL = 'http://192.168.1.100:8000';

👉 REPLACE 192.168.1.100 with YOUR_PC_IP from Phase 5

Example:
If your IP is 192.168.1.50:
static const String BACKEND_URL = 'http://192.168.1.50:8000';
```

### Task 7.3: Call in Your UI
```
👉 IN ANY SCREEN where you need recommendations:

// Example: In home_screen.dart
onPressed: () async {
  final result = await BackendService.getRecommendations(
    audioScore: 45,    // From your audio service
    digitalScore: 60,  // From your digital service  
    physicalScore: 35, // From your physical service
  );
  
  if (result.containsKey('recommendations')) {
    final recommendations = result['recommendations'];
    
    // Display on screen
    for (var rec in recommendations) {
      print('${rec['title']}');
      print('${rec['action']}');
      print('Duration: ${rec['duration']}');
    }
  }
}
```

✅ **Phase 7 Complete!** Flutter app configured. Move to Phase 8.

---

## ⏱️ PHASE 8: Test Mobile App Connection (2 minutes)

### Task 8.1: Make Sure Backend is Running
```
👉 BackendServer PowerShell should still be open
   (from Phase 4)

👉 If closed, restart it:
python main.py
```

### Task 8.2: Run Flutter App
```
👉 IN NEW TERMINAL (your Flutter project):

cd "D:\FYP\New folder\student_stress_app"
flutter run

👉 APP LAUNCHES on your device/emulator
```

### Task 8.3: Test Recommendation Call
```
👉 NAVIGATE to the page where you call backend

👉 TRIGGER the recommendation request
   (button press, data collection complete, etc.)

👉 SHOULD SEE:
- Recommendation engine prints in backend PowerShell
- 3 recommendations displayed in app
- Each with action, duration, benefit
```

### Task 8.4: Check Backend Logs
```
👉 IN BACKEND POWERSHELL, YOU'LL SEE:

[*] Getting recommendations for: student_001
    Audio Score: 45/100
    Digital Score: 60/100
    Physical Score: 35/100
[*] Analyzing stress scores...
    Audio Score: 45/100
    Digital Score: 60/100
    Physical Score: 35/100
    Average: 46.7/100
    Primary Stressor: DIGITAL
[*] Classifying stress level...
    Stress Level: MODERATE
    Category: Stress levels are normal...
[*] Generating recommendations with Gemini...
    [OK] Generated 3 recommendations
      1. Phone Disconnect Challenge (30 minutes)
      2. Disable Notifications (10 minutes to set up)
      3. Evening Tech Curfew (30 minutes daily)

✅ ALL WORKING!
```

✅ **Phase 8 Complete!** Connection tested and working!

---

## ✅ YOU'RE DONE! 

**Summary of What You've Accomplished:**

✅ Got Gemini API key (free tier)  
✅ Created .env file with API key  
✅ Verified all dependencies installed  
✅ Tested all system components  
✅ Started backend server  
✅ Configured Flutter app  
✅ Tested mobile app ↔ backend communication  
✅ Successfully generated recommendations!

---

## 🎯 Your System Workflow

```
STUDENT OPENS APP
    ↓
APP COLLECTS SENSOR DATA (3 sources)
    • Audio: 10-30 second recording
    • Digital: Phone usage stats
    • Physical: Accelerometer readings
    ↓
APP SENDS TO backend: http://YOUR_PC_IP:8000
    ↓
BACKEND ANALYZES (4 parallel steps)
    • YAMNet → audio_score (0-100)
    • Rule Engine → digital_score (0-100)
    • Random Forest → physical_score (0-100)
    • Combine scores
    ↓
BACKEND USES LANGGRAPH + GEMINI
    Step 1: Analyze scores
    Step 2: Classify stress level
    Step 3: Call Gemini LLM for intelligent recommendations
    ↓
BACKEND RETURNS 3 RECOMMENDATIONS
    • Title
    • Specific action
    • Time required
    • Why it helps
    • Motivation
    ↓
APP DISPLAYS BEAUTIFULLY
    • Shows stress gauge
    • Lists recommendations
    • Student can take action
  
✅ EVERYTHING WORKING TOGETHER!
```

---

## 🆘 If Something Goes Wrong

| Error | Solution |
|-------|----------|
| `.env not found` | Create file at `D:\FYP\New folder\python\.env` with `GOOGLE_API_KEY=...` |
| `Port 8000 in use` | Close other apps using port 8000 or restart PC |
| `API key invalid` | Get new key from https://ai.google.dev/ |
| `Connection refused` | Ensure backend running (`python main.py`) |
| `Different IP error` | Use correct YOUR_PC_IP from `ipconfig` |
| `Gemini rate limit` | Wait 1 minute (60 requests/min free tier) |

---

🚀 **YOU'RE READY TO DEPLOY YOUR STRESS APP!**

Next time: Just run backend and Flutter app - everything connects automatically!
