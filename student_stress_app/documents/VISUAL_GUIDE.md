# 📱 Visual Guide - What You'll See

## Home Screen with Circular Progress Bars

```
┌─────────────────────────────────────────┐
│ Stress Dashboard                    ⚙️  │  ← Settings icon
├─────────────────────────────────────────┤
│                                         │
│  ┌────────────────────────────────┐   │
│  │ Student ID: student_001        │   │
│  │ Status: Active 🟢              │   │
│  └────────────────────────────────┘   │
│                                         │
│  STRESS LEVELS                          │
│  ┌──────────┐  ┌──────────┐  ┌──────┐│
│  │ 🎤 Audio │  │ 📱Digital│  │🏃 Phys││
│  │          │  │          │  │      ││
│  │   75°    │  │   60°    │  │ 45°  ││
│  │ Moderate │  │ Moderate │  │Health││
│  │ ✓✓✓✓✓✓✓  │  │ ✓✓✓✓✓✓   │  │ ✓✓✓  ││
│  │ ○ ○ ○ ○  │  │ ○ ○ ○ ○  │  │○ ○ ○││
│  └──────────┘  └──────────┘  └──────┘│
│                                         │
│  ┌────────────────────────────────┐   │
│  │ STATUS                          │   │
│  │ Scores retrieved successfully   │   │
│  └────────────────────────────────┘   │
│                                         │
│  ACTIONS                                │
│  ┌────────────────────────────────┐   │
│  │ 📊 Check Stress Level          │   │
│  └────────────────────────────────┘   │
│  ┌────────────────────────────────┐   │
│  │ ⏹️ End Collection               │   │
│  └────────────────────────────────┘   │
│                                         │
│  COLLECTION TIMELINE                    │
│  Audio samples       Every 3 hours      │
│  Daily analysis      Midnight (00:00)   │
│  Digital tracking    Continuous         │
│  Physical activity   Daily              │
│                                         │
└─────────────────────────────────────────┘
```

---

## Circular Progress Bar Detail

### Audio Score (75 - Moderate)
```
      ╔═══════════╗
      ║           ║
      ║    🎤     ║
      ║           ║
      ║   75      ║
      ║   / 100   ║
      ║           ║
      ║ Environment║
      ║ Moderate  ║
      ╚═══════════╝

Color: Orange (#FF9500)
Progress: 75%
Label: "Moderate"
Status: Shows warning level stress
```

### Digital Score (60 - Moderate)
```
      ╔═══════════╗
      ║           ║
      ║    📱     ║
      ║           ║
      ║   60      ║
      ║   / 100   ║
      ║           ║
      ║  Digital  ║
      ║ Moderate  ║
      ╚═══════════╝

Color: Orange (#FF9500)
Progress: 60%
Label: "Moderate"
Status: Shows warning level stress
```

### Physical Score (45 - Healthy)
```
      ╔═══════════╗
      ║           ║
      ║    🏃     ║
      ║           ║
      ║   45      ║
      ║   / 100   ║
      ║           ║
      ║  Physical ║
      ║  Healthy  ║
      ╚═══════════╝

Color: Green (#34C759)
Progress: 45%
Label: "Healthy"
Status: Shows good health level
```

---

## Settings Screen

### Light Theme
```
┌─────────────────────────────────┐
│ Settings                        │
├─────────────────────────────────┤
│                                 │
│ APPEARANCE                      │
│                                 │
│ ┌─────────────────────────────┐│
│ │ Light              ◉ Selected │
│ │ Dark               ○         │
│ │ System             ○         │
│ └─────────────────────────────┘│
│                                 │
│ ABOUT                           │
│                                 │
│ ┌─────────────────────────────┐│
│ │ App Version        → 1.0.0   │
│ └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘

Colors:
- Background: White (#F5F5F7)
- Text: Black (#000000)
- Cards: White (#FFFFFF)
- Accents: Blue (#007AFF)
```

### Dark Theme
```
┌─────────────────────────────────┐
│ Settings                        │
├─────────────────────────────────┤
│                                 │
│ APPEARANCE                      │
│                                 │
│ ┌─────────────────────────────┐│
│ │ Light              ○         │
│ │ Dark               ◉ Selected │
│ │ System             ○         │
│ └─────────────────────────────┘│
│                                 │
│ ABOUT                           │
│                                 │
│ ┌─────────────────────────────┐│
│ │ App Version        → 1.0.0   │
│ └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘

Colors:
- Background: Black (#000000)
- Text: White (#FFFFFF)
- Cards: Dark Gray (#1C1C1E)
- Accents: Blue (#007AFF)
```

---

## Color Examples

### Stress Level Colors

#### Healthy (Score < 35)
```
┌──────────────────────────┐
│       🟢 Green           │
│       #34C759            │
│   Healthy Stress Level   │
│                          │
│ Score: 0-34              │
│ Meaning: Good condition  │
└──────────────────────────┘
```

#### Moderate (Score 35-64)
```
┌──────────────────────────┐
│       🟠 Orange          │
│       #FF9500            │
│  Moderate Stress Level   │
│                          │
│ Score: 35-64             │
│ Meaning: Watch closely   │
└──────────────────────────┘
```

#### High (Score 65-100)
```
┌──────────────────────────┐
│       🔴 Red             │
│       #FF3B30            │
│   High Stress Level      │
│                          │
│ Score: 65-100            │
│ Meaning: Intervention    │
└──────────────────────────┘
```

---

## Animation Sequence - Circular Progress Bar

### Frame 1: Start (0%)
```
      ╭───────────╮
      │     🎤    │
      │   0/100   │
      │           │
      ╰───────────╯
```

### Frame 2: 25% (0.375s)
```
      ╔═══════╗
      ║ 🎤  ◿ ║
      ║  25/100
      ╚═══════╝
```

### Frame 3: 50% (0.75s)
```
      ╔════════╗
      ║ 🎤  ◐ ║
      ║  50/100
      ╚════════╝
```

### Frame 4: 75% (1.125s)
```
      ╔════════╗
      ║ 🎤  ◑ ║
      ║  75/100
      ╚════════╝
```

### Frame 5: Complete (1.5s)
```
      ╔════════╗
      ║ 🎤  ◕ ║
      ║  75/100
      ║ Moderate
      ╚════════╝
```

**Total duration**: 1.5 seconds
**Animation type**: Smooth easing curve
**Effect**: Professional entrance animation

---

## User Interaction Flow

### Starting the App
```
1. Launch app
   ↓
2. System checks data collection status
   ↓
3. Captures initial audio (if not collecting)
   ↓
4. Displays home screen with:
   - User ID
   - Status: Inactive
   - "Start Collection" button
```

### Start Monitoring
```
1. User taps "Start Collection"
   ↓
2. Request microphone permission
   ↓
3. Start data collection
   ↓
4. Display confirmation dialog
   ↓
5. Home screen updates:
   - Status: Active
   - Enable "Check Stress Level" button
   - Show circular progress bars
```

### Check Stress Level
```
1. User taps "Check Stress Level"
   ↓
2. Show loading state
   ↓
3. Fetch scores from services:
   - Audio analysis
   - Digital habits
   - Physical activity
   ↓
4. Animate circular progress bars (1.5s)
   ↓
5. Display results with colors:
   - Green if healthy
   - Orange if moderate
   - Red if high stress
```

### Switch Theme
```
1. User taps ⚙️ Settings icon
   ↓
2. Open Settings Screen
   ↓
3. User selects theme (Light/Dark)
   ↓
4. Entire app theme changes instantly:
   - Background color updates
   - Text color updates
   - All colors adapt
   - Components restyle
   ↓
5. Close settings
   ↓
6. Home screen displays in new theme
```

---

## Responsive Layouts

### Mobile (Small Phone)
```
┌─────────────────┐
│ Stress Dashboard│⚙️
├─────────────────┤
│ Student ID      │
│ Status          │
├─────────────────┤
│ STRESS LEVELS   │
│ ┌─────┐         │
│ │🎤 75│         │
│ │Mod  │         │
│ └─────┘         │
│ ┌─────┐         │ (Scrollable)
│ │📱 60│         │
│ │Mod  │         │
│ └─────┘         │
│ ┌─────┐         │
│ │🏃 45│         │
│ │Hlth │         │
│ └─────┘         │
├─────────────────┤
│ [Check Status]  │
│ [End]           │
│ Timeline info   │
└─────────────────┘
```

### Tablet (Large Screen)
```
┌──────────────────────────────────────┐
│ Stress Dashboard                  ⚙️  │
├──────────────────────────────────────┤
│ Student ID: student_001              │
│ Status: Active 🟢                    │
├──────────────────────────────────────┤
│ STRESS LEVELS                        │
│  ┌──────┐  ┌──────┐  ┌──────┐      │
│  │🎤 75 │  │📱 60 │  │🏃 45 │      │
│  │Moderate Moderate Healthy          │
│  └──────┘  └──────┘  └──────┘      │
├──────────────────────────────────────┤
│ [📊 Check Stress] [⏹️ End]           │
│                                      │
│ Timeline: Audio 3hrs | Daily 00:00   │
└──────────────────────────────────────┘
```

---

## Light vs Dark Theme Comparison

### Same Content, Different Themes

#### Light Theme
```
┌───────────────────────────────────┐
│ Homescreen (Light)            ⚙️  │  White background
├───────────────────────────────────┤  
│ Student ID: student_001           │  Black text
│ Status: Active 🟢                 │  
│                                   │
│ Audio    Digital    Physical      │  Cards have subtle
│ 75°      60°       45°            │  light border
│ Orange   Orange    Green          │  
│                                   │
│ [📊 Check]  [⏹️ End]              │  Blue buttons
└───────────────────────────────────┘
```

#### Dark Theme
```
┌───────────────────────────────────┐
│ Homescreen (Dark)             ⚙️  │  Black background
├───────────────────────────────────┤
│ Student ID: student_001           │  White text
│ Status: Active 🟢                 │
│                                   │
│ Audio    Digital    Physical      │  Cards have subtle
│ 75°      60°       45°            │  dark border
│ Orange   Orange    Green          │
│                                   │
│ [📊 Check]  [⏹️ End]              │  Blue buttons
└───────────────────────────────────┘
```

**Key Difference**: Only colors change, layout stays same

---

## Button States

### Normal State
```
┌─────────────────────────┐
│ 📊 Check Stress Level   │  Blue background
│                         │  White text
└─────────────────────────┘
```

### Disabled State
```
┌─────────────────────────┐
│ 📊 Check Stress Level   │  Gray background
│                         │  Gray text
└─────────────────────────┘
```

### Loading State
```
┌─────────────────────────┐
│ [spinner] Loading...    │  Shows spinner
│                         │  Button disabled
└─────────────────────────┘
```

### Pressed State
```
┌─────────────────────────┐
│ 📊 Check Stress Level   │  Pressed effect
│                         │  Slight opacity change
└─────────────────────────┘
```

---

## Card Styling

### Light Theme Card
```
┌─────────────────────────────────┐  Subtle border
│ Student ID: student_001         │  Light gray text
│ Status: Active 🟢               │  White background
│                                 │  12px rounded corners
└─────────────────────────────────┘
```

### Dark Theme Card
```
┌─────────────────────────────────┐  Subtle border
│ Student ID: student_001         │  Light gray text
│ Status: Active 🟢               │  Dark gray background
│                                 │  12px rounded corners
└─────────────────────────────────┘
```

---

## Typography Hierarchy

### Display
```
Stress Dashboard              34pt Bold (-0.5 letter spacing)
```

### Heading
```
Stress Levels                 24pt Semi-bold
```

### Body
```
Student ID: student_001       16pt Regular
Status: Active                14pt Regular
```

### Label
```
APPEARANCE                    12pt Medium (0.5 letter spacing)
```

---

## Stress Core Information Display

When user checks stress level:

```
┌────────────────────────────┐
│                            │
│         🎤 AUDIO           │
│                            │
│      Current Score: 75     │
│      Status: Moderate      │
│      Category: Environment │
│                            │
│      📈 Trend: ↗ Increasing│
│      Last Reading: 2 hrs   │
│                            │
└────────────────────────────┘
```

---

## Success States

### Theme Change Successful
```
User sees:
✓ Entire app instantly changes theme
✓ All colors adapt
✓ Text is readable in new theme
✓ Status bar matches theme
```

### Stress Scores Retrieved
```
User sees:
✓ Three circular progress bars animate
✓ Each bar fills with appropriate color
✓ Scores display clearly
✓ Labels show stress level
```

### Data Collection Started
```
User sees:
✓ Status changes to "Active"
✓ Status badge shows green 🟢
✓ "Check Stress Level" button enables
✓ Confirmation dialog appears
```

---

## Error States

### Permission Denied
```
Status: ⚠️ Microphone permission required
Action: Tap to retry
```

### Connection Error
```
Status: Could not fetch scores. Offline mode.
Action: App still works with cached data
```

### Collection Error
```
Status: ❌ Error occurred
Action: Check and retry
```

---

## Visual Themes Summary

| Aspect | Light | Dark |
|--------|-------|------|
| Background | #F5F5F7 (Light gray) | #000000 (Black) |
| Surface | #FFFFFF (White) | #1C1C1E (Dark gray) |
| Text Primary | #000000 (Black) | #FFFFFF (White) |
| Text Secondary | #666666 (Gray) | #999999 (Gray) |
| Border | #E5E5EA (Light) | #38383A (Dark) |
| Accents | #007AFF (Blue) | #007AFF (Blue) |
| Stress Green | #34C759 | #34C759 |
| Stress Orange | #FF9500 | #FF9500 |
| Stress Red | #FF3B30 | #FF3B30 |

---

## What Makes It Professional

✅ **Consistent Spacing** - 16px standard padding
✅ **Clear Typography** - 4-level hierarchy
✅ **Smooth Animations** - 1.5s easing curves
✅ **Color Theory** - iOS standard colors
✅ **Responsive Layout** - Works all screen sizes
✅ **Accessibility** - High contrast colors
✅ **Polish** - Professional icons and design
✅ **Intuitive** - Easy to use and understand

---

**When you run the app, you'll see a modern, professional iOS-style interface with beautiful circular progress bars showing your stress levels! 🎉**
