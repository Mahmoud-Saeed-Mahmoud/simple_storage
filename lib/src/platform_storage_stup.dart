import 'storage_adapter.dart';

class StorageAdapterImpl implements StorageAdapter {
  @override
  Future<bool> exists(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> init() {
    throw UnimplementedError();
  }

  @override
  Future<String> readAsString(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> writeAsString(String path, String content) {
    throw UnimplementedError();
  }
}
