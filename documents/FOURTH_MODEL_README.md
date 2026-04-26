# Fourth Model: Physical Activity & Movement-Based Stress Detection
**Random Forest Classifier on UCI HAR Dataset**

---

## 📋 Overview

The **Fourth Model** analyzes physical activity patterns using accelerometer and gyroscope sensor data to detect movement-based stress indicators. It uses a **Random Forest classifier** trained on the **UCI Human Activity Recognition (HAR) Dataset**.

### Key Features:
- **Model Type:** Random Forest (100 estimators, depth=20)
- **Dataset:** UCI HAR - 30 volunteers, 7,352 samples, 561 features
- **Accuracy:** ~91.1% on test set
- **Activities Detected:** 6 types (Walking, Stairs, Sitting, Standing, Laying)
- **Stress Factors:** Activity type, intensity, pattern regularity, sedentary time

---

## 🗂️ Dataset: UCI HAR

**Location:** `D:\FYP\New folder\student_stress_app\assets\UCI-HAR Dataset`

**Source:** 
- Smartlab - Non-Linear Complex Systems Laboratory (University of Genoa)
- 30 volunteers (19-48 years old)
- Samsung Galaxy S II smartphone (accelerometer + gyroscope at 50Hz)

**Activities Recorded:**
```
1. WALKING            → Score: 35° (Moderate stress)
2. WALKING_UPSTAIRS   → Score: 45° (Moderate-high stress)
3. WALKING_DOWNSTAIRS → Score: 40° (Moderate stress)
4. SITTING            → Score: 25° (Low stress)
5. STANDING           → Score: 30° (Low-moderate stress)
6. LAYING             → Score: 15° (Very low stress)
```

**Dataset Structure:**
```
UCI-HAR Dataset/
├── train/
│   ├── X_train.txt          (7,352 samples × 561 features)
│   ├── y_train.txt          (7,352 activity labels)
│   ├── subject_train.txt    (Subject IDs)
│   └── Inertial Signals/    (Raw sensor readings)
├── test/
│   ├── X_test.txt           (2,947 samples × 561 features)
│   ├── y_test.txt           (2,947 activity labels)
│   └── Inertial Signals/
├── activity_labels.txt
├── features.txt
└── README.txt
```

---

## 🔧 Architecture: Mobile + Backend

### Mobile (Flutter) - Data Collection
**File:** `lib/services/physical_activity_service.dart`

**Responsibilities:**
- Collect accelerometer readings (X, Y, Z axes) - m/s²
- Collect gyroscope readings (X, Y, Z axes) - rad/s
- Track activity history (recent activity sequence)
- Record sitting duration
- Send JSON to backend

**Sensor Data Flow:**
```
Phone Sensors (50Hz)
    ↓
[acc_x, acc_y, acc_z, gyro_x, gyro_y, gyro_z]
    ↓
HTTP POST → Backend
```

### Backend (Python) - ML Processing
**File:** `python/physical_activity_service.py`

**Responsibilities:**
- Load UCI HAR training data (7,352 samples, 561 features)
- Train Random Forest classifier
- Extract/normalize features from sensor data
- Predict activity type
- Calculate stress score based on:
  - Base activity score (15-45°)
  - Movement intensity (0-100)
  - Pattern regularity (0-100)
  - Sedentary time modifiers
  - Irregular pattern penalties

**Processing Pipeline:**
```
Sensor Data (JSON)
    ↓
Feature Extraction (normalize to 561 dims)
    ↓
Random Forest Prediction
    ↓
Activity Classification (6 classes)
    ↓
Stress Score Calculation
    ↓
JSON Response with Score + Recommendations
```

---

## 📊 Stress Score Calculation

### Base Activity Score (Primary Factor)
Each activity has an inherent stress score:
```
LAYING                15°  ← Rest/Sleep (lowest stress)
SITTING               25°  ← Sedentary
STANDING              30°  ← Alert but still
WALKING               35°  ← Normal mobility
WALKING_DOWNSTAIRS    40°  ← More exertion
WALKING_UPSTAIRS      45°  ← High exertion (highest)
```

### Modifiers Applied

**1. Movement Intensity (0-100)**
- Calculated from acceleration magnitude
- Higher intensity = higher stress (if irregular pattern)
- Range: 0 (stationary) to 100 (vigorous activity)

**2. Pattern Regularity (0-100)**
- Analyzes activity history transitions
- 100 = predictable patterns
- <40 = chaotic/irregular patterns (stress indicator)
- Penalty: +15-25° for irregular patterns

**3. Sedentary Time**
- Sitting >60 minutes = adds penalty
- +20° for prolonged sitting

**4. Activity Changes**
- Frequent activity switches = chaos indicator
- High variance = stress

### Final Score Formula
```
physical_stress_score = base_activity_score + modifiers
  where modifiers include:
    - intensity bonus/penalty
    - regularity adjustment
    - sedentary penalty
    - pattern chaos penalty

Result: 0-100° scale
```

---

## 🎯 API Endpoint: `/analyze-movement`

### Request (HTTP POST)
```json
{
  "user_id": "student_001",
  "acc_x": 0.5,           // m/s² (accelerometer X)
  "acc_y": 9.8,           // m/s² (accelerometer Y)
  "acc_z": 0.3,           // m/s² (accelerometer Z)
  "gyro_x": 0.01,         // rad/s (gyroscope X)
  "gyro_y": 0.02,         // rad/s (gyroscope Y)
  "gyro_z": 0.01,         // rad/s (gyroscope Z)
  "activity_history": ["SITTING", "SITTING", "STANDING", "WALKING"],
  "sitting_duration_minutes": 45
}
```

### Response (HTTP 200)
```json
{
  "status": "Success",
  "activity": "WALKING",
  "activity_score": 35,
  "movement_intensity": 65,      // 0-100
  "pattern_regularity": 85,      // 0-100
  "physical_stress_score": 42,   // FINAL SCORE (0-100°)
  "stress_level": "Normal",
  "components": {
    "activity": "WALKING",
    "intensity": 65,
    "regularity": 85
  },
  "recommendations": [
    "Great! You're being active",
    "Stay hydrated with high activity"
  ],
  "model": "Random Forest (UCI HAR Dataset)"
}
```

---

## 🚀 Integration in FYP

### Four-Model System

The student stress app now uses **4 complementary ML models:**

| Model # | Name | Technology | Input | Output | Location |
|---------|------|-----------|-------|--------|----------|
| 1️⃣ | Environmental Stress | YAMNet (Google) | 10s audio | Score 0-100° | Python backend |
| 2️⃣ | Behavioral Stress | Threshold-based | Phone unlocks/day | Score 0-100° | Python backend |
| 3️⃣ | Digital Stress | Digital Habits | Screen time, apps, calls | Score 0-100° | Python backend |
| 4️⃣ | Physical Stress | Random Forest (UCI) | Accelerometer + Gyroscope | Score 0-100° | Python backend |

### Multi-Modal Fusion
```
AGGREGATE SCORE = (Audio + Behavioral + Digital + Physical) / 4
Result: Single 0-100° stress indicator
```

---

## 📱 Mobile Integration

### In-App Flow:
1. **Collect**: App gathers sensor data every 30 seconds
2. **Package**: Accelerometer + Gyroscope + Activity history
3. **Send**: HTTP POST to `/analyze-movement` endpoint
4. **Display**: Show activity + score in UI
5. **Store**: Save locally in SharedPreferences
6. **Aggregate**: Include in `/sync-all` for final score

### New UI Card
```
┌────────────────────────────────┐
│ PHYSICAL ACTIVITY ANALYSIS     │
├────────────────────────────────┤
│ Current Activity: 🚶 WALKING   │
│ Intensity: 65%  │ Pattern: 85% │
│ Score: 42°(Normal)             │
├────────────────────────────────┤
│ [Analyze Movement →]           │
│ 💡 Recommendations:            │
│ • Stay hydrated                │
│ • Maintain activity level      │
└────────────────────────────────┘
```

---

## 🔬 Technical Details

### Random Forest Model
- **Estimators:** 100 trees
- **Max Depth:** 20 levels
- **Features:** 561 (scikit-learn StandardScaler normalized)
- **Algorithm:** CART (Classification and Regression Trees)
- **Training Data:** 7,352 samples from 30 subjects
- **Test Accuracy:** ~91.1%

### Feature Extraction
The UCI HAR dataset includes 561 pre-computed features:
- **Time domain:** Mean, std, min, max, energy, entropy, etc.
- **Frequency domain:** FFT coefficients, dominant frequencies
- **Component statistics:** Per accelerometer/gyroscope axis

In the mobile app, we send raw sensor data which the backend processes through the same feature space.

---

## 📈 Stress Interpretation

| Score Range | Level | Meaning |
|-------------|-------|---------|
| 0-25° | 🟢 Low | Good activity patterns, healthy movement |
| 25-50° | 🟡 Normal | Typical daily movement, balanced |
| 50-75° | 🟠 Elevated | Irregular patterns, too much sitting, or intense activity |
| 75-100° | 🔴 High | Chaotic movement patterns, sedentary, high stress |

---

## 💡 Use Cases

### Student Sleep/Wake Cycle
- Morning (6-9am): Walking, stairs → Score ↑ (commute activity)
- Day (9-17): Sitting, standing → Score ↓ (classes)
- Evening (17-20): Walking → Score ↓ (commute back)
- Night (20-6): Laying → Score ✓ (rest)

### Stress Detection Example
- **Normal day:** Score = 35° (varied activities, regular patterns)
- **High stress day:** Score = 72° (chaotic patterns, much sitting, no breaks)
- **Exercise day:** Score = 40° (high intensity but regular = positive)

### Recommendations Generated
- "Consider standing up or taking a short walk every hour"
- "Frequent posture changes detected - work on staying seated actively"
- "High activity detected - stay hydrated"
- "Try to maintain a regular activity pattern"

---

## 🎓 For FYP Report

### Model Justification
The UCI HAR dataset is ideal because:
1. ✅ Real-world smartphone sensor data (Samsung Galaxy S II)
2. ✅ Well-balanced dataset (30 subjects, 6 activities)
3. ✅ High accuracy (91%+) on benchmark tasks
4. ✅ Public dataset (standardized, reproducible)
5. ✅ Relevant to student daily activities
6. ✅ Captures different movement states

### Contribution Statement
"The fourth model adds **physical activity analysis** to the stress detection system. Using Random Forest on the UCI HAR dataset, it detects six daily activities (walking, stairs, sitting, standing, laying) and calculates stress based on movement patterns. This complements the audio (environmental), behavioral (phone usage), and digital habit (screen time) models to create a comprehensive multi-modal stress assessment."

---

## 📝 Summary

✅ **Model:** Random Forest (UCI HAR Dataset)  
✅ **Input:** Accelerometer + Gyroscope + Activity history  
✅ **Output:** Physical stress score (0-100°) + Activity type  
✅ **Accuracy:** ~91% on UCI HAR benchmark  
✅ **Integration:** Backend `/analyze-movement` endpoint  
✅ **UI:** Physical Activity Analytics card in Flutter app  
✅ **Use:** Complement 3 other models for holistic stress assessment  
