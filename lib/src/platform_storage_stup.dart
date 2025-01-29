// src/platform_storage_stup.dart

import 'storage_adapter.dart';

class StorageAdapterImpl implements StorageAdapter {
  @override
  Future<void> deleteFile(String path) {
    throw UnimplementedError(
        'deleteFile() is not implemented for this platform.');
  }

  @override
  Future<bool> exists(String path) {
    throw UnimplementedError('exists() is not implemented for this platform.');
  }

  @override
  Future<void> init() {
    throw UnimplementedError('init() is not implemented for this platform.');
  }

  @override
  Future<String> readAsString(String path) {
    throw UnimplementedError(
        'readAsString() is not implemented for this platform.');
  }

  @override
  Future<void> writeAsString(String path, String content) {
    throw UnimplementedError(
        'writeAsString() is not implemented for this platform.');
  }
}
