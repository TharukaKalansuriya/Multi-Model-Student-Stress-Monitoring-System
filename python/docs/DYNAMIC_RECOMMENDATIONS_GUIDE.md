## 🧠 Dynamic Recommendation System - No Hardcoded Values

### Overview

The recommendation system generates personalized stress management advice based on actual stress scores, not hardcoded responses. It works in two tiers:

1. **Tier 1: Google Gemini LLM** (Primary)
   - Uses real-time scores to generate intelligent recommendations
   - Handles complex patterns and nuanced advice
   - Takes 5-40 seconds (it's calling Google's API)

2. **Tier 2: Dynamic Fallback** (Backup)
   - Generates recommendations from actual stress scores
   - No hardcoded values - everything is calculated
   - Used when Gemini API is unavailable
   - Instant response (<100ms)

---

### How It Works

#### The Workflow (LanGraph)

```
Input Scores → Analyze → Classify → Generate (Gemini) → Return
                (1)        (2)          (3)
```

1. **Analyze Node**: Identifies primary stressor from scores
   - Highest score = primary stressor
   - Calculates averages and patterns

2. **Classify Node**: Determines stress level
   - < 30: LOW
   - 30-50: MODERATE  
   - 50-75: HIGH
   - > 75: CRITICAL

3. **Generate Node**: Creates recommendations via Gemini
   - Falls back to dynamic recommendations if API fails
   - All recommendations are specific to the user's scores

---

### Dynamic Fallback Algorithm

The system NEVER uses hardcoded strings. Instead, it builds recommendations from score data:

#### Recommendation 1: Address PRIMARY Stressor

Based on which score is highest (audio, digital, or physical):

```python
# Example: If digital_score = 85 (highest)
primary_stressor = 'digital'
primary_score = 85

# The system generates:
{
  "title": f"📱 URGENT: Phone Crisis ({primary_score:.0f}°)",
  "action": "Digital stress is critical! Put your phone...",
  "benefit": f"Addresses your {primary_score:.0f}° stress...",
  "priority": "high"  # High because score > 70
}
```

**Score Ranges for Recommendation Intensity:**
- Score > 70: URGENT, HIGH priority, immediate action
- Score 50-70: High priority, address soon
- Score 35-50: Medium priority, preventive approach
- Score < 35: Low priority, maintenance/positive reinforcement

#### Recommendation 2: Address SECONDARY Stressor

Works the same way but for the second-highest stress source:

```python
# Example: If audio_score = 55 (second highest)
secondary_stressor = 'audio'
secondary_score = 55

# Different recommendations than primary
{
  "title": f"🎵 Audio Masking ({secondary_score:.0f}°)",
  "action": f"Use headphones...",
  "benefit": f"Reduces environmental noise contributing to {secondary_score:.0f}° stress",
  "priority": "high"  # Because > 50
}
```

#### Recommendation 3: Overall Stress Management

Based on AVERAGE of all three scores:

```python
average_score = (audio + digital + physical) / 3

if average_score > 70:
  # Crisis interventions
  "title": f"🔴 CRISIS: Overall Stress {average:.0f}° - Immediate Action"
  
elif average_score > 55:
  # Multi-domain approach
  "title": f"⚠️ Elevated Stress Management ({average:.0f}°)"
  
elif average_score > 40:
  # Build sustainable routines
  "title": f"⚡ Moderate Stress Routine ({average:.0f}°)"
  
else:
  # Maintenance and positive reinforcement
  "title": f"✨ Excellent Stress Level ({average:.0f}°)"
```

---

### Example Outputs (All Dynamic)

#### Example 1: Low Stress Student
```json
{
  "audio_score": 15,
  "digital_score": 20,
  "physical_score": 25,
  "recommendations": [
    {
      "title": "🔉 Maintain Audio Awareness (15°)",
      "action": "Your audio stress is manageable...",
      "benefit": "Keeps your 15° audio stress stable",
      "priority": "low"
    },
    {
      "title": "📱 Healthy Digital Habits (20°)",
      "action": "Your phone usage is under control...",
      "benefit": "Maintains your healthy 20° digital stress level",
      "priority": "medium"
    },
    {
      "title": "✨ Excellent Stress Level (20°)",
      "action": "Maintain your current habits...",
      "benefit": "Sustain your optimal 20° stress level",
      "priority": "low"
    }
  ]
}
```

#### Example 2: Moderate Stress Student
```json
{
  "audio_score": 45,
  "digital_score": 60,
  "physical_score": 40,
  "recommendations": [
    {
      "title": "📵 Phone Detox (60°)",
      "action": "Put your phone in another room for 30 minutes...",
      "benefit": "Addresses your 60° digital stress through immediate disconnect",
      "priority": "high"
    },
    {
      "title": "⏰ Notification Limits (45°)",
      "action": "Disable non-essential app notifications...",
      "benefit": "Reduces digital stress interruptions at level 45°",
      "priority": "medium"
    },
    {
      "title": "⚡ Moderate Stress Routine (48°)",
      "action": "Build daily routine: 20-min focus blocks...",
      "benefit": "Sustainable practices that lower your 48° stress over time",
      "priority": "medium"
    }
  ]
}
```

#### Example 3: High Stress Student  
```json
{
  "audio_score": 75,
  "digital_score": 82,
  "physical_score": 78,
  "recommendations": [
    {
      "title": "🔇 Critical Noise - Find Silent Space NOW (75°)",
      "action": "Your environment noise is severe (75°)...",
      "benefit": "Directly reduces your 75° environmental stress level",
      "priority": "high"
    },
    {
      "title": "📱 URGENT: Phone Crisis (82°)",
      "action": "Digital stress is critical! Put your phone...",
      "benefit": "Breaks the severe phone addiction cycle at 82° stress",
      "priority": "high"
    },
    {
      "title": "🔴 CRISIS: Overall Stress 78° - Immediate Action",
      "action": "Take 10 deep breaths and step outside...",
      "benefit": "Activates parasympathetic nervous system",
      "priority": "high"
    }
  ]
}
```

---

### Code Implementation

#### Backend (Python)

The `_fallback_recommendations` method builds recommendations dynamically:

```python
def _fallback_recommendations(self, state: RecommendationState) -> list[dict]:
    # Get actual scores (not hardcoded)
    audio_score = state["audio_score"]  # Real value from mobile
    digital_score = state["digital_score"]  # Real value from mobile
    physical_score = state["physical_score"]  # Real value from mobile
    average_score = (audio_score + digital_score + physical_score) / 3
    
    # Rank by actual values
    stressors = [
        ('audio', audio_score),
        ('digital', digital_score),
        ('physical', physical_score),
    ]
    stressors.sort(key=lambda x: x[1], reverse=True)
    primary_stressor, primary_score = stressors[0]
    
    # Build recommendation from actual score
    if primary_stressor == 'audio':
        if primary_score > 70:  # Dynamic threshold
            # Generate HIGH PRIORITY recommendation
            recommendations.append({
                "title": f"🔇 Critical Noise ({primary_score:.0f}°)",
                "action": f"Your environment noise is severe ({primary_score:.0f}°)...",
                "benefit": f"Directly reduces your {primary_score:.0f}° environmental stress",
                "priority": "high"
            })
        elif primary_score > 50:
            # Generate MEDIUM PRIORITY recommendation
            # ...
```

#### Mobile App (Dart)

```dart
// Get recommendations with real scores from analysis
final recommendations = await backend.getRecommendations(
  audioScore: 75,    // These are REAL scores from YAMNet analysis
  digitalScore: 82,  // From actual phone usage patterns
  physicalScore: 78, // From sensor data
);

// The backend generates dynamic recommendations based on these REAL values
// NOT from a hardcoded list
print(recommendations['recommendations']);
// Output will be specific to the user's 75/82/78 score profile
```

---

### Caching for Performance

The recommendation system caches results to avoid repeated Gemini API calls:

```python
# Round scores to nearest 5 to increase cache hits
def _generate_cache_key(audio_score, digital_score, physical_score):
    audio_rounded = round(audio_score / 5) * 5  # 75 → 75, 78 → 80
    digital_rounded = round(digital_score / 5) * 5
    physical_rounded = round(physical_score / 5) * 5
    
    # Same rounded scores = same cache entry
    return f"{audio_rounded}_{digital_rounded}_{physical_rounded}"
```

**Cache Benefits:**
- Score 75° and 76° → Same recommendations (rounded to 75°)
- Much faster responses (< 100ms vs 5-40s)
- Reduces API costs (60 requests/minute limit)
- Cached for 1 hour then refreshed

---

### Stress Level Thresholds (Dynamic)

The system classifies stress dynamically based on average:

```python
average_score = (audio + digital + physical) / 3

if average_score < 30:
    level = "low"
    category = "You're managing stress well"
    
elif average_score < 50:
    level = "moderate"
    category = "Stress levels are normal, but watch out for patterns"
    
elif average_score < 75:
    level = "high"
    category = "Your stress is elevated - intervention recommended"
    
else:
    level = "critical"
    category = "Immediate stress management needed"
```

---

### Stress Score Interpretation

Each score represents stress on a 0-100 scale:

#### Audio Stress (Environmental)
- **0-25°**: Quiet environment, no stress
- **25-50°**: Normal office/campus noise
- **50-75°**: Loud environment, focus difficult
- **75-100°**: Extremely noisy, headaches/anxiety

#### Digital Stress (Phone Usage)
- **0-25°**: Healthy phone habits, good control
- **25-50°**: Normal student phone usage
- **50-75°**: Excessive usage, addiction signs
- **75-100°**: Severe digital addiction, withdrawal symptoms

#### Physical Stress (Activity Level)
- **0-25°**: Active, regular exercise, healthy
- **25-50°**: Moderate activity, balanced movement
- **50-75°**: Sedentary, limited movement
- **75-100°**: Very sedentary, health risk indicators

---

### API Request/Response

#### Request
```json
{
  "user_id": "student_001",
  "audio_score": 45,
  "digital_score": 60,
  "physical_score": 40
}
```

#### Response
```json
{
  "status": "Success",
  "user_id": "student_001",
  "scores": {
    "audio": 45,
    "digital": 60,
    "physical": 40,
    "average": 48.33
  },
  "stress_analysis": {
    "level": "moderate",
    "category": "Stress levels are normal, but watch out for patterns",
    "primary_stressor": "digital"
  },
  "recommendations": [
    {
      "title": "📵 Phone Detox (60°)",
      "action": "Put your phone in another room for 30 minutes...",
      "duration": "30 minutes",
      "benefit": "Addresses your 60° digital stress through immediate disconnect",
      "motivation": "You'll regain focus within 5 minutes",
      "priority": "high"
    },
    ...
  ],
  "generated_by": "Google Gemini (LanGraph) or Dynamic Fallback",
  "model": "gemini-2.0-flash",
  "timestamp": "2026-04-19T15:30:45.123456"
}
```

---

### Troubleshooting

#### Issue: Recommendations seem generic
**Solution**: Check that real scores are being sent:
```dart
// Make sure scores are from actual analysis
final audio = await analyzeAudio();      // Not just 50
final digital = await analyzeDigital();  // Real behavior data
final physical = await analyzeMovement(); // Real sensor data
```

#### Issue: Recommendations always the same
**Solution**: Enable cache debugging:
```python
# In recommendation_service.py, look for:
# "[*] Cache hit!" vs "[*] Cache expired"
```

#### Issue: Gemini API timeout
**Solution**: System automatically uses dynamic fallback:
```python
# If Gemini API fails after 45 seconds,
# _fallback_recommendations() is used instead
# This is NOT an error - it's by design!
```

---

### How to Extend the System

Add new stress sources without hardcoding:

```python
# New recommendation 4: Sleep quality
if fourth_score > 60:
    recommendations.append({
        "title": f"😴 Sleep Issues ({fourth_score:.0f}°)",
        "action": "Your sleep quality is low. Try sleeping at regular times...",
        "benefit": f"Improves health markers contributing to {fourth_score:.0f}° stress",
        "priority": "high"
    })

# The system automatically adjusts based on actual score!
```

