# Student Stress Detection App — Quick Reference Guide for FYP

## 📱 Mobile App Data Flow (Flutter)

### Audio Stress Detection Flow

```
Step 1: User taps "Record Audio" button
        ↓
Step 2: App starts recording for 10 seconds
        • Format: 16-bit PCM WAV
        • Sample Rate: 16 kHz
        • Channels: Mono (1)
        ↓
Step 3: Audio file saved (~320 KB)
        ↓
Step 4: File size validation (must be > 50 KB)
        ↓
Step 5: Upload to backend via HTTP POST
        • URL: https://backend/analyze-audio
        • Method: multipart/form-data
        ↓
Step 6: Wait for backend response
        • Audio Score: 0-100
        • Detected Sounds: {"Speech": 0.85, "Traffic": 0.62, ...}
        • Time: ~300ms
        ↓
Step 7: Extract detected sounds + calculate score
        • Dart formula: (∑confidence × weight) / ∑confidence × 100
        ↓
Step 8: Return stress score to home screen
```

### Behavioral Stress Detection Flow

```
App Lifecycle Detection:
  ├─ resumed → App came to foreground
  └─ Count as "unlock" (proxy for phone unlock)

Daily Counter:
  ├─ Stored in SharedPreferences
  ├─ Resets at midnight
  └─ Track first unlock timestamp

Score Calculation:
  ├─ unlocks_per_hour = daily_count / hours_elapsed
  ├─ behavioral_score = (unlocks_per_hour / 15) × 100
  └─ Clamped to 0-100

Example: 8 unlocks in 2 hours
  └─ 8 / 2 = 4 unlocks/hour
  └─ (4 / 15) × 100 = 26.67°
```

### Physical Activity Detection Flow

```
Accelerometer Monitoring:
  ├─ Continuous background check
  ├─ 2.56-second feature windows
  └─ Classification: Walking / Sitting / Lying

Stress Impact:
  ├─ Walking: ✓ Reduces risk by 5°
  ├─ Sitting/Lying: ✗ Increases risk after 60 mins
  └─ Max risk: 100°

Example Timeline:
  [00:00] Start sitting
  [01:00] Sitting for 60 mins → +10° risk
  [02:00] Still sitting → +10° risk (total 20°)
  [02:05] Start walking → -5° risk (total 15°)
  [02:06] Sitting again → reset timer
```

---

## 🔌 Backend API Quick Reference

### POST /analyze-audio
**Send audio file to YAMNet for analysis**

```
Request:
- Method: POST
- URL: /analyze-audio
- Content-Type: multipart/form-data
- Field: audio_file (WAV file)
- File Format: Mono, 16-bit PCM, 16000 Hz
- File Size: 50 KB - 5 MB

Response (200):
{
  "status": "Success",
  "audio_score": 48.93,
  "detected_sounds": {
    "Speech": 0.85,
    "Traffic": 0.62,
    "Ambient": 0.45
  },
  "top_detected_events": [
    {"class": "Traffic", "confidence": 0.62, "stress_weight": 85},
    {"class": "Speech", "confidence": 0.85, "stress_weight": 30},
    ...
  ],
  "model": "YAMNet (AudioSet)",
  "classes_detected": 3
}

Response (400):
{
  "detail": "Failed to analyze audio: [error message]"
}
```

### POST /sync
**Send scores and receive final stress calculation**

```
Request:
- Method: POST
- URL: /sync
- Content-Type: application/json
- Body: {
    "user_id": "student_123",
    "audio_score": 48.93,
    "behavioral_score": 26.67
  }

Response (200):
{
  "status": "Success",
  "final_stress": 36.60,
  "physical_context": "Sedentary for 45 mins"
}
```

### POST /physical_activity
**Update physical activity state**

```
Request:
- Method: POST
- URL: /physical_activity
- Content-Type: application/json
- Body: {
    "prediction": "Sitting"  // or "Walking", "Laying"
  }

Response (200):
{
  "status": "Activity Updated",
  "current_risk": 45
}
```

---

## 🧠 YAMNet Model Details

### What is YAMNet?

- **Name**: Yet Another MobileNet
- **Purpose**: Audio event classification
- **Training Dataset**: AudioSet (2M+ YouTube videos)
- **Classes**: 521 sound event categories
- **Model Size**: ~20 MB
- **Inference Speed**: ~100-300ms per 10-second audio on CPU
- **Accuracy**: High on AudioSet test set, good generalization

### What Can It Detect?

| Category | Examples | Count |
|----------|----------|-------|
| Speech | Speech, language variants, silence | ~46 classes |
| Music | Genres, instruments, singing | ~68 classes |
| Animals | Dog, cat, bird sounds | ~32 classes |
| Vehicles | Car, motorcycle, aircraft, train | ~51 classes |
| Weather | Rain, wind, thunder, hail | ~44 classes |
| Domestic | Appliances, household sounds | ~40 classes |
| Alerts | Siren, alarm, whistles | ~20 classes |
| Nature | Water, stream, ocean, forest | ~30 classes |
| Other | Crowd, footsteps, impact sounds | ~90 classes |

### Stress Weight Mapping

**High Stress (70-100):**
- Siren (100), Fire alarm (98), Gunshot (96), Screaming (95)
- Emergency vehicle (88), Crying (85), Traffic (85), Alarm (80)

**Medium Stress (40-70):**
- Car horn (75), Yelling (70), Motorcycle (60), Dog barking (60)
- Snoring (50), Coughing (45), Sneezing (40), Ambient (35)

**Low Stress (0-30):**
- Speech (30), Music (20), Wind (15), Rain (12)
- Laughter (10), Birds (10), Stream (8), Silence (0)

---

## 📊 Score Interpretation Guide

### Audio Stress Score
```
0-25°     → Quiet, calm environment
          └─ Detected: Silence, soft music, light ambient
25-50°    → Moderate background noise
          └─ Detected: Speech, ambient, some traffic
50-75°    → Noisy, disruptive environment
          └─ Detected: Traffic, loud speech, machinery
75-100°   → High noise, extreme stress
          └─ Detected: Sirens, alarms, emergencies
```

### Behavioral Score
```
0-20°     → Minimal phone engagement (focused)
          └─ <1 unlock per hour
20-40°    → Normal engagement
          └─ 2-5 unlocks per hour
40-60°    → High engagement/distraction
          └─ 6-10 unlocks per hour
60-80°    → Very high engagement/anxiety
          └─ 10-15 unlocks per hour
80-100°   → Extreme engagement/stress
          └─ 15+ unlocks per hour
```

### Physical Score
```
0-30°     → Active, moving around
          └─ Walking, exercise, activity
30-60°    → Moderate sedentary behavior
          └─ Sitting 30-60 minutes
60-100°   → High sedentary time
          └─ Sitting 2+ hours without movement
```

### Final Stress Score
```
0-30°     → Relaxed ✓
30-50°    → Calm ✓
50-70°    → Alert ⚠️
70-100°   → Stressed ⚠️⚠️
```

---

## 🔄 Complete Message Sequence

```
MINUTE 0:
┌─ User launches app
├─ BehavioralService registers for app lifecycle events
├─ PhysicalService starts background activity monitoring
└─ HomeScreen displays stress levels

MINUTE 5:
┌─ Backend /sync endpoint called
├─ Retrieves current scores (if available)
└─ Displays on screen

MINUTE 10:
┌─ User taps "Record Audio" button
├─ Audio starts recording (10 seconds)
└─ Flutter Sound plugin captures microphone

MINUTE 10.001:
┌─ Phone unlocks → BehavioralService detects app re-open
├─ Increments daily unlock count
└─ Logs unlock event

MINUTE 10.5:
┌─ Audio capture completes (320 KB WAV file)
├─ AudioStressService validates file size
├─ Prepares HTTP POST request with multipart audio
└─ Sends to backend

MINUTE 10.51:
┌─ Backend receives audio file
├─ YAMNet model (already loaded) processes audio
├─ Inference completes (~300ms)
├─ Detected sounds: Speech (0.85), Ambient (0.45), Traffic (0.62)
└─ Audio score calculated: 48.93°

MINUTE 10.52:
┌─ Flutter receives JSON response
├─ Extracts detected sounds
├─ Parses audio score: 48.93°
├─ Gets behavioral score from SharedPreferences: 26.67°
└─ Prepares /sync request

MINUTE 10.53:
┌─ /sync request sent to backend
├─ Includes: audio_score=48.93, behavioral_score=26.67
├─ Backend adds physical_risk=34.20 (from memory)
├─ Calculates: (48.93 + 26.67 + 34.20) / 3 = 36.60°
└─ Returns final stress: 36.60°

MINUTE 10.54:
┌─ Flutter receives final stress score
├─ Updates UI: "Current Stress: 36.60°"
├─ Displays detected sounds list
└─ User sees complete stress analysis
```

---

## 🛠️ Technology Stack Summary

| Layer | Component | Technology | Language |
|-------|-----------|-----------|----------|
| **Presentation** | Mobile UI | Flutter | Dart |
| **Data Capture** | Audio | flutter_sound_lite | Plugin |
| **Data Capture** | Motion | phone_sensors | Plugin |
| **Local Storage** | Preferences | shared_preferences | Plugin |
| **Networking** | HTTP Client | http package | Dart |
| **Business Logic** | Audio Service | AudioStressService | Dart |
| **Business Logic** | Behavioral Service | BehavioralService | Dart |
| **Inference API** | REST Endpoint | FastAPI | Python |
| **ML Model** | YAMNet | TensorFlow Hub | SavedModel |
| **Server** | ASGI | Uvicorn | Python |
| **Deployment** | Tunnel | ngrok | Tunnel |

---

## 📁 File Structure

```
student_stress_app/
├── lib/
│   ├── main.dart (Entry point)
│   ├── screens/
│   │   └── home_screen.dart (UI)
│   └── services/
│       ├── audio_stress_service.dart (Audio + YAMNet integration)
│       ├── behavioral_service.dart (Unlock tracking)
│       ├── physical_service.dart (Activity detection)
│       └── sync_service.dart (Backend communication)
├── android/ (Platform-specific)
└── pubspec.yaml (Dependencies)

python/
├── main.py (FastAPI app)
├── yamnet_service.py (YAMNet inference)
└── requirements.txt (Python dependencies)
```

---

## 🔑 Key Code Snippets

### Flutter: Send Audio to Backend
```dart
final request = http.MultipartRequest(
  'POST',
  Uri.parse('${backend_url}/analyze-audio'),
);
request.files.add(
  await http.MultipartFile.fromPath('audio_file', filePath),
);
final response = await http.Response.fromStream(await request.send());
final json = jsonDecode(response.body) as Map<String, dynamic>;
final detectedSounds = json['detected_sounds'] as Map<String, dynamic>;
```

### Python: YAMNet Inference
```python
waveform = load_wav_file(path)  # 16kHz mono
scores, embeddings, spectrogram = model(waveform)
mean_scores = np.mean(scores, axis=0)  # Average across frames
top_indices = np.argsort(mean_scores)[-10:][::-1]  # Top 10
audio_score = calculate_stress_from_scores(mean_scores)
return {"audio_score": audio_score, "detected_sounds": detected}
```

### Python: Stress Score Fusion
```python
final_stress = (audio_score + behavioral_score + physical_risk) / 3
return {"status": "Success", "final_stress": final_stress}
```

---

## ✅ Testing Checklist for FYP

- [ ] App starts without errors
- [ ] Audio records for full 10 seconds
- [ ] File size is approximately 320 KB
- [ ] Backend receives audio file successfully
- [ ] YAMNet detects sound events (not hardcoded!)
- [ ] Detected sounds match actual audio environment
- [ ] Audio score is calculated correctly
- [ ] Behavioral score increments with app unlocks
- [ ] Physical activity detection works in background
- [ ] Final stress score is average of 3 models
- [ ] JSON responses parse correctly
- [ ] Error handling works (network down, etc.)
- [ ] UI updates after each analysis
- [ ] Multiple consecutive analyses work

---

## 🎓 FYP Documentation Checklist

- [x] System architecture documented
- [x] Data flow diagrams included
- [x] Data types defined
- [x] API endpoints specified
- [x] ML model explained (YAMNet + AudioSet)
- [x] Stress calculation formulas shown
- [x] Complete message sequence documented
- [x] Backend code available
- [x] Security/privacy considerations
- [x] Performance metrics provided
- [x] Citations and references included

---

## 🚀 Next Steps for FYP Submission

1. **Install APK on device**
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

2. **Ensure backend is running**
   ```bash
   cd python && python main.py
   ```

3. **Test complete flow**
   - Open app → Tap audio button → Speak 10 seconds → Check results

4. **Collect screenshots/videos** of:
   - Audio recording interface
   - Detected sounds output
   - Stress score display
   - Backend logs showing inference

5. **Document evidence**
   - Console logs showing YAMNet processing
   - Example audio analyses (real sounds, real scores)
   - Backend API responses (prove it's ML, not hardcoded)
   - Architecture diagrams

6. **Include in FYP report**
   - This technical documentation
   - System architecture
   - Implementation details
   - Test results
   - User interface screenshots

---

**Date**: March 11, 2026  
**Status**: Ready for FYP Submission  
**Version**: 1.0

