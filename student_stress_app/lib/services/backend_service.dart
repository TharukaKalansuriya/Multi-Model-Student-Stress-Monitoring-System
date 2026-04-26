import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();

  // Supported backend URLs - can be switched at runtime
  static const String _defaultLocalhost = 'http://10.0.2.2:8000';
  static const String _defaultPhysicalDevice = 'http://192.168.1.1:8000';
  static const String _ngrokUrl = 'https://attractable-camdyn-otoscopic.ngrok-free.dev';
  
  // ══════════════════════════════════════════════════════════════════════
  // IMPORTANT: Default to ngrok URL so physical devices work out of the box
  // ══════════════════════════════════════════════════════════════════════
  static String _baseUrl = _ngrokUrl;
  static const String _prefUrlKey = 'backend_url_override';
  static const String _prefConnectionModeKey = 'backend_connection_mode';

  late SharedPreferences prefs;
  static bool _initialized = false;

  BackendService._internal();

  factory BackendService() {
    return _instance;
  }

  // ══════════════════════════════════════════════════════════════════════
  // STATIC GETTER — All services MUST use this to get the backend URL
  // ══════════════════════════════════════════════════════════════════════
  static String getBackendUrl() => _baseUrl;

  /// Standard headers for all HTTP requests (includes ngrok bypass)
  static Map<String, String> getHeaders({bool isJson = true}) {
    final headers = <String, String>{
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
      'User-Agent': 'dart:http/StudentStressApp',
    };
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  /// Initialize the backend service
  Future<void> initialize() async {
    if (_initialized) return;
    prefs = await SharedPreferences.getInstance();
    _loadBackendUrl();
    _initialized = true;
    print('[BackendService] Initialized');
    print('[BackendService] Current URL: $_baseUrl');
  }

  /// Load backend URL from preferences
  void _loadBackendUrl() {
    final savedUrl = prefs.getString(_prefUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
      print('[BackendService] Backend URL loaded from preferences: $_baseUrl');
    } else {
      // Default to ngrok URL
      _baseUrl = _ngrokUrl;
      print('[BackendService] Using default ngrok URL: $_baseUrl');
    }
  }

  /// Set custom backend URL with validation
  Future<void> setBackendUrl(String url) async {
    if (url.isEmpty) {
      print('[BackendService] ❌ Cannot set empty URL');
      return;
    }
    
    // Remove trailing slash if present
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    
    _baseUrl = url;
    await prefs.setString(_prefUrlKey, url);
    print('[BackendService] ✅ Backend URL set to: $_baseUrl');
  }

  /// Switch to localhost connection (for Android emulator)
  Future<void> switchToLocalhost({String? customIp}) async {
    final url = customIp != null ? 'http://$customIp:8000' : _defaultLocalhost;
    await setBackendUrl(url);
    print('[BackendService] 🔄 Switched to localhost: $url');
  }

  /// Switch to ngrok tunnel connection
  Future<void> switchToNgrok({String? customNgrokUrl}) async {
    final url = customNgrokUrl ?? _ngrokUrl;
    await setBackendUrl(url);
    print('[BackendService] 🔄 Switched to ngrok: $url');
  }

  /// Switch to physical device IP (for real devices on same network)
  Future<void> switchToPhysicalDevice(String deviceIp) async {
    final url = 'http://$deviceIp:8000';
    await setBackendUrl(url);
    print('[BackendService] 🔄 Switched to physical device: $url');
  }

  /// Get all available connection modes
  Map<String, String> getAvailableUrls() {
    return {
      'localhost': _defaultLocalhost,
      'ngrok': _ngrokUrl,
      'physical_device': _defaultPhysicalDevice,
      'custom': _baseUrl,
    };
  }

  /// Health check - verify backend is running with detailed diagnostics
  Future<Map<String, dynamic>> checkHealth({bool verbose = false}) async {
    try {
      if (verbose) {
        print('[BackendService] 🔍 Checking health for: $_baseUrl');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: getHeaders(isJson: false),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[BackendService] ✅ Health check PASSED');
        return {
          'status': 'connected',
          'statusCode': response.statusCode,
          'message': 'Backend is running',
          'details': data,
        };
      } else {
        print('[BackendService] ⚠️ Health check returned: ${response.statusCode}');
        return {
          'status': 'error',
          'statusCode': response.statusCode,
          'message': 'Backend returned error',
        };
      }
    } catch (e) {
      print('[BackendService] ❌ Health check failed: $e');
      return {
        'status': 'disconnected',
        'statusCode': 0,
        'message': 'Cannot connect to backend',
        'error': e.toString(),
      };
    }
  }

  /// Quick boolean health check (legacy)
  Future<bool> isHealthy() async {
    final result = await checkHealth();
    return result['status'] == 'connected';
  }

  /// Test connection to all known URLs and return the working one
  Future<String?> testAllConnections() async {
    print('[BackendService] 🧪 Testing all connection types...');
    
    final urls = [
      ('ngrok', _ngrokUrl),
      ('Localhost (Emulator)', _defaultLocalhost),
      ('Current', _baseUrl),
    ];

    for (var (label, url) in urls) {
      try {
        print('   Testing $label: $url');
        final response = await http.get(
          Uri.parse('$url/health'),
          headers: getHeaders(isJson: false),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          print('[BackendService] ✅ Working connection found: $label ($url)');
          return url;
        }
      } catch (e) {
        print('   ❌ $label failed: $e');
      }
    }

    print('[BackendService] ⚠️ No working connections found');
    return null;
  }

  /// Fetch recommendations from backend
  /// Increased timeout to 40 seconds since Gemini LLM can be slow
  Future<Map<String, dynamic>> getRecommendations({
    required int audioScore,
    required int digitalScore,
    required int physicalScore,
  }) async {
    try {
      print('[BackendService] 🎯 Fetching recommendations from $_baseUrl/get-recommendations');
      print('[BackendService] Scores - Audio: $audioScore, Digital: $digitalScore, Physical: $physicalScore');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/get-recommendations'),
            headers: getHeaders(),
            body: jsonEncode({
              'audio_score': audioScore,
              'digital_score': digitalScore,
              'physical_score': physicalScore,
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[BackendService] ✅ Recommendations received successfully');

        // Cache the recommendations
        await prefs.setString(
          'last_recommendations',
          jsonEncode(data),
        );
        await prefs.setInt(
          'last_recommendations_time',
          DateTime.now().millisecondsSinceEpoch,
        );

        return {
          'status': 'success',
          'data': data,
        };
      } else {
        print('[BackendService] Error: ${response.statusCode}');
        print('[BackendService] Response: ${response.body}');
        throw Exception(
            'Failed to fetch recommendations: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('[BackendService] ❌ Exception: $e');
      throw Exception('Recommendations fetch failed: $e');
    }
  }

  /// Get fallback recommendations when backend is unavailable
  Map<String, dynamic> _getFallbackRecommendations() {
    return {
      'scores': {
        'audio': 0,
        'digital': 0,
        'physical': 0,
        'average': 0.0,
      },
      'stress_analysis': {
        'level': 'moderate',
        'category': 'Stress levels are normal',
        'primary_stressor': 'unknown',
      },
      'recommendations': [
        {
          'title': '🚶 Take a Walking Break',
          'action': 'Step outside for a 10-minute walk to clear your mind',
          'duration': '10 minutes',
          'benefit': 'Reduces overall stress and improves focus',
          'motivation': 'Fresh air and movement power!',
          'priority': 'high',
        },
        {
          'title': '🧘 Practice Deep Breathing',
          'action': 'Try 5 minutes of deep breathing exercises',
          'duration': '5 minutes',
          'benefit': 'Calms your nervous system immediately',
          'motivation': 'Quick stress relief technique',
          'priority': 'high',
        },
        {
          'title': '📱 Phone-Free Time',
          'action': 'Put your phone away for 30 minutes',
          'duration': '30 minutes',
          'benefit': 'Reduces digital stress and screen fatigue',
          'motivation': 'You\'ll feel more present and relaxed',
          'priority': 'medium',
        },
      ],
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Analyze audio stress
  Future<Map<String, dynamic>> analyzeAudio(List<double> audioData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/analyze-audio'),
            headers: getHeaders(),
            body: jsonEncode({
              'audio_data': audioData,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'score': 0};
    } catch (e) {
      print('[BackendService] Audio analysis error: $e');
      return {'status': 'error', 'score': 0};
    }
  }

  /// Analyze digital habits stress
  Future<Map<String, dynamic>> analyzeDigitalHabits(
      Map<String, dynamic> habitData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/analyze-digital-habits'),
            headers: getHeaders(),
            body: jsonEncode(habitData),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'score': 0};
    } catch (e) {
      print('[BackendService] Digital habits analysis error: $e');
      return {'status': 'error', 'score': 0};
    }
  }

  /// Analyze physical activity stress
  Future<Map<String, dynamic>> analyzePhysicalActivity(
      Map<String, dynamic> activityData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/analyze-movement'),
            headers: getHeaders(),
            body: jsonEncode(activityData),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'status': 'error', 'score': 0};
    } catch (e) {
      print('[BackendService] Physical activity analysis error: $e');
      return {'status': 'error', 'score': 0};
    }
  }

  /// Get cached recommendations
  Map<String, dynamic>? getCachedRecommendations() {
    try {
      final cached = prefs.getString('last_recommendations');
      if (cached != null) {
        return jsonDecode(cached);
      }
      return null;
    } catch (e) {
      print('[BackendService] Error getting cached recommendations: $e');
      return null;
    }
  }

  /// Clear cached data
  Future<void> clearCache() async {
    await prefs.remove('last_recommendations');
    await prefs.remove('last_recommendations_time');
    print('[BackendService] Cache cleared');
  }
}
