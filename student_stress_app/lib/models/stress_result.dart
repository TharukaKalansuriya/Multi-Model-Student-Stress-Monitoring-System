// Stress prediction result model
class StressResult {
  final double stressLevel; // e.g. 0.0 to 1.0
  final String label;       // e.g. "Low", "Medium", "High"
  final DateTime timestamp;

  StressResult({
    required this.stressLevel,
    required this.label,
    required this.timestamp,
  });

  @override
  String toString() =>
      'StressResult(label: $label, level: $stressLevel, time: $timestamp)';
}
