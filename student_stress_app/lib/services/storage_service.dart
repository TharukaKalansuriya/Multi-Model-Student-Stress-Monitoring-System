import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service for managing file paths and local storage access.
class StorageService {
  /// Returns the application documents directory path.
  Future<String> getAppDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

 
  Future<File> getModelFile(String modelFileName) async {
    final basePath = await getAppDocumentsPath();
    return File('$basePath/$modelFileName');
  }
}
