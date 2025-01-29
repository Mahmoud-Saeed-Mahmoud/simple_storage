// src/web_storage_adapter.dart
import 'dart:html';

import 'storage_adapter.dart';

/// A storage adapter that stores data in the browser's local storage.
class StorageAdapterImpl implements StorageAdapter {
  @override

  /// Deletes a key from the browser's local storage.
  Future<void> deleteFile(String path) async {
    try {
      window.localStorage.remove(path);
    } catch (e) {
      throw StorageException('Error deleting localStorage key "$path": $e', e);
    }
  }

  @override

  /// Checks if a key exists in the browser's local storage.
  Future<bool> exists(String path) async {
    return window.localStorage.containsKey(path);
  }

  @override

  /// Initializes the storage adapter. For web local storage this is a no-op.
  Future<void> init() async {
    // No need for init for web local storage
  }

  @override

  /// Reads a key from the browser's local storage as a string.
  Future<String> readAsString(String path) async {
    try {
      return window.localStorage[path] ?? '';
    } catch (e) {
      throw StorageException(
          'Error reading from localStorage key "$path": $e', e);
    }
  }

  @override

  /// Writes a key to the browser's local storage with the given string content.
  Future<void> writeAsString(String path, String content) async {
    try {
      window.localStorage[path] = content;
    } catch (e) {
      throw StorageException(
          'Error writing to localStorage key "$path": $e', e);
    }
  }
}
