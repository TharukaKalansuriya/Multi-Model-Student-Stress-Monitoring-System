import 'package:permission_handler/permission_handler.dart';

/// Service to request and check runtime permissions.
class PermissionService {
  /// Requests microphone permission. Returns true if granted.
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Requests storage permission. Returns true if granted.
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Checks if microphone permission is already granted.
  Future<bool> isMicrophoneGranted() async {
    return await Permission.microphone.isGranted;
  }

  /// Requests permissions needed for Digital Habits Score (Call Log)
  Future<void> requestDigitalHabitsPermissions() async {
    // Request Call Log Permission
    if (!await Permission.phone.isGranted) {
      await Permission.phone.request();
    }
  }
}
