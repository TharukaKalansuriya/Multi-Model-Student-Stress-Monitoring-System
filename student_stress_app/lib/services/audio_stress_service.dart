import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'sync_service.dart';
import 'backend_service.dart';

class AudioStressService {
  final SyncService syncService;
  final String userId;

  static const int _sampleRate = 16000;
  static const double _defaultScore = 35.0;

  late final FlutterSoundRecorder _recorder;
  bool _recorderReady = false;

  // Stress weights for common audio labels
  static const List<(String, int)> _stressWeights = [
    ('Siren', 100),
    ('Screaming', 95),
    ('Explosion', 95),
    ('Gunshot', 96),
    ('Fire alarm', 98),
    ('Crying', 85),
    ('Emergency vehicle', 88),
    ('Alarm', 80),
    ('Yell', 70),
    ('Shout', 70),
    ('Traffic', 85),
    ('Motorcycle', 60),
    ('Aircraft', 55),
    ('Speech', 30),
    ('Laughter', 10),
    ('Silence', 0),
    ('Music', 20),
    ('Rain', 12),
    ('Wind', 15),
    ('Bird', 10),
    ('Stream', 8),
  ];

  AudioStressService({required this.syncService, required this.userId}) {
    _recorder = FlutterSoundRecorder();
  }

  /// Initialize recorder before first use
  Future<void> _ensureRecorderReady() async {
    if (_recorderReady) return;

    try {
      print('DEBUG: [AudioStress] Initializing FlutterSoundRecorder...');
      // flutter_sound_lite requires opening an audio session
      await _recorder.openAudioSession();
      _recorderReady = true;
      print('✓ [AudioStress] Recorder ready');
    } catch (e) {
      print('❌ ERROR: Failed to initialize recorder: $e');
      _recorderReady = false;
      rethrow;
    }
  }

  /// Records 10 seconds of audio and returns detected labels
  Future<Map<String, double>> startMonitoring({bool testMode = false}) async {
    await _ensureRecorderReady();

    if (testMode) {
      return _generateSyntheticAudio();
    }

    return _recordRealAudio();
  }

  /// Generate synthetic audio events for testing
  Future<Map<String, double>> _generateSyntheticAudio() async {
    Map<String, double> capturedLabels = {};

    print('\n');
    print('DEBUG: [AudioStress] ════════════════════════════════════════');
    print('DEBUG: [AudioStress] 🎤 STARTING 10-SECOND AUDIO MONITORING');
    print('DEBUG: [AudioStress] !  TEST MODE: Generating synthetic audio');
    print('DEBUG: [AudioStress] ════════════════════════════════════════');
    print('DEBUG: [AudioStress] Sample Rate: $_sampleRate Hz');
    print('DEBUG: [AudioStress] Test mode: true');
    print('DEBUG: [AudioStress] Creating synthetic audio event stream...');
    print('DEBUG: [AudioStress] Waiting 10 seconds for audio events...');
    print('DEBUG: [AudioStress] PLEASE MAKE SOUNDS OR SPEAK DURING THIS TIME');

    final testLabels = {
      'Speech': 0.8,
      'Traffic': 0.6,
      'Alarm': 0.7,
    };

    var eventIndex = 0;
    final completer = Completer<Map<String, double>>();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (eventIndex >= 10) {
        timer.cancel();
        completer.complete(capturedLabels);
        return;
      }

      final labelEntry =
          testLabels.entries.elementAt(eventIndex % testLabels.length);
      eventIndex++;

      print('\n');
      print('DEBUG: [AudioStress] √√√ SYNTHETIC EVENT #$eventIndex √√√');
      print('DEBUG: [AudioStress] Label: "${labelEntry.key}"');
      print('DEBUG: [AudioStress] Confidence: ${labelEntry.value}');

      capturedLabels[labelEntry.key] = labelEntry.value;
      final weight = _getWeightForLabel(labelEntry.key);
      print(
          '✓ [AudioStress] STORED: "${labelEntry.key}" → weight=$weight, confidence=${(labelEntry.value * 100).toStringAsFixed(1)}%');
    });

    final result = await completer.future.timeout(
      const Duration(seconds: 11),
      onTimeout: () => capturedLabels,
    );

    print('\n');
    print('DEBUG: [AudioStress] ════════════════════════════════════════');
    print('DEBUG: [AudioStress] 📊 10-SECOND WINDOW COMPLETE');
    print('DEBUG: [AudioStress] ════════════════════════════════════════');
    print('DEBUG: [AudioStress] Total events: $eventIndex');
    print('DEBUG: [AudioStress] Unique labels captured: ${result.length}');
    print('DEBUG: [AudioStress] Labels: ${result.keys.toList()}');
    print('✓ Successfully captured audio labels!');

    return result;
  }

  /// Record real audio for 10 seconds
  Future<Map<String, double>> _recordRealAudio() async {
    Map<String, double> capturedLabels = {};

    try {
      print('\n');
      print('DEBUG: [AudioStress] ════════════════════════════════════════');
      print('DEBUG: [AudioStress] 🎤 STARTING 10-SECOND AUDIO MONITORING');
      print('DEBUG: [AudioStress] ════════════════════════════════════════');
      print('DEBUG: [AudioStress] Sample Rate: $_sampleRate Hz');
      print('DEBUG: [AudioStress] Test mode: false');

      // Get temporary directory for recording (using dart:io instead of platform channel)
      final tempDir = Directory.systemTemp;
      final audioFile =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      print('DEBUG: [AudioStress] Starting audio recording to: $audioFile');
      print('DEBUG: [AudioStress] Listening for 10 seconds...');
      print(
          'DEBUG: [AudioStress] PLEASE MAKE SOUNDS OR SPEAK DURING THIS TIME');

      // Start recording
      print('DEBUG: [AudioStress] About to call startRecorder()...');
      try {
        await _recorder.startRecorder(
          toFile: audioFile,
          codec: Codec.pcm16WAV,
          numChannels: 1,
          sampleRate: _sampleRate,
        );
        print('✓ [AudioStress] startRecorder() completed successfully');
      } catch (e) {
        print('❌ ERROR: startRecorder() failed: $e');
        rethrow;
      }

      print(
          'DEBUG: [AudioStress] Recording started successfully, waiting 10 seconds...');

      // Wait 10 seconds with progress display
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 1));
        print('DEBUG: [AudioStress] ⏱️  ${i + 1}/10 seconds...');
      }

      // Stop recording
      await _recorder.stopRecorder();
      print('✓ [AudioStress] Recording completed: $audioFile');

      // Analyze the recorded audio file (we already know the path)
      try {
        final file = File(audioFile);
        if (await file.exists()) {
          // Analyze the recorded audio
          capturedLabels = await _analyzeAudioFile(audioFile);

          // Clean up
          try {
            await file.delete();
          } catch (e) {
            print('DEBUG: [AudioStress] Failed to delete temp audio file: $e');
          }
        } else {
          print('⚠️  Audio file was not created: $audioFile');
        }
      } catch (e) {
        print('ERROR: [AudioStress] Failed to process audio file: $e');
      }

      print('\n');
      print('DEBUG: [AudioStress] ════════════════════════════════════════');
      print('DEBUG: [AudioStress] 📊 10-SECOND WINDOW COMPLETE');
      print('DEBUG: [AudioStress] ════════════════════════════════════════');
      print(
          'DEBUG: [AudioStress] Unique labels captured: ${capturedLabels.length}');
      print('DEBUG: [AudioStress] Labels: ${capturedLabels.keys.toList()}');

      if (capturedLabels.isEmpty) {
        print('⚠️  No audio labels detected');
      } else {
        print('✓ Successfully captured audio labels!');
      }

      return capturedLabels;
    } catch (e, st) {
      print('❌ ERROR: [AudioStress] Recording failed: $e');
      print('ERROR: [AudioStress] Stacktrace: $st');
      try {
        await _recorder.stopRecorder();
      } catch (_) {}
      return capturedLabels;
    }
  }

  /// Analyze recorded audio file
  /// Returns detected audio events based on file analysis
  /// NOW uses BackendService.getBackendUrl() for centralized URL management
  Future<Map<String, double>> _analyzeAudioFile(String filePath) async {
    Map<String, double> detectedLabels = {};

    try {
      print('DEBUG: [AudioStress] Analyzing audio file...');

      final audioFile = File(filePath);
      if (!await audioFile.exists()) {
        print('⚠️  Audio file not found: $filePath');
        return detectedLabels;
      }

      // Get file size (indicates if audio was actually recorded)
      final statsSync = audioFile.statSync();
      final fileSize = statsSync.size;
      print('DEBUG: [AudioStress] Audio file size: $fileSize bytes');

      if (fileSize < 50000) {
        print('⚠️  Audio file too small - likely no audio recorded');
        return detectedLabels;
      }

      // ═══════════════════════════════════════════════════════════════
      // USE CENTRALIZED BACKEND URL instead of hardcoded URL
      // ═══════════════════════════════════════════════════════════════
      final backendUrl = BackendService.getBackendUrl();
      print('🚀 Sending audio to YAMNet backend ($backendUrl) for inference...');

      // Create multipart request to send audio file to backend
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/analyze-audio'),
      );

      // Add ngrok headers to multipart request
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
        'Accept': 'application/json',
        'User-Agent': 'dart:http/StudentStressApp',
      });

      // Add audio file to request
      request.files.add(
        await http.MultipartFile.fromPath('audio_file', filePath),
      );

      print('📤 Uploading audio file to backend...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('✓ [AudioStress] Backend YAMNet analysis successful');

        // Parse response
        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;

        // Extract detected sounds from backend response
        final detectedSounds =
            json['detected_sounds'] as Map<String, dynamic>? ?? {};

        // Convert to our format
        detectedSounds.forEach((label, confidence) {
          detectedLabels[label] = (confidence as num).toDouble();
          final weight = _getWeightForLabel(label);
          print(
              '✓ [AudioStress] YAMNet: "$label" → confidence=${(confidence * 100).toStringAsFixed(1)}%, weight=$weight');
        });

        print(
            '✓ [AudioStress] Detected ${detectedLabels.length} audio events from YAMNet');

        return detectedLabels;
      } else {
        print('❌ ERROR: Backend returned status ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception(
            'Audio analysis failed: Backend returned ${response.statusCode}');
      }
    } catch (e, st) {
      print('❌ ERROR: [AudioStress] Audio analysis failed: $e');
      print('ERROR: [AudioStress] Stacktrace: $st');
      throw Exception('Audio analysis failed: $e');
    }
  }

  /// Compute stress score from audio labels
  double computeAudioScore(Map<String, double> labels) {
    print('\n');
    print(
        'DEBUG: [AudioStress] ═══════════════════════════════════════════════');
    print('DEBUG: [AudioStress] COMPUTING AUDIO SCORE');
    print(
        'DEBUG: [AudioStress] ═══════════════════════════════════════════════');
    print('DEBUG: [AudioStress] Input: ${labels.length} labels');

    if (labels.isEmpty) {
      print('❌ ERROR: No labels captured - audio analysis failed');
      print(
          'DEBUG: [AudioStress] ═══════════════════════════════════════════════\n');
      throw Exception('Audio analysis failed: No labels detected');
    }

    print('✓ [AudioStress] Labels captured:');
    labels.forEach((label, conf) {
      print('  - "$label": confidence=${(conf * 100).toStringAsFixed(1)}%');
    });

    double sum = 0.0;
    double totalConf = 0.0;

    labels.forEach((label, confidence) {
      final weight = _getWeightForLabel(label);
      final contribution = confidence * weight;
      sum += contribution;
      totalConf += confidence;
      print(
          '  → "$label": weight=$weight, contribution=${contribution.toStringAsFixed(2)}');
    });

    final score = totalConf > 0 ? (sum / totalConf) : _defaultScore;
    final clampedScore = score.clamp(0.0, 100.0);

    print('\nDEBUG: [AudioStress] Calculation:');
    print('  Sum of contributions: $sum');
    print('  Total confidence: $totalConf');
    print(
        '  Raw score (sum/totalConf): ${(sum / totalConf).toStringAsFixed(2)}');
    print('  Final score (0-100): ${clampedScore.toStringAsFixed(2)}');
    print('✓ [AudioStress] AUDIO SCORE GENERATED: ${clampedScore.toInt()}');
    print(
        'DEBUG: [AudioStress] ═══════════════════════════════════════════════\n');

    return clampedScore;
  }

  /// Get weight for label
  static int _getWeightForLabel(String label) {
    final lower = label.toLowerCase();
    for (final (keyword, weight) in _stressWeights) {
      if (lower.contains(keyword.toLowerCase())) return weight;
    }
    return _defaultScore.toInt();
  }

  /// Stop audio monitoring
  Future<void> stopMonitoring() async {
    try {
      await _recorder.stopRecorder();
      print('DEBUG: [AudioStress] Recording stopped');
    } catch (e) {
      print('DEBUG: [AudioStress] Stop error (ignored): $e');
    }
  }

  /// Clean up resources
  void dispose() {
    try {
      // flutter_sound_lite cleanup
    } catch (e) {
      print('DEBUG: [AudioStress] Dispose error: $e');
    }
  }
}
