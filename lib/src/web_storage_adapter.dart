// lib/src/web_storage_adapter.dart
import 'dart:html';

import 'storage_adapter.dart';

/// A storage adapter that stores data in the browser's local storage.
class StorageAdapterImpl implements StorageAdapter {
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
    return window.localStorage[path] ?? '';
  }

  @override

  /// Writes a key to the browser's local storage with the given string content.
  Future<void> writeAsString(String path, String content) async {
    window.localStorage[path] = content;
  }
}
