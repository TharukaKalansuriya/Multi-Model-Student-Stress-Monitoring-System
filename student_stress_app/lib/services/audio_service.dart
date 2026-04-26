import 'dart:async';

// NOTE: This service is deprecated. Use AudioStressService instead.
// import 'package:tflite_audio/tflite_audio.dart';

/// AudioService
///
/// DEPRECATED - Use AudioStressService instead.
/// 
/// This was the original implementation. It's kept for reference only.
class AudioService {
  // ─── Asset paths ──────────────────────────────────────────────────────────
  static const String _modelPath = 'assets/yamnet.tflite';
  static const String _labelPath = 'assets/labels.txt';

  // ─── Recording parameters ─────────────────────────────────────────────────
  static const int _sampleRate = 16000;
  static const int _bufferSize = 2000;

  // ─── Stress weight table ──────────────────────────────────────────────────
  //
  // Each entry is a keyword (matched as a case-insensitive substring against
  // the YAMNet label) paired with a stress score in [0, 100].
  //
  // High-stress sounds  →  80–100
  // Mid-stress sounds   →  40–79
  // Low-stress sounds   →  0–20
  static const List<_WeightEntry> _weights = [
    // ── High stress (80-100) ──────────────────────────────────────────────
    _WeightEntry('Siren', 100),
    _WeightEntry('Civil defense siren', 100),
    _WeightEntry('Fire alarm', 98),
    _WeightEntry('Smoke detector', 97),
    _WeightEntry('Gunshot', 96),
    _WeightEntry('Machine gun', 96),
    _WeightEntry('Explosion', 95),
    _WeightEntry('Artillery', 95),
    _WeightEntry('Screaming', 90),
    _WeightEntry('Scream', 90),
    _WeightEntry('Traffic noise', 85),
    _WeightEntry('Traffic', 85),
    _WeightEntry('Emergency vehicle', 88),
    _WeightEntry('Police car', 88),
    _WeightEntry('Ambulance', 88),
    _WeightEntry('Fire engine', 87),
    _WeightEntry('Jackhammer', 84),
    _WeightEntry('Chainsaw', 83),
    _WeightEntry('Drill', 82),
    _WeightEntry('Power tool', 82),
    _WeightEntry('Tools', 80),
    _WeightEntry('Hammer', 80),
    _WeightEntry('Thunderstorm', 80),
    _WeightEntry('Thunder', 78),
    // ── Mid stress (40-79) ────────────────────────────────────────────────
    _WeightEntry('Crying', 70),
    _WeightEntry('Baby cry', 70),
    _WeightEntry('Crowd', 65),
    _WeightEntry('Cheering', 60),
    _WeightEntry('Hubbub', 62),
    _WeightEntry('Children shouting', 65),
    _WeightEntry('Yell', 60),
    _WeightEntry('Shout', 60),
    _WeightEntry('Dog', 55),
    _WeightEntry('Bark', 58),
    _WeightEntry('Alarm', 72),
    _WeightEntry('Buzzer', 68),
    _WeightEntry('Car alarm', 75),
    _WeightEntry('Air horn', 74),
    _WeightEntry('Lawn mower', 55),
    _WeightEntry('Vacuum cleaner', 50),
    _WeightEntry('Motorcycle', 60),
    _WeightEntry('Truck', 58),
    _WeightEntry('Bus', 50),
    _WeightEntry('Aircraft engine', 55),
    _WeightEntry('Helicopter', 60),
    _WeightEntry('Jet engine', 65),
    _WeightEntry('Speech', 40),
    _WeightEntry('Conversation', 40),
    _WeightEntry('Telephone', 45),
    _WeightEntry('Music', 42),
    // ── Low stress (0-20) ─────────────────────────────────────────────────
    _WeightEntry('Silence', 0),
    _WeightEntry('Outside, rural or natural', 5),
    _WeightEntry('Outside, rural', 5),
    _WeightEntry('Natural sounds', 5),
    _WeightEntry('Rustling leaves', 8),
    _WeightEntry('Stream', 8),
    _WeightEntry('Waterfall', 8),
    _WeightEntry('Ocean', 10),
    _WeightEntry('Waves', 10),
    _WeightEntry('Rain', 12),
    _WeightEntry('Wind', 15),
    _WeightEntry('Bird vocalization', 10),
    _WeightEntry('Bird', 10),
    _WeightEntry('Chirp', 8),
    _WeightEntry('Laughter', 15),
    _WeightEntry('Singing', 18),
    _WeightEntry('Humming', 15),
    _WeightEntry('Ambient music', 15),
    _WeightEntry('Breathing', 10),
    _WeightEntry('Reverberation', 12),
    _WeightEntry('Field recording', 10),
  ];

  /// Fallback score for labels that do not match any keyword.
  static const double _defaultScore = 35.0;

  // ─── Model lifecycle ──────────────────────────────────────────────────────

  /// DEPRECATED - This service is no longer used
  /// Use AudioStressService instead
  Future<void> loadModel() async {
    // TfliteAudio.loadModel() - deprecated
    print('[AudioService] DEPRECATED - Use AudioStressService');
  }

  /// DEPRECATED - This service is no longer used
  Future<void> stopRecording() async {
    // TfliteAudio.stopAudioRecognition() - deprecated
    print('[AudioService] DEPRECATED - Use AudioStressService');
  }

  // ─── Recording stream ─────────────────────────────────────────────────────

  /// DEPRECATED - This service is no longer used
  Stream<Map<dynamic, dynamic>> startRecordingStream({
    int numOfInferences = 5,
  }) {
    // TfliteAudio.startAudioRecognition() - deprecated
    print('[AudioService] DEPRECATED - Use AudioStressService');
    return const Stream.empty();
  }

  // ─── Stress scoring ───────────────────────────────────────────────────────

  /// Maps a label-to-confidence [result] map to a stress percentage [0.0–100.0].
  ///
  /// ### Algorithm
  /// For every label in [result]:
  /// 1. Find its stress weight by case-insensitive substring match against
  ///    [_weights]. If no match is found, use [_defaultScore].
  /// 2. Compute a confidence-weighted sum:
  ///    `weightedSum += confidence × stressWeight`
  /// 3. Divide by total confidence to get the weighted average.
  /// 4. Clamp to [0.0, 100.0] and return.
  ///
  /// ### Example
  /// ```dart
  /// final score = audioService.getStressScore({
  ///   'Traffic noise, roadway noise': 0.8,
  ///   'Silence': 0.2,
  /// });
  /// // → (0.8×85 + 0.2×0) / 1.0 = 68.0
  /// ```
  double getStressScore(Map<String, double> result) {
    if (result.isEmpty) return _defaultScore;

    double weightedSum = 0.0;
    double totalConfidence = 0.0;

    for (final entry in result.entries) {
      final weight = _scoreForLabel(entry.key);
      weightedSum += entry.value * weight;
      totalConfidence += entry.value;
    }

    if (totalConfidence == 0.0) return _defaultScore;

    final raw = weightedSum / totalConfidence;
    return raw.clamp(0.0, 100.0);
  }

  /// Convenience: returns a stress score directly from a single label string
  /// (as returned by the YAMNet recognitionResult in non-raw mode).
  ///
  /// Equivalent to `getStressScore({label: 1.0})`.
  double getStressScoreFromLabel(String label) {
    return _scoreForLabel(label).clamp(0.0, 100.0);
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────

  /// Finds the stress score for a [label] using case-insensitive substring
  /// matching. The FIRST matching entry in [_weights] wins (higher priority
  /// entries should be listed earlier). Falls back to [_defaultScore].
  static double _scoreForLabel(String label) {
    final lower = label.toLowerCase();
    for (final entry in _weights) {
      if (lower.contains(entry.keyword.toLowerCase())) {
        return entry.score.toDouble();
      }
    }
    return _defaultScore;
  }
}

// ─── Private helper type ──────────────────────────────────────────────────

class _WeightEntry {
  final String keyword;
  final int score;
  const _WeightEntry(this.keyword, this.score);
}
