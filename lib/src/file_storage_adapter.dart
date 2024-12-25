// lib/src/file_storage_adapter.dart
import 'dart:io';

import 'storage_adapter.dart';

/// A storage adapter that uses the file system to store data.
class FileStorageAdapter implements StorageAdapter {
  /// Checks if a file exists at the given path.
  @override
  Future<bool> exists(String path) async {
    return File(path).exists();
  }

  /// Initializes the storage adapter.
  @override
  Future<void> init() async {
    // No need for init for the file system
  }

  /// Reads the contents of a file at the given path as a string.
  @override
  Future<String> readAsString(String path) async {
    return File(path).readAsString();
  }

  /// Writes the given string to a file at the given path.
  @override
  Future<void> writeAsString(String path, String content) async {
    await File(path).writeAsString(content);
  }
}
