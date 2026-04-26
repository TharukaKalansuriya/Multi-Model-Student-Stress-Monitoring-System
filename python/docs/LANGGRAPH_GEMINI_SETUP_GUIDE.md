# 🤖 LanGraph + Google Gemini Recommendation Engine - Setup Guide

## ✅ Installation Complete!

You now have a production-ready AI recommendation engine that generates personalized stress management advice based on your 3 stress scores.

---

## 🚀 Quick Setup (5 minutes)

### Step 1: Get Your Free Gemini API Key

1. Go to: **https://ai.google.dev/**
2. Click **"Get API Key"** button
3. Select or create a Google Cloud project
4. Copy your API key (looks like: `AIzaSy...`)
5. **That's it!** (No credit card needed)

### Step 2: Create .env File

**File:** `D:\FYP\New folder\python\.env`

```
GOOGLE_API_KEY=your-api-key-here
```

Replace `your-api-key-here` with your actual key from Step 1.

⚠️ **IMPORTANT:** Add `.env` to `.gitignore` so you don't accidentally commit your key to Github!

### Step 3: Start Backend

```bash
conda activate stress_model
cd "D:\FYP\New folder\python"
python main.py
```

Expected Output:
```
[*] Initializing Recommendation Engine (LanGraph + Google Gemini)...
[*] Recommendation Service initialized with Google Gemini
    Model: gemini-2.0-flash
    Free tier: 60 requests/minute
[OK] FastAPI backend running on http://localhost:8000
```

### Step 4: Test the Endpoint

Use this to test (replace URL if using ngrok):

```bash
curl -X POST http://localhost:8000/get-recommendations \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "student_001",
    "audio_score": 45,
    "digital_score": 60,
    "physical_score": 35
  }'
```

Or use Python:

```python
import requests

response = requests.post(
    "http://localhost:8000/get-recommendations",
    json={
        "user_id": "student_001",
        "audio_score": 45,
        "digital_score": 60,
        "physical_score": 35
    }
)

print(response.json())
```

---

## 📊 How It Works

### Architecture

```
Mobile App (Flutter)
    ↓
    Collects 3 stress scores
    ├─ Audio: 0-100 (environment)
    ├─ Digital: 0-100 (phone usage)
    └─ Physical: 0-100 (activity)
    ↓
Backend FastAPI (/get-recommendations)
    ↓
LanGraph Workflow
    ├─ Node 1: Analyze scores
    ├─ Node 2: Classify stress level
    └─ Node 3: Generate recommendations
    ↓
Google Gemini LLM
    (Generates intelligent recommendations)
    ↓
Response to App
    ├─ 3 specific, actionable recommendations
    ├─ Personalized to primary stressor
    └─ Includes time estimates & motivation
    ↓
Display in Mobile App
```

### Example Request

```json
{
  "user_id": "student_001",
  "audio_score": 45,      // Environmental stress
  "digital_score": 60,    // Phone usage stress
  "physical_score": 35    // Activity level stress
}
```

### Example Response

```json
{
  "status": "Success",
  "user_id": "student_001",
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
      "action": "Put your phone in another room for 30 minutes while you work/study",
      "duration": "30 minutes",
      "benefit": "Breaks phone usage habit, reduces digital stress",
      "motivation": "You'll be amazed at your focus!",
      "priority": "high"
    },
    {
      "title": "Disable Notifications",
      "action": "Turn off all non-essential notifications for 2 hours during study time",
      "duration": "10 minutes to set up",
      "benefit": "Removes constant digital interruptions",
      "motivation": "Reclaim your attention span",
      "priority": "high"
    },
    {
      "title": "Evening Tech Curfew",
      "action": "No screens 30 minutes before bed - read or journal instead",
      "duration": "30 minutes daily",
      "benefit": "Better sleep + reduced bedtime stress scrolling",
      "motivation": "You'll sleep better and feel less anxious",
      "priority": "medium"
    }
  ],
  "generated_by": "Google Gemini (LanGraph)",
  "model": "gemini-2.0-flash",
  "timestamp": "2026-04-17T14:30:45.123456"
}
```

---

## 📱 Integrate with Mobile App

### Add Endpoint to Flutter App

**File:** `lib/services/recommendation_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendationService {
  static const String baseUrl = "http://localhost:8000"; // or ngrok URL
  
  static Future<Map<String, dynamic>> getRecommendations({
    required int audioScore,
    required int digitalScore,
    required int physicalScore,
    String userId = "student_001",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/get-recommendations"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "audio_score": audioScore,
          "digital_score": digitalScore,
          "physical_score": physicalScore,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to get recommendations");
      }
    } catch (e) {
      print("Error: $e");
      rethrow;
    }
  }
}
```

### Use in Your Screen

```dart
// In your HomeScreen or StressAnalysisScreen
final recommendations = await RecommendationService.getRecommendations(
  audioScore: stressScores['audio_score'],
  digitalScore: stressScores['digital_score'],
  physicalScore: stressScores['physical_score'],
);

// Display recommendations
final recs = recommendations['recommendations'] as List;
for (var rec in recs) {
  print("${rec['priority']}: ${rec['title']}");
  print("Action: ${rec['action']}");
  print("Duration: ${rec['duration']}");
  print("Benefit: ${rec['benefit']}");
}
```

---

## 🔄 Workflow: From 3 Scores to Recommendations

### Step by Step

```
1. Mobile App collects/calculates:
   ├─ Audio Score (YAMNet model): 45°
   ├─ Digital Score (behavioral analysis): 60°
   └─ Physical Score (UCI HAR model): 35°

2. App sends to /get-recommendations endpoint:
   POST /get-recommendations
   {
     "audio_score": 45,
     "digital_score": 60,
     "physical_score": 35
   }

3. Backend LanGraph workflow triggers:
   
   Node 1 - ANALYZE:
   ├─ Read all 3 scores
   ├─ Calculate average: (45+60+35)/3 = 46.7°
   └─ Output: Scores analyzed
   
   Node 2 - CLASSIFY:
   ├─ Average score 46.7° → "moderate" level
   ├─ Identify max score: digital (60°)
   ├─ Primary stressor: "digital"
   └─ Output: Stress profile created
   
   Node 3 - GENERATE:
   ├─ Build context for Gemini:
   │  "Student has moderate stress
   │   Primary issue: digital/phone usage
   │   Environmental stress: 45° (moderate)
   │   Activity level: 35° (good)"
   ├─ Send to Gemini LLM:
   │  "Generate 3 recommendations for this student"
   └─ Output: 3 personalized recommendations
   
4. Gemini LLM Response:
   - Analyzes student profile
   - Generates 3 student-specific recommendations
   - Prioritizes digital habit reduction
   - Includes time estimates & motivation
   
5. Backend returns structured JSON:
   {
     "recommendations": [
       {"title": "Phone Disconnect Challenge", ...},
       {"title": "Disable Notifications", ...},
       {"title": "Evening Tech Curfew", ...}
     ]
   }

6. Mobile app displays recommendations:
   ├─ Shows in priority order (high → medium)
   ├─ Displays action, duration, benefit
   ├─ Tracks if user completes recommendations
   └─ Updates stress score after action taken
```

---

## 🎯 Stress Level Classifications

| Score | Level | Category | Action |
|-------|-------|----------|--------|
| < 30 | Low | "You're managing stress well" | Maintain current habits |
| 30-50 | Moderate | "Stress levels are normal" | Watch for patterns |
| 50-75 | High | "Stress is elevated" | Intervention recommended |
| > 75 | Critical | "Immediate management needed" | Take action today |

---

## 🔐 Security & Privacy

### API Key Safety
- ✅ Store in `.env` file (never in code)
- ✅ Add `.env` to `.gitignore`
- ✅ Never commit to Github
- ✅ Rotate key if accidentally exposed

### Free Tier Limits
- ✅ 60 requests/minute (plenty for your app)
- ✅ Unlimited daily calls
- ✅ No credit card required
- ✅ Perfect for student projects

---

## 🧪 Testing

### Test 1: Low Stress Profile
```bash
curl -X POST http://localhost:8000/get-recommendations \
  -d '{"audio_score": 20, "digital_score": 25, "physical_score": 30}'
```
Expected: "LOW STRESS" recommendations

### Test 2: High Stress Profile
```bash
curl -X POST http://localhost:8000/get-recommendations \
  -d '{"audio_score": 80, "digital_score": 85, "physical_score": 75}'
```
Expected: "CRITICAL" recommendations

### Test 3: Specific Stressor Focus
```bash
curl -X POST http://localhost:8000/get-recommendations \
  -d '{"audio_score": 10, "digital_score": 90, "physical_score": 20}'
```
Expected: Digital-focused recommendations

---

## 🐛 Troubleshooting

### Error: `ModuleNotFoundError: No module named 'langchain'`
```bash
conda activate stress_model
pip install langchain langgraph langchain-google-genai python-dotenv
```

### Error: `GOOGLE_API_KEY not found`
1. Create `.env` file in `D:\FYP\New folder\python\`
2. Add: `GOOGLE_API_KEY=your-key-here`
3. Restart backend

### Error: `Failed to generate recommendations`
1. Check internet connection
2. Verify API key is valid
3. Check quota: https://ai.google.dev/
4. Try again in a few seconds

### Fallback Mode (If Gemini Unavailable)
The service automatically falls back to pre-defined recommendations if:
- API key is invalid
- Network error occurs
- Gemini is down

Fallback recommendations are still high-quality based on primary stressor!

---

## 📊 Monitoring

### Check API Usage
Visit: https://ai.google.dev/ → View usage stats

### Log Analysis
Backend logs show:
```
[*] Analyzing stress scores...
[*] Generating recommendations with Gemini...
[OK] Generated 3 recommendations
```

---

## 📚 Files Created/Modified

**Created:**
- ✅ `recommendation_service.py` - LanGraph + Gemini integration
- ✅ `.env.template` - Template for API key

**Modified:**
- ✅ `main.py` - Added `/get-recommendations` endpoint
- ✅ `requirements.txt` - Added langchain, langgraph, langchain-google-genai

---

## 🎓 How LanGraph Works (Optional Reading)

LanGraph is a framework for building stateful multi-actor applications using LLMs.

In our case:
- **State:** 3 stress scores → classification → recommendations
- **Nodes:** Analysis → Classification → Generation
- **Edges:** Linear flow (analyze → classify → generate)
- **LLM:** Google Gemini for intelligent recommendation generation

Benefits:
- Clear workflow visibility
- Easy debugging (see which step failed)
- Scalable (easy to add steps later)
- Production-ready error handling

---

## 🚀 Next Steps

1. ✅ Get API key from Google AI
2. ✅ Create `.env` file with key
3. ✅ Start backend
4. ✅ Test `/get-recommendations` endpoint
5. ✅ Integrate into mobile app
6. ✅ Deploy to production

---

## 💡 Pro Tips

1. **Cache Recommendations:** Store in database if same scores appear
2. **A/B Testing:** Compare Gemini recommendations vs rule-based
3. **User Feedback:** Ask if recommendations helped → improve prompts
4. **Personalization:** Track which recommendations work best for each user
5. **Analytics:** Log all generated recommendations for students

---

## 📞 Support

- **Gemini Docs:** https://ai.google.dev/docs
- **LanGraph Docs:** https://langgraph.dev/
- **FastAPI Docs:** http://localhost:8000/docs (when running)

---

**Status:** ✅ Ready to Use!  
**Model:** Google Gemini 2.0 Flash  
**Framework:** LanGraph + Langchain  
**Free Tier:** 60 requests/minute  
**Last Updated:** April 17, 2026
