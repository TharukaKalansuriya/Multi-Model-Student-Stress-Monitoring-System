# 📋 Quick Reference Card - Mobile App & Backend Connection

### 🚀 Start Backend
```bash
cd D:\FYP\after akilas model edit\python
python main.py
# Backend runs on: http://localhost:8000
```

### 📱 Mobile App Setup

#### Option 1: Android Emulator (DEFAULT - No Config!)
- Already uses: `http://10.0.2.2:8000`
- Just run the app!

#### Option 2: Physical Device on Same WiFi
```dart
await backend.switchToPhysicalDevice('192.168.1.100');
```

#### Option 3: ngrok Remote
```dart
// Pre-configured for default ngrok URL
await backend.switchToNgrok();

// Or custom ngrok URL
await backend.switchToNgrok('https://custom.ngrok-free.dev');
```

### 🧪 Test Everything
```bash
python test_complete_system.py
```

---

## 🔗 Key Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Check if backend is running |
| `/config` | GET | View backend configuration |
| `/get-recommendations` | POST | Get stress recommendations |
| `/analyze-audio` | POST | Analyze audio file |
| `/analyze-digital-habits` | POST | Analyze phone usage |
| `/analyze-movement` | POST | Analyze physical activity |

---

## 📊 Quick Test

```bash
# Check backend
curl http://localhost:8000/health

# Get recommendations
curl -X POST http://localhost:8000/get-recommendations \
  -H "Content-Type: application/json" \
  -d '{"audio_score": 45, "digital_score": 55, "physical_score": 40}'
```

---

## 📱 Mobile App Methods

```dart
final backend = BackendService();
await backend.initialize();

// Switch connections
await backend.switchToLocalhost();
await backend.switchToPhysicalDevice('192.168.1.100');
await backend.switchToNgrok();

// Check connection
bool healthy = await backend.isHealthy();

// Get recommendations
final recommendations = await backend.getRecommendations(
  audioScore: 45,
  digitalScore: 55,
  physicalScore: 40,
);
```

---

## 🎯 Stress Score Ranges

| Score | Audio | Digital | Physical |
|-------|-------|---------|----------|
| 0-25° | Quiet ✅ | Healthy ✅ | Active ✅ |
| 25-50° | Normal | Normal | Moderate |
| 50-75° | Loud ⚠️ | Excessive ⚠️ | Sedentary ⚠️ |
| 75-100° | Very Loud 🔴 | Addiction 🔴 | Very Sedentary 🔴 |

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| "Connection refused" | Start: `python main.py` |
| Emulator fails | Using 10.0.2.2:8000? |
| Physical device fails | Same WiFi? Correct IP? |
| ngrok broken | Generate new: `ngrok http 8000` |

---

## ✅ Verification Checklist

- [ ] Backend running: `python main.py`
- [ ] Health check: `curl http://localhost:8000/health`
- [ ] All tests: `python test_complete_system.py`
- [ ] App connects
- [ ] Recommendations dynamic

---

## 📚 Full Documentation

- [SYSTEM_SETUP_SUMMARY.md](SYSTEM_SETUP_SUMMARY.md)
- [CONNECTION_SETUP_GUIDE.md](CONNECTION_SETUP_GUIDE.md)
- [DYNAMIC_RECOMMENDATIONS_GUIDE.md](DYNAMIC_RECOMMENDATIONS_GUIDE.md)

---

**Last Updated: April 19, 2026 - All Systems Working ✅**

**Expected Output:**
```
[*] Initializing Recommendation Engine...
INFO:     Uvicorn running on http://127.0.0.1:8000
```

**⚠️ DO NOT CLOSE THIS TERMINAL!**

---

## 🧪 5. TEST BACKEND (New PowerShell)

**PowerShell Terminal 2:**
```bash
# Health check
curl http://localhost:8000/health

# Test recommendations
$body = @{
    audio_score = 45
    digital_score = 60
    physical_score = 35
} | ConvertTo-Json

curl -Method Post `
  -Uri http://localhost:8000/get-recommendations `
  -ContentType "application/json" `
  -Body $body
```

**Expected:** JSON response with 3 recommendations

---

## 📍 6. GET YOUR PC'S IP ADDRESS

**PowerShell Terminal 2:**
```bash
ipconfig
```

**Look for:** `IPv4 Address . . . : 192.168.x.x`

**Copy this IP** → Use in Flutter app

---

## 📱 7. CONFIGURE FLUTTER APP

**File:** `lib/services/backend_service.dart`

```dart
class BackendService {
  // Replace 192.168.1.100 with YOUR_PC_IP from Step 6
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

---

## 🎮 8. RUN FLUTTER APP

**PowerShell Terminal 3:**
```bash
cd "D:\FYP\New folder\student_stress_app"
flutter run
```

**Ensure:** Terminal 1 (backend) is still running!

---

## 📊 API ENDPOINT REFERENCE

### POST /get-recommendations ⭐ **NEW**

**Request:**
```json
{
  "user_id": "student_001",
  "audio_score": 45,
  "digital_score": 60,
  "physical_score": 35
}
```

**Response:**
```json
{
  "status": "Success",
  "scores": {
    "audio": 45,
    "digital": 60,
    "physical": 35,
    "average": 46.7
  },
  "stress_analysis": {
    "level": "moderate",
    "category": "Stress levels are normal, but watch out for patterns",
    "primary_stressor": "digital"
  },
  "recommendations": [
    {
      "title": "Phone Disconnect Challenge",
      "action": "Put your phone in another room for 30 minutes",
      "duration": "30 minutes",
      "benefit": "Breaks phone usage habit, reduces digital stress",
      "motivation": "You'll be amazed at your focus!",
      "priority": "high"
    },
    {...},
    {...}
  ],
  "generated_at": "2026-04-18T14:30:45"
}
```

---

## 🔗 OTHER ENDPOINTS

### POST /analyze-audio
```
Input: WAV file (multipart/form-data)
Output: audio_score (0-100)
```

### POST /analyze-digital-habits
```
Input: {"app_usage": {...}, "screen_time": 240, ...}
Output: digital_score (0-100)
```

### POST /physical_activity
```
Input: {"sensor_data": [...]}
Output: physical_score (0-100)
```

### GET /health
```
Input: None
Output: System status + available endpoints
```

---

## ⚡ QUICK TROUBLESHOOTING

| Problem | Fix |
|---------|-----|
| `ModuleNotFoundError` | `pip install -r requirements.txt` |
| `Port 8000 in use` | `netstat -ano \| findstr :8000` then `taskkill /PID <PID> /F` |
| `GOOGLE_API_KEY not found` | Create .env file (Step 2) with your key |
| `Connection refused` | Check backend running on Terminal 1 |
| `Invalid IP in Flutter` | Run `ipconfig` to get correct IPv4 address |
| `Gemini returns error` | Check .env file has valid key |
| `Slow recommendations` | Normal (2-3 sec) - Gemini API speed |

---

## 📋 CHECKLIST

- [ ] Got Gemini API key from https://ai.google.dev/
- [ ] Created `.env` file with GOOGLE_API_KEY
- [ ] Ran `python verify_setup.py` (all green ✅)
- [ ] Backend running: `python main.py`
- [ ] Got PC IP: `ipconfig` → IPv4 Address
- [ ] Updated Flutter with correct backend URL
- [ ] Flutter app connects and gets recommendations
- [ ] See 3 recommendations generated by Gemini

---

## 🎯 YOUR ARCHITECTURE

```
Flutter App
    ↓
[Audio] [Digital] [Physical] scores
    ↓ (POST to backend)
http://YOUR_PC_IP:8000/get-recommendations
    ↓
Backend FastAPI
    ↓
LanGraph Workflow
  Node 1: Analyze scores
  Node 2: Classify stress
  Node 3: Call Gemini
    ↓
Google Gemini LLM
    ↓
3 Personalized Recommendations
    ↓
Return to Flutter
    ↓
Display to Student ✨
```

---

## 📞 PERFORMANCE SPECS

| Component | Speed | Accuracy | Cost |
|-----------|-------|----------|------|
| Audio (YAMNet) | ~2s | 521 classes | FREE |
| Digital (Rules) | <1ms | n/a | FREE |
| Physical (RF) | <1ms | 92.4% | FREE |
| Recommendations | 2-3s | Student-friendly | **FREE** |
| **Total** | **5-6s** | **Comprehensive** | **$0/month** |

---

## 🔐 SECURITY NOTES

- ✅ Gemini API key in `.env` (not in code)
- ✅ Add `.env` to `.gitignore` before committing
- ✅ Don't share API key in messages/Discord
- ✅ Local processing for audio/digital/physical (privacy)
- ✅ Only recommendations go through Gemini (no personal data)

---

## 📞 SUPPORT RESOURCES

**Official Docs:**
- FastAPI: https://fastapi.tiangolo.com/
- LanGraph: https://python.langchain.com/docs/langgraph/
- Google Gemini: https://ai.google.dev/documentation
- Flutter HTTP: https://pub.dev/packages/http

**Project Guides:**
- Full Setup: `INTEGRATION_SETUP_GUIDE.md`
- Step-by-Step: `STEP_BY_STEP_SETUP.md`
- Architecture: `COMPLETE_IMPLEMENTATION_SUMMARY.md`
- Gemini Setup: `LANGGRAPH_GEMINI_SETUP_GUIDE.md`

---

## 🚀 READY? START HERE:

```bash
# Terminal 1: Start Backend
cd "D:\FYP\New folder\python"
conda activate stress_model
python main.py

# Terminal 2: Get your IP
ipconfig

# Terminal 3: Run Flutter
cd "D:\FYP\New folder\student_stress_app"
flutter run
```

🎉 **DONE!** Your stress detection app is live!
