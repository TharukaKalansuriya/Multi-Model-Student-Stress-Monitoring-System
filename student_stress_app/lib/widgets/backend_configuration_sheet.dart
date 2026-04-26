import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:student_stress_app/services/backend_service.dart';
import 'package:student_stress_app/services/digital_habits_service.dart';

/// Backend Configuration Widget
/// Allows users to configure backend URL for different environments
class BackendConfigurationSheet extends StatefulWidget {
  const BackendConfigurationSheet({Key? key}) : super(key: key);

  @override
  State<BackendConfigurationSheet> createState() =>
      _BackendConfigurationSheetState();
}

class _BackendConfigurationSheetState extends State<BackendConfigurationSheet> {
  late TextEditingController _urlController;
  late BackendService _backendService;
  late SharedPreferences _prefs;
  bool _isSaving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: BackendService.getBackendUrl(),
    );
    _backendService = BackendService();
    _loadPreferences();
  }

  void _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showMessage('Please enter a URL', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final testUrl = '$url/health';
      print('[BackendConfig] Testing connection to: $testUrl');

      final response = await http
          .get(Uri.parse(testUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _showMessage('✓ Connection successful!', Colors.green);
      } else {
        _showMessage(
          '✗ Server responded with ${response.statusCode}',
          Colors.orange,
        );
      }
    } catch (e) {
      _showMessage(
        '✗ Connection failed: $e',
        Colors.red,
      );
      print('[BackendConfig] Connection error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveConfiguration() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      _showMessage('URL cannot be empty', Colors.red);
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _showMessage('URL must start with http:// or https://', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save to both services
      await _backendService.setBackendUrl(url);
      // All services now use BackendService.getBackendUrl() centrally

      _showMessage('✓ Configuration saved!', Colors.green);

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showMessage('Error saving configuration: $e', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, Color color) {
    setState(() => _statusMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _setPreset(String url) {
    setState(() => _urlController.text = url);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Backend Configuration',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 20),
            Text(
              'Current Backend URL',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'http://10.0.2.2:8000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quick Presets',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _buildPresetButton(
              label: '📱 Android Emulator',
              url: 'http://10.0.2.2:8000',
              description: 'Default for emulator',
            ),
            _buildPresetButton(
              label: '🍎 iOS Simulator',
              url: 'http://localhost:8000',
              description: 'For iOS simulator',
            ),
            _buildPresetButton(
              label: '📡 ngrok Tunnel',
              url: 'https://your-ngrok-url.ngrok.io',
              description: 'Physical device via ngrok',
            ),
            const SizedBox(height: 16),
            Text(
              'Physical Device Setup',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'e.g., http://192.168.1.100:8000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.computer),
              ),
              onChanged: (value) => _urlController.text = value,
            ),
            const SizedBox(height: 20),
            if (_statusMessage != null) ...[
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _testConnection,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Test Connection'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveConfiguration,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
            if (_isSaving) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 16),
            _buildHelpText(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Backend URL Configuration',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Configure where the app connects to fetch stress analysis. Different devices need different URLs:',
            style: TextStyle(color: Colors.blue.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton({
    required String label,
    required String url,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _setPreset(url),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        description,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpText() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need help?',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.amber.shade900),
          ),
          const SizedBox(height: 8),
          Text(
            '• Emulator: Use 10.0.2.2:8000\n'
            '• Physical Device: Use your computer\'s IP (e.g., 192.168.1.100:8000)\n'
            '• Remote: Use ngrok tunnel URL\n'
            '• Test connection to verify URL works',
            style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
          ),
        ],
      ),
    );
  }
}

/// Show Backend Configuration Sheet
void showBackendConfigurationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const BackendConfigurationSheet(),
  );
}
