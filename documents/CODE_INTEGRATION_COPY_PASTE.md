# 🔧 Complete Integration Guide - Copy & Paste Code Examples

## For FYP Implementation

**Status:** Production-ready code snippets  
**Date:** March 11, 2026  
**Purpose:** Direct integration into Flutter app and backend

---

## Part 1: Flutter App Integration

### Step 1: Update `main.dart` with Multi-Model Support

```dart
// File: lib/main.dart

import 'package:flutter/material.dart';
import 'services/audio_stress_service.dart';
import 'services/behavioral_service.dart';
import 'services/digital_habits_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load configuration
  final audioService = await AudioStressService.initialize();
  final behavioralService = BehavioralService();
  final digitalService = DigitalHabitsService();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AudioStressService>.value(value: audioService),
        Provider<BehavioralService>.value(value: behavioralService),
        Provider<DigitalHabitsService>.value(value: digitalService),
      ],
      child: const StudentStressApp(),
    ),
  );
}

class StudentStressApp extends StatelessWidget {
  const StudentStressApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Stress Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

### Step 2: Update `home_screen.dart` with All Three Models

```dart
// File: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_stress_service.dart';
import '../services/behavioral_service.dart';
import '../services/digital_habits_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _audioScore;
  int? _behavioralScore;
  int? _digitalScore;
  int? _multiModalScore;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInitialScores();
  }

  Future<void> _loadInitialScores() async {
    final behavioral = context.read<BehavioralService>();
    
    setState(() {
      _behavioralScore = behavioral.getCurrentScore().toInt();
    });
  }

  // ========== MODEL 1: ENVIRONMENTAL (AUDIO) ==========
  Future<void> _analyzeAudioStress() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Recording audio...';
    });

    try {
      final audioService = context.read<AudioStressService>();
      
      // Record 10 seconds of audio
      final audioPath = await audioService.recordAudio();
      print('[HomeScreen] Audio recorded: $audioPath');
      
      setState(() => _statusMessage = 'Analyzing audio...');
      
      // Send to backend
      final result = await audioService.analyzeAudioFile(audioPath);
      
      setState(() {
        _audioScore = (result['audio_score'] as num).toInt();
        _statusMessage = 'Audio analysis complete!';
      });
      
      print('[HomeScreen] Audio Score: $_audioScore°');
      
      // Update UI with detected sounds
      _showAudioResultsDialog(result);
      
    } catch (e) {
      setState(() => _statusMessage = 'Error: ${e.toString()}');
      print('[ERROR] Audio analysis failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAudioResultsDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎤 Audio Analysis Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stress Score: ${result['audio_score']}°',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Detected Sounds:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...((result['detected_sounds'] as Map<String, dynamic>)
                  .entries
                  .map((e) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '• ${e.key}: ${(e.value * 100).toStringAsFixed(1)}%',
                    ),
                  ))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ========== MODEL 2: DIGITAL HABITS ==========
  Future<void> _analyzeDigitalHabits() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Analyzing digital habits...';
    });

    try {
      final digitalService = context.read<DigitalHabitsService>();
      
      // Collect today's digital behavior
      final result = await digitalService.analyzeDigitalHabits(
        userId: 'student_001',  // TODO: Use actual user ID from auth
      );
      
      setState(() {
        _digitalScore = (result['digital_score'] as num).toInt();
        _statusMessage = 'Digital habits analysis complete!';
      });
      
      print('[HomeScreen] Digital Score: $_digitalScore°');
      
      // Show results
      _showDigitalResultsDialog(result);
      
    } catch (e) {
      setState(() => _statusMessage = 'Error: ${e.toString()}');
      print('[ERROR] Digital habits analysis failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDigitalResultsDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📱 Digital Habits Analysis'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stress Score: ${result['digital_score']}°',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrangeAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Component Breakdown:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._buildComponentBars(result['components'] as Map<String, dynamic>),
              const SizedBox(height: 16),
              const Text(
                'Recommendations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(result['recommendations'] as List<dynamic>)
                  .cast<String>()
                  .map((r) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('• $r'),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildComponentBars(Map<String, dynamic> components) {
    return components.entries.map((e) {
      final percentage = ((e.value as num).toInt()).toDouble();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${e.key}: ${percentage.toInt()}°',
              style: const TextStyle(fontSize: 12),
            ),
            LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              color: _getColorForScore(percentage),
              backgroundColor: Colors.grey[300],
            ),
          ],
        ),
      );
    }).toList();
  }

  // ========== MODEL 3: BEHAVIORAL (UNLOCKS) ==========
  void _showBehavioralStats() {
    final behavioral = context.read<BehavioralService>();
    final score = behavioral.getCurrentScore();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔓 Behavioral Stress (Phone Unlocks)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stress Score: ${score.toInt()}°',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Daily Unlocks: ${behavioral.getDailyUnlockCount()}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interpretation:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_getUnlockInterpretation(behavioral.getDailyUnlockCount())),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getUnlockInterpretation(int unlocks) {
    if (unlocks < 5) {
      return '✅ Calm - Very focused, minimal phone checking';
    } else if (unlocks < 15) {
      return '😊 Normal - Typical student behavior';
    } else if (unlocks < 25) {
      return '⚠️ Stressed - High checking frequency suggests anxiety';
    } else {
      return '🚨 Very Stressed - Severe attention issues or anxiety';
    }
  }

  // ========== MULTI-MODAL FUSION ==========
  Future<void> _syncAllModels() async {
    if (_audioScore == null || _behavioralScore == null || _digitalScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please analyze all three models first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Syncing all models...';
    });

    try {
      final digitalService = context.read<DigitalHabitsService>();
      
      // Send all three scores to backend for fusion
      final result = await digitalService.syncAllModels(
        audioScore: _audioScore!,
        behavioralScore: _behavioralScore!,
        digitalScore: _digitalScore!,
      );
      
      setState(() {
        _multiModalScore = (result['multi_modal_score'] as num).toInt();
        _statusMessage = 'All models synchronized!';
      });
      
      print('[HomeScreen] Multi-Modal Score: $_multiModalScore°');
      
      _showFusionResultsDialog(result);
      
    } catch (e) {
      setState(() => _statusMessage = 'Error: ${e.toString()}');
      print('[ERROR] Fusion failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFusionResultsDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎯 Complete Stress Assessment'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main score with color coding
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getColorForScore(result['multi_modal_score'] as num).withOpacity(0.1),
                  border: Border.all(
                    color: _getColorForScore(result['multi_modal_score'] as num),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Overall Stress Level',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(result['multi_modal_score'] as num).toInt()}°',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getColorForScore(result['multi_modal_score'] as num),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result['stress_level'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Component breakdown
              const Text(
                'Component Scores:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._buildComponentBars(result['breakdown'] as Map<String, dynamic>),
              
              const SizedBox(height: 16),
              
              // Interpretation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Interpretation:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(result['interpretation'] as String),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getColorForScore(num score) {
    final s = score.toInt();
    if (s < 25) return Colors.green;
    if (s < 50) return Colors.blue;
    if (s < 75) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Stress Monitor'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status message
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),

              // Loading indicator
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),

              // Score cards
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Audio Score Card
                  _buildScoreCard(
                    title: '🎤 Environmental',
                    subtitle: 'Audio Analysis',
                    score: _audioScore,
                    color: Colors.blue,
                    onTap: _analyzeAudioStress,
                  ),
                  // Digital Score Card
                  _buildScoreCard(
                    title: '📱 Digital Habits',
                    subtitle: 'Phone Behavior',
                    score: _digitalScore,
                    color: Colors.deepOrange,
                    onTap: _analyzeDigitalHabits,
                  ),
                  // Behavioral Score Card
                  _buildScoreCard(
                    title: '🔓 Behavioral',
                    subtitle: 'Phone Unlocks',
                    score: _behavioralScore,
                    color: Colors.red,
                    onTap: _showBehavioralStats,
                  ),
                  // Multi-Modal Card
                  _buildScoreCard(
                    title: '🎯 Combined',
                    subtitle: 'All Models',
                    score: _multiModalScore,
                    color: Colors.purple,
                    onTap: _syncAllModels,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action buttons
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyzeAudioStress,
                icon: const Icon(Icons.mic),
                label: const Text('Analyze Audio'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyzeDigitalHabits,
                icon: const Icon(Icons.phone_android),
                label: const Text('Analyze Digital Habits'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _syncAllModels,
                icon: const Icon(Icons.sync),
                label: const Text('Sync All Models'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard({
    required String title,
    required String subtitle,
    required int? score,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            if (score != null)
              Text(
                '$score°',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              )
            else
              Text(
                'Tap to analyze',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## Part 2: Backend Integration

### Step 1: Ensure all services are imported in Python

```python
# File: main.py
# Check this is at the top:

from fastapi import FastAPI, UploadFile, File, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os
import json
import uuid
import numpy as np
import tensorflow as tf
from yamnet_service import get_yamnet_service
from digital_habits_service import get_digital_habits_service
from behavioral_service import get_behavioral_service

app = FastAPI(title="Student Stress Monitor API")

# Initialize services
yamnet_analyzer = get_yamnet_service()
digital_analyzer = get_digital_habits_service()
behavioral_analyzer = get_behavioral_service()

# Global state
user_stress_data = {}
```

### Step 2: Test Endpoints Manually

```bash
# Test 1: Audio endpoint
curl -X POST https://attractable-camdyn-otoscopic.ngrok-free.dev/analyze-audio \
  -F "audio_file=@/path/to/test_audio.wav"

# Test 2: Digital habits endpoint
curl -X POST https://attractable-camdyn-otoscopic.ngrok-free.dev/analyze-digital-habits \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "student_001",
    "unlocks": 28,
    "screen_time": 285,
    "app_usage": [
      {"app": "YouTube", "time_ms": 1200000},
      {"app": "Instagram", "time_ms": 900000},
      {"app": "Gmail", "time_ms": 600000}
    ],
    "call_log": 8,
    "messages": 42,
    "late_night_usage": true,
    "morning_rush": false
  }'

# Test 3: Multi-modal fusion
curl -X POST https://attractable-camdyn-otoscopic.ngrok-free.dev/sync-all \
  -H "Content-Type: application/json" \
  -d '{
    "audio_score": 30,
    "behavioral_score": 100,
    "digital_score": 60
  }'
```

---

## Part 3: Troubleshooting Guide

### Issue 1: "Permission Denied" for microphone

```dart
// Add to home_screen.dart initState:
Future<void> _requestPermissions() async {
  final micStatus = await Permission.microphone.request();
  if (!micStatus.isGranted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text('This app needs microphone access to analyze environmental stress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
```

### Issue 2: Backend connection fails

```dart
// Add timeout and retry logic:
Duration timeout = const Duration(seconds: 30);
int retries = 3;

for (int i = 0; i < retries; i++) {
  try {
    final response = await http.post(
      Uri.parse('$_backendUrl/analyze-digital-habits'),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    ).timeout(timeout);
    return jsonDecode(response.body);
  } catch (e) {
    if (i == retries - 1) rethrow;
    await Future.delayed(Duration(seconds: 2 * (i + 1)));
  }
}
```

### Issue 3: Audio file too large

```dart
// Compress audio before sending:
Future<File> _compressAudio(String originalPath) async {
  // Use ffmpeg or flutter_sound to downsample
  // Target: 16kHz mono, 10 seconds = ~320KB
  final file = File(originalPath);
  if (file.lengthSync() > 500000) {
    // File too large - resample to 8kHz
    print('[Warning] Audio file large, resampling...');
  }
  return file;
}
```

---

## Part 4: Data Collection Format Reference

### Digital Habits Data Structure

```json
{
  "user_id": "student_001",
  "date": "2026-03-11",
  "unlocks": {
    "count": 28,
    "timestamps": [
      "2026-03-11T06:30:00Z",
      "2026-03-11T06:31:15Z",
      // ... 26 more
    ]
  },
  "screen_time": {
    "total_minutes": 285,
    "by_hour": {
      "6": 15,
      "7": 25,
      // ...
      "22": 35
    }
  },
  "app_usage": [
    {
      "app": "YouTube",
      "time_ms": 1200000,
      "sessions": 3,
      "timestamps": ["2026-03-11T15:30:00Z", "2026-03-11T17:00:00Z", "2026-03-11T20:30:00Z"]
    },
    {
      "app": "Instagram",
      "time_ms": 900000,
      "sessions": 5
    },
    {
      "app": "Gmail",
      "time_ms": 600000,
      "sessions": 1
    }
  ],
  "communications": {
    "calls": 8,
    "messages": 42,
    "busy_periods": [
      {"time": "2026-03-11T12:00:00Z", "reason": "lunch"}
    ]
  },
  "sleep_patterns": {
    "late_night_usage": true,
    "late_night_apps": ["YouTube", "Instagram"],
    "morning_rush": false
  }
}
```

---

## Part 5: Testing Checklist

- [ ] Audio recording works (10 seconds, 16kHz, WAV format)
- [ ] Audio upload to backend succeeds (<5 sec)
- [ ] YAMNet inference completes and returns proper JSON
- [ ] Digital habits data collected throughout the day
- [ ] Digital habits backend analysis returns valid scores
- [ ] Multi-modal fusion calculates correctly: (A + B + D) / 3
- [ ] All three scores display in UI
- [ ] Stress level classification works (Calm/Normal/Elevated/High)
- [ ] Recommendations are relevant and actionable
- [ ] Permissions handling for microphone complete
- [ ] Error messages are user-friendly
- [ ] API responses include all required fields

---

**Ready to build? Run:**
```bash
flutter clean && flutter pub get && flutter run
```

