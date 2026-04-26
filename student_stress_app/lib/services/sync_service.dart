import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/behavioral_service.dart';
import '../services/backend_service.dart';

/// SyncService
///
/// Sends the dual stress scores to the FastAPI backend via HTTP POST.
/// NOW uses BackendService.getBackendUrl() for centralized URL management.
class SyncService {
  final BehavioralService _behavioralService = BehavioralService();

  /// Sends the audio and behavioral scores to the `/sync` endpoint.
  ///
  /// Returns `true` on success (HTTP 200), `false` otherwise.
  Future<bool> syncStressScore({
    required String userId,
    required int audioScore,
  }) async {
    final backendUrl = BackendService.getBackendUrl();
    final uri = Uri.parse('$backendUrl/sync');

    try {
      print('DEBUG: Syncing both models to Python');
      final behavioralScore =
          await _behavioralService.calculateBehavioralScore();

      final response = await http.post(
        uri,
        headers: BackendService.getHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'audio_score': audioScore,
          'behavioral_score': behavioralScore,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('[SyncService] Synced successfully: ${response.body}');
        return true;
      } else {
        print(
          '[SyncService] Sync failed — HTTP ${response.statusCode}: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('[SyncService] Network error: $e');
      return false;
    }
  }

  /// Sync all component scores to the /sync-all endpoint
  Future<Map<String, dynamic>> syncAll(Map<String, dynamic> data) async {
    try {
      final backendUrl = BackendService.getBackendUrl();
      final uri = Uri.parse('$backendUrl/sync-all');

      print('[SyncService] Syncing all models to backend...');
      print('[SyncService] URL: $uri');

      final response = await http
          .post(
            uri,
            headers: BackendService.getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        print('[SyncService] ✓ Sync successful: ${result['status']}');
        return result;
      } else {
        print(
            '[SyncService] Sync failed - HTTP ${response.statusCode}: ${response.body}');
        return {'status': 'Error', 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('[SyncService] ✗ Network error: $e');
      return {'status': 'Error', 'message': e.toString()};
    }
  }

  /// Get daily summary from backend
  Future<Map<String, dynamic>> getDailySummary(String userId) async {
    try {
      final backendUrl = BackendService.getBackendUrl();
      final uri = Uri.parse('$backendUrl/get-daily-summary');

      print('[SyncService] Getting daily summary...');

      final response = await http
          .post(
            uri,
            headers: BackendService.getHeaders(),
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        print('[SyncService] ✓ Daily summary retrieved');
        return result;
      } else {
        print(
            '[SyncService] Failed to get summary - HTTP ${response.statusCode}');
        return {'status': 'Error', 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('[SyncService] ✗ Network error: $e');
      return {'status': 'Error', 'message': e.toString()};
    }
  }

  /// Start automated collection on backend
  Future<Map<String, dynamic>> startCollection(String userId) async {
    try {
      final backendUrl = BackendService.getBackendUrl();
      final uri = Uri.parse('$backendUrl/start-automated-collection');

      print('[SyncService] Starting collection...');

      final response = await http
          .post(
            uri,
            headers: BackendService.getHeaders(),
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        print('[SyncService] ✓ Collection started');
        return result;
      } else {
        print(
            '[SyncService] Failed to start collection - HTTP ${response.statusCode}');
        return {'status': 'Error', 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('[SyncService] ✗ Network error: $e');
      return {'status': 'Error', 'message': e.toString()};
    }
  }

  /// Stop automated collection on backend
  Future<Map<String, dynamic>> stopCollection(String userId) async {
    try {
      final backendUrl = BackendService.getBackendUrl();
      final uri = Uri.parse('$backendUrl/stop-automated-collection');

      print('[SyncService] Stopping collection...');

      final response = await http
          .post(
            uri,
            headers: BackendService.getHeaders(),
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        print('[SyncService] ✓ Collection stopped');
        return result;
      } else {
        print(
            '[SyncService] Failed to stop collection - HTTP ${response.statusCode}');
        return {'status': 'Error', 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('[SyncService] ✗ Network error: $e');
      return {'status': 'Error', 'message': e.toString()};
    }
  }

  /// Send accumulated behavioral data with audio score after 3-hour cycle
  /// This is the main sync endpoint for the 3-hour accumulation system
  Future<Map<String, dynamic>> syncWithAccumulatedData(
    Map<String, dynamic> accumulatedData,
  ) async {
    try {
      final backendUrl = BackendService.getBackendUrl();
      final uri = Uri.parse('$backendUrl/analyze-digital-habits');

      print('[SyncService] Sending 3-hour accumulated data...');
      print('[SyncService] URL: $uri');

      final response = await http
          .post(
            uri,
            headers: BackendService.getHeaders(),
            body: jsonEncode(accumulatedData),
          )
          .timeout(
              const Duration(seconds: 60)); // Longer timeout for heavy analysis

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        print('[SyncService] ✓ 3-hour sync successful');
        print('[SyncService]   Digital Score: ${result['digital_score']}');
        print(
            '[SyncService]   Recommendations: ${result['recommendations']?.length ?? 0} items');
        return result;
      } else {
        print(
            '[SyncService] 3-hour sync failed - HTTP ${response.statusCode}: ${response.body}');
        return {'status': 'Error', 'message': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('[SyncService] ✗ 3-hour sync network error: $e');
      return {'status': 'Error', 'message': e.toString()};
    }
  }
}
