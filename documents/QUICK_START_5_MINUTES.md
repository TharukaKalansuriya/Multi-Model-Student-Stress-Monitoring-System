# 🚀 GET STARTED NOW (5 MINUTES)

## Step 1: Get API Key (2 min)

1. Open: https://ai.google.dev/
2. Click **"Get API key"** button
3. Click **"Create API key in Google Cloud"**
4. Copy your key (looks like: `AIzaSy...`)

✅ **Done!** (No credit card needed)

---

## Step 2: Create .env File (1 min)

**File Path:** `D:\FYP\New folder\python\.env`

**Content:**
```
GOOGLE_API_KEY=your-api-key-from-step-1
```

Replace `your-api-key-from-step-1` with your actual key.

**⚠️ IMPORTANT:**
```
Add to .gitignore:
.env
```

---

## Step 3: Install Packages (2 min)

```bash
conda activate stress_model
pip install -r requirements.txt
```

---

## Step 4: Start Backend

```bash
conda activate stress_model
cd "D:\FYP\New folder\python"
python main.py
```

**Expected Output:**
```
[*] Initializing Recommendation Engine (LanGraph + Google Gemini)...
[OK] Recommendation Service initialized
[OK] FastAPI backend running on http://localhost:8000
```

---

## Step 5: Test It Works

**In another terminal:**

```bash
python test_system.py
```

This will test:
- ✅ Backend connection
- ✅ AI recommendations
- ✅ Random Forest model

---

## Step 6: Use in Mobile App

Send 3 scores to get recommendations:

```dart
final response = await http.post(
  Uri.parse("http://localhost:8000/get-recommendations"),
  headers: {"Content-Type": "application/json"},
  body: jsonEncode({
    "audio_score": 45,      // 0-100
    "digital_score": 60,    // 0-100
    "physical_score": 35    // 0-100
  }),
);
```

Response includes 3 personalized recommendations! 🎉

---

## 📊 Example Response

```json
{
  "recommendations": [
    {
      "title": "Phone Disconnect Challenge",
      "action": "Put your phone in another room for 30 minutes",
      "duration": "30 minutes",
      "benefit": "Reduces digital stress",
      "priority": "high"
    },
    {
      "title": "Disable Notifications",
      "action": "Turn off non-essential notifications",
      "duration": "10 minutes",
      "benefit": "Less interruptions",
      "priority": "high"
    },
    {
      "title": "Evening Tech Curfew",
      "action": "No screens 30 min before bed",
      "duration": "30 minutes daily",
      "benefit": "Better sleep",
      "priority": "medium"
    }
  ]
}
```

---

## 🆓 Free Tier

- ✅ 60 requests/minute
- ✅ No credit card
- ✅ Perfect for your app

---

## ❓ Troubleshooting

| Problem | Solution |
|---------|----------|
| Backend won't start | `pip install -r requirements.txt` |
| API key error | Check `.env` file has correct key |
| Slow response | Gemini takes 2-3s (normal) |
| No recommendations | Check internet connection |

---

## 📚 Full Docs

- **Complete Setup:** `LANGGRAPH_GEMINI_SETUP_GUIDE.md`
- **ML Model:** `RANDOM_FOREST_INTEGRATION_GUIDE.md`
- **Architecture:** `COMPLETE_IMPLEMENTATION_SUMMARY.md`

---

## ✅ What You Have Now

- **Random Forest**: 92.4% activity detection
- **YAMNet**: Audio analysis
- **Digital Behavior**: Phone usage scoring
- **Google Gemini**: AI-powered recommendations
- **LanGraph**: Intelligent orchestration

**Status: READY TO USE! 🚀**
