## 🔗 Mobile App & Backend Connection Guide

### Quick Start

#### Option 1: Android Emulator (Default - No Extra Steps)
1. Start the backend: `python main.py` (or run `start_backend.bat` on Windows)
2. Backend runs on: `http://localhost:8000`
3. Emulator accesses as: `http://10.0.2.2:8000` ← **ALREADY CONFIGURED**
4. No action needed! Mobile app will automatically connect.

#### Option 2: Physical Android Device
1. Find your PC's IP address:
   - Windows: Open Command Prompt → `ipconfig` → Look for "IPv4 Address" (e.g., 192.168.1.100)
   - Mac/Linux: `ifconfig` or `ip addr`

2. Start backend on your PC: `python main.py`

3. In mobile app, configure URL:
   ```dart
   // In main.dart or settings screen, add:
   final backend = BackendService();
   await backend.switchToPhysicalDevice('192.168.1.100');
   ```

4. Device must be on same WiFi network as your PC

#### Option 3: ngrok Tunnel (For Remote Testing/Deployment)

##### Step 1: Install ngrok
- Download from: https://ngrok.com/download
- Windows: Extract to a folder
- Add ngrok to PATH (Windows):
  1. Copy ngrok.exe location
  2. Open Environment Variables
  3. Add ngrok folder to PATH

##### Step 2: Get Your ngrok URL
1. Start the backend first: `python main.py`
2. Open another terminal/command prompt
3. Run: `ngrok http 8000`
4. Look for output like:
   ```
   Session Status                online
   Account                       <your-account>
   Version                       3.x.x
   Region                        us,jp,in (...)
   Latency                       45ms
   Web Interface                 http://127.0.0.1:4040
   Forwarding                    https://xxxx-yyyy-zzzz.ngrok-free.dev -> http://localhost:8000
   ```
5. Your ngrok URL: `https://xxxx-yyyy-zzzz.ngrok-free.dev` ← **Use this**

##### Step 3: Configure Mobile App
In your Flutter app, set the ngrok URL:
```dart
import 'package:student_stress_app/services/backend_service.dart';

void main() {
  // After initializing BackendService:
  final backend = BackendService();
  await backend.switchToNgrok('https://attractable-camdyn-otoscopic.ngrok-free.dev');
  // Or use custom ngrok URL:
  // await backend.switchToNgrok('https://your-custom-url.ngrok-free.dev');
}
```

Or use the provided constant:
```dart
// In backend_service.dart, it's already defined as _ngrokUrl
await backend.switchToNgrok(); // Uses default ngrok URL
```

---

### 🔧 Backend Service Methods

#### Available Connection Methods
```dart
final backend = BackendService();

// 1. Use default localhost (Android emulator)
await backend.switchToLocalhost();

// 2. Use custom PC IP (physical device)
await backend.switchToPhysicalDevice('192.168.1.100');

// 3. Use default ngrok URL
await backend.switchToNgrok();

// 4. Use custom ngrok URL
await backend.switchToNgrok('https://your-custom.ngrok-free.dev');

// 5. Set any URL manually
await backend.setBackendUrl('http://custom:8000');

// 6. Get current URL
String url = BackendService.getBackendUrl();
print('Connected to: $url');
```

#### Health Check & Diagnostics
```dart
// Simple boolean check
bool isHealthy = await backend.isHealthy();

// Detailed health info
Map<String, dynamic> health = await backend.checkHealth(verbose: true);

// Test all connections and find working one
String? workingUrl = await backend.testAllConnections();
if (workingUrl != null) {
  print('✅ Found working connection: $workingUrl');
}
```

#### Get Available Connections
```dart
Map<String, String> urls = backend.getAvailableUrls();
// Returns:
// {
//   'localhost': 'http://10.0.2.2:8000',
//   'ngrok': 'https://attractable-camdyn-otoscopic.ngrok-free.dev',
//   'physical_device': 'http://192.168.1.1:8000',
//   'custom': '...'
// }
```

---

### 📱 Adding URL Selection UI (Optional)

Create a settings screen in your app:

```dart
import 'package:flutter/material.dart';
import 'package:student_stress_app/services/backend_service.dart';

class BackendSettingsScreen extends StatefulWidget {
  @override
  State<BackendSettingsScreen> createState() => _BackendSettingsScreenState();
}

class _BackendSettingsScreenState extends State<BackendSettingsScreen> {
  final backend = BackendService();
  late String currentUrl;
  bool isHealthy = false;
  
  @override
  void initState() {
    super.initState();
    currentUrl = BackendService.getBackendUrl();
    checkHealth();
  }
  
  Future<void> checkHealth() async {
    final result = await backend.checkHealth();
    setState(() {
      isHealthy = result['status'] == 'connected';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Backend Configuration')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Status indicator
          Card(
            color: isHealthy ? Colors.green[100] : Colors.red[100],
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(isHealthy ? Icons.check_circle : Icons.error),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHealthy ? '✅ Connected' : '❌ Disconnected',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(currentUrl, style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Connection options
          Text('Connection Options', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 12),
          
          ElevatedButton.icon(
            onPressed: () async {
              await backend.switchToLocalhost();
              setState(() => currentUrl = BackendService.getBackendUrl());
              await checkHealth();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Switched to localhost')),
              );
            },
            icon: Icon(Icons.computer),
            label: Text('Use Localhost (Emulator)'),
          ),
          
          SizedBox(height: 12),
          
          ElevatedButton.icon(
            onPressed: () async {
              // Show dialog to input IP
              final ip = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Enter Device IP'),
                  content: TextField(
                    hintText: '192.168.1.100',
                    onChanged: (value) => ip = value,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, ip),
                      child: Text('Connect'),
                    ),
                  ],
                ),
              );
              
              if (ip != null && ip.isNotEmpty) {
                await backend.switchToPhysicalDevice(ip);
                setState(() => currentUrl = BackendService.getBackendUrl());
                await checkHealth();
              }
            },
            icon: Icon(Icons.phone_android),
            label: Text('Use Physical Device IP'),
          ),
          
          SizedBox(height: 12),
          
          ElevatedButton.icon(
            onPressed: () async {
              await backend.switchToNgrok();
              setState(() => currentUrl = BackendService.getBackendUrl());
              await checkHealth();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Switched to ngrok')),
              );
            },
            icon: Icon(Icons.cloud),
            label: Text('Use ngrok Tunnel'),
          ),
          
          SizedBox(height: 24),
          
          // Test connection
          ElevatedButton.icon(
            onPressed: () async {
              final result = await backend.checkHealth(verbose: true);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(result['status'] == 'connected' ? '✅ Connected' : '❌ Disconnected'),
                  content: Text(result['message']),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.network_check),
            label: Text('Test Connection'),
          ),
        ],
      ),
    );
  }
}
```

---

### ⚠️ Troubleshooting Connection Issues

#### Problem: "Connection refused"
**Solution:**
1. Make sure backend is running: `python main.py`
2. Check if running on correct port (8000)
3. Try: `curl http://localhost:8000/health`

#### Problem: Emulator can't connect to localhost
**Solution:**
1. Use `10.0.2.2` instead of `localhost` ✅ (Already configured)
2. Check Windows Firewall allows port 8000
3. Try restarting emulator

#### Problem: Physical device can't connect
**Solution:**
1. Device must be on **same WiFi** as PC
2. Get correct PC IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
3. Disable firewalls temporarily to test
4. PC firewall must allow inbound on port 8000

#### Problem: ngrok URL not working
**Solution:**
1. ngrok tunnel expires! Get new one: `ngrok http 8000`
2. Browser warning on https? → ngrok normal, add header: `ngrok-skip-browser-warning: true` ✅ (Done automatically)
3. Rate limited? → Upgrade ngrok account

---

### 🌐 Backend Endpoints

All endpoints support CORS for remote access:

#### Health & Config
- `GET /health` - Quick health check
- `GET /config` - Backend configuration and endpoints

#### Analysis
- `POST /analyze-audio` - Audio file analysis (YAMNet)
- `POST /analyze-digital-habits` - Digital behavior (Rule-based)
- `POST /analyze-movement` - Physical activity (Random Forest)

#### Recommendations
- `POST /get-recommendations` - AI-powered recommendations (Gemini)

#### Sync
- `POST /sync-all` - Sync all model scores

---

### 📊 Example: Complete Flow

```dart
import 'package:student_stress_app/services/backend_service.dart';

void main() async {
  final backend = BackendService();
  await backend.initialize();
  
  // Option 1: Use default (emulator)
  // No additional config needed
  
  // Option 2: Test connection
  bool isHealthy = await backend.isHealthy();
  print(isHealthy ? '✅ Connected' : '❌ Disconnected');
  
  // Option 3: Switch to ngrok for testing
  // await backend.switchToNgrok();
  
  // Option 4: Use physical device
  // await backend.switchToPhysicalDevice('192.168.1.100');
  
  // Get recommendations
  final recommendations = await backend.getRecommendations(
    audioScore: 45,
    digitalScore: 55,
    physicalScore: 40,
  );
  
  print('Recommendations generated!');
}
```

---

### 🚀 Production Deployment Tips

1. **Use ngrok for testing**: `ngrok http 8000`
2. **Buy ngrok static domain**: Prevents URL changes
3. **Use HTTPS always**: ngrok automatically uses HTTPS
4. **Set API key in .env**: Already configured ✅
5. **Monitor rate limits**: Check ngrok dashboard
6. **Store ngrok URL in app config**: Load from server/database

