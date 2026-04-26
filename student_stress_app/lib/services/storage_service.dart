import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service for managing file paths and local storage access.
class StorageService {
  /// Returns the application documents directory path.
  Future<String> getAppDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Returns a [File] reference for a model file stored locally.
  Future<File> getModelFile(String modelFileName) async {
    final basePath = await getAppDocumentsPath();
    return File('$basePath/$modelFileName');
  }
}
