# 🚀 Quick Start: Running Mobile App with Trained Model

## ⏱️ 5-Minute Setup

### Step 1: Open PowerShell & Activate Environment
```powershell
conda activate stress_model
```

### Step 2: Start Backend
```powershell
cd "D:\FYP\New folder\python"
python main.py
```

**Expected Output:**
```
[*] Initializing Physical Activity Service (Trained Random Forest Model)...
  [OK] Random Forest model loaded successfully
  [OK] Model ready for real-time predictions
[OK] FastAPI backend running on http://localhost:8000
```

### Step 3: In Another Terminal, Start Mobile App
```powershell
cd "D:\FYP\New folder\student_stress_app"
flutter run
```

### ✅ Done!
- Mobile app connects to backend
- Backend uses trained Random Forest model
- Predictions sent to app
- Stress scores displayed with recommendations

---

## 📊 Model Details at a Glance

| Feature | Value |
|---------|-------|
| **Algorithm** | Random Forest (100 trees) |
| **Accuracy** | 92.4% (vs 70% heuristic) |
| **Activities** | 6 (WALKING, SITTING, STANDING, etc.) |
| **Model Size** | 1.11 MB |
| **Prediction Time** | <1ms |
| **Training Data** | 7,352 samples from UCI HAR |

---

## 🔧 Troubleshooting Quick Fixes

**Backend won't start?**
```bash
pip install -r requirements.txt
```

**Model not loading?**
```bash
# Verify model exists
ls "D:\FYP\New folder\student_stress_app\assets\models\uci_har_random_forest.pkl"
```

**Module not found?**
```bash
conda activate stress_model
pip install scikit-learn joblib
```

---

## 📁 Key Files

- **Backend:** `D:\FYP\New folder\python\main.py`
- **Model:** `D:\FYP\New folder\student_stress_app\assets\models\uci_har_random_forest.pkl`
- **Mobile:** `D:\FYP\New folder\student_stress_app\lib\main.dart`
- **Full Guide:** `RANDOM_FOREST_INTEGRATION_GUIDE.md`

---

## 🎯 What You Get

✅ **92.4% accurate** activity detection (up from 70%)  
✅ **Real-time** stress scoring  
✅ **Personalized** recommendations  
✅ **No internet** required for predictions  
✅ **Production-ready** backend  

---

**Status:** Ready to use! 🚀
