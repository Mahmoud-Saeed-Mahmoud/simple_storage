// src/file_storage_adapter.dart
import 'dart:io';

import 'storage_adapter.dart';

/// A storage adapter that uses the file system to store data.
class StorageAdapterImpl implements StorageAdapter {
  /// Deletes the file at the given path.
  @override
  Future<void> deleteFile(String path) async {
    try {
      if (await exists(path)) {
        await File(path).delete();
      }
    } on FileSystemException catch (e) {
      throw StorageException('Error deleting file "$path": ${e.message}', e);
    }
  }

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
    try {
      return await File(path).readAsString();
    } on FileSystemException catch (e) {
      throw StorageException('Error reading file "$path": ${e.message}', e);
    }
  }

  /// Writes the given string to a file at the given path.
  @override
  Future<void> writeAsString(String path, String content) async {
    try {
      await File(path).writeAsString(content);
    } on FileSystemException catch (e) {
      throw StorageException('Error writing to file "$path": ${e.message}', e);
    }
  }
}
