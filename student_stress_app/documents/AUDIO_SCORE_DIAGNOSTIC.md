# Audio Score Generation Diagnostic Guide

## Quick Test Steps

### 1. **Deploy & Start Logging**
```bash
# Terminal 1: Deploy app and monitor logs
flutter run

# Terminal 2 (in parallel): Show ALL logs including audio debug messages
flutter logs
```

### 2. **In the App - Test Audio Score**
1. Make sure microphone permission is granted (app should prompt on first audio button click)
2. **Tap the "Start Audio Monitoring" button**
3. Wait 10 seconds while the timer counts down
4. **Check both:**
   - **The UI**: What status message appears? (key indicator)
   - **The Console Logs**: Follow the detailed sequence below

---

## What to Look For in Logs

### 🟢 SUCCESS: Audio Score WILL BE Generated
Look for this sequence:

```
DEBUG: [AudioStress] ════════════════════════════════════════
DEBUG: [AudioStress] Starting 10-second audio monitoring...
DEBUG: [AudioStress] Sample Rate: 16000, Buffer: 2000
DEBUG: [AudioStress] Creating recognition stream...
DEBUG: [AudioStress] Stream created, subscribing to events...

⏱️  [10 second countdown timer shows on screen]

✓ Event #1 received                          👈 KEY: Receiving events means microphone is working!
  Type: _InternalLinkedHashMap
  Keys: ['recognitionResult', 'confidence']
  Full data: {recognitionResult: 'Speech', confidence: 0.75}
✓ Found label in "recognitionResult": "Speech"
✓ STORED: "Speech" → weight=30, confidence=75.0%

✓ Event #2 received
  ... [more events like above]

════ 10-SECOND WINDOW COMPLETE ════
Events received: 6                           👈 Number shows audio was captured!
Unique labels captured: 3
Labels: [Speech, Music, Traffic]

✓ [AudioStress] COMPUTED AUDIO SCORE
✓ [HomeScreen] Computed audio score: 42      👈 SCORE GENERATED!
✓ Score Generated: 42                        👈 Shows in app

Syncing both scores…
Synced successfully ✓
```

---

### 🔴 FAILURE: Audio Score WON'T Generate - Issue 1: No Events
Look for:

```
DEBUG: [AudioStress] ════════════════════════════════════════
DEBUG: [AudioStress] Starting 10-second audio monitoring...
DEBUG: [AudioStress] Creating recognition stream...
DEBUG: [AudioStress] Stream created, subscribing to events...

✓ 10-second timer shows on screen

════ 10-SECOND WINDOW COMPLETE ════
Events received: 0                          👈 PROBLEM: No events at all!
Unique labels captured: 0
Labels: []

⚠️  [AudioStress] WARNING: No labels captured, returning default score: 35.0
DEBUG: [AudioStress] This means no audio events were received from the plugin.

✓ [HomeScreen] Computed audio score: 35
✓ Score Generated: 35                       👈 But it's DEFAULT, not real!

UI shows: "⚠️ No audio detected - Check microphone permission"
```

**Root Cause:** Microphone events not being captured
- [ ] Check: Did app ask for microphone permission? Did you grant it?
- [ ] Check: Is there audio/sound in the room?
- [ ] Check: Is plug or headset plugged into phone?
- [ ] Fix: Go to Settings > Apps > student_stress_app > Permissions > Microphone > Allow

---

### 🔴 FAILURE: Audio Score WON'T Generate - Issue 2: Stream Error
Look for:

```
ERROR: [AudioStress] Stream error: PlatformException(channel-error, ...)

════ 10-SECOND WINDOW COMPLETE ════
Events received: 0
Labels: []

⚠️  [AudioStress] WARNING: No labels captured, returning default score: 35.0

UI shows: "⚠️ No audio detected - Check microphone permission"
```

**Root Cause:** TfliteAudio plugin crashed or system error
- [ ] Restart the app
- [ ] Restart the device
- [ ] Re-grant microphone permission

---

## Score Calculation Breakdown

When audio score IS generated, you'll see detailed calculation:

```
DEBUG: [AudioStress] ════════════════════════════════════════
DEBUG: [AudioStress] COMPUTING AUDIO SCORE
✓ [AudioStress] Labels captured: 3
  - "Speech": confidence=0.75
  - "Music": confidence=0.6
  - "Traffic": confidence=0.5

  → "Speech": weight=30, contribution=22.5
  → "Music": weight=20, contribution=12.0
  → "Traffic": weight=85, contribution=42.5

DEBUG: [AudioStress] Calculation:
  Sum of contributions: 77.0
  Total confidence: 1.85
  Raw score: 41.62
  Final score (0-100): 41.62

✓ [AudioStress] AUDIO SCORE GENERATED: 41   👈 FINAL SCORE
```

---

## Visual UI Indicators

### When Audio Score IS Generated:
- Status message: **"✓ Score Generated: XX"** (where XX = your calculated score)
- Score chip: **Shows your calculated number with color indicator**
- Button state: **Recording stops, shows result**

### When Audio Score is NOT Generated:  
- Status message: **"⚠️ No audio detected - Check microphone permission"**
- Score chip: **Remains empty or shows gray**
- Reason clear: **Default score fallback triggered**

---

## How to Run the Test

### Step 1: Terminal Setup
```powershell
# Build the APK if not already done
flutter build apk

# Then deploy and log in one command
flutter run
```

### Step 2: Check Flutter Logs
The app will automatically output to the console. You should see the sequence above.

Alternatively, in a separate terminal:
```bash
flutter logs --verbose
```

### Step 3: Tap Button and Observe
1. App loads → See "Start Audio Monitoring" button
2. Tap button → Microphone permission dialog (grant it)
3. Wait 10 seconds → Timer counts down
4. After 10s → Status message appears + logs show result

---

## Common Scenarios

| Scenario | Log Output | UI Message | Audio Score? |
|----------|-----------|-----------|--------------|
| Audio captured + calculated | Events received: 5+, "SCORE GENERATED: 50" | ✓ Score Generated: 50 | ✅ YES |
| No audio in room | Events received: 0, "No labels captured" | ⚠️ No audio detected | ❌ NO (default=35) |
| Microphone permission denied | No events, stream may error | ⚠️ No audio detected | ❌ NO (default=35) |
| App crash mid-recording | ERROR line in logs | Error: ... | ❌ NO |

---

## Quickest Way to Tell

**Look at the status message on screen after 10 seconds:**
- 🟢 Shows "✓ Score Generated: XX" where XX ≠ 35 → **Audio score was computed from real data**
- 🟡 Shows "✓ Score Generated: 35" → **Default fallback (no labels captured)**
- 🔴 Shows "⚠️ No audio detected..." → **No microphone access**
- 🔴 Shows "Error: ..." → **App crashed**

---

## Debug Logs Location

After running `flutter run`, all output appears in the terminal. Key messages to grep for:

```bash
# On Windows PowerShell:
flutter logs | Select-String "AUDIO_SCORE GENERATED"
flutter logs | Select-String "Events received:"
flutter logs | Select-String "WARNING:"
```

---

## Still Not Working?

If score always shows 35 and logs show "Events received: 0":

1. **Verify permission granted:**
   - Open device Settings
   - Find App Permissions
   - Microphone permission should be "Allow"

2. **Test microphone separately:**
   - Open Google Recorder app or Voice Recorder
   - Try recording 3 seconds of sound
   - If it works, microphone is fine → plugin issue
   - If it fails, microphone may be disabled or broken

3. **Check logs for errors:**
   - Look for "ERROR:" lines
   - Screenshot/copy the error and share it

4. **Restart app & device:**
   - Uninstall the APK
   - Rebuild and deploy fresh
   - Restart device completely

---

## Expected Behavior Summary

✅ **Score IS Generated When:**
- Microphone permission granted
- Audio/sound is present in the room
- App runs for full 10 seconds without crashing
- Logs show "Events received: 1+" 
- Final message shows "Score Generated: XX" (where XX varies)

❌ **Score is NOT Generated When:**
- No microphone permission
- No audio/sound in the room
- Logs show "Events received: 0"
- UI shows default message about no audio
- Final score shows as default (35)

---

## Questions Answered

**Q: How do I know if 35 is real or default?**
A: Look at the logs. If "Events received: 0", it's default. If > 0, it's real.

**Q: Why does my score keep showing 35?**
A: Either no audio was captured, or the audio-to-label mapping resulted in a weight-35 average.

**Q: What if I see lots of events but still 35?**
A: The audio captured had labels that average to weight 35 (like "Silence" or "Speech"). This IS a real score.

**Q: Can I test without audio?**
A: No. The plugin needs actual microphone input. Play music, speak, make sounds.

