// lib/src/storage_adapter.dart
/// An abstract class that defines the interface for a storage adapter.
///
/// A storage adapter is responsible for storing and retrieving data from a
/// specific storage location. For example, a file system storage adapter would
/// store and retrieve data from the local file system, while a web storage
/// adapter would store and retrieve data from the browser's local storage.
abstract class StorageAdapter {
  /// Checks if a file exists at the given path.
  ///
  /// Returns a future that completes with true if the file exists, and false
  /// otherwise.
  Future<bool> exists(String path);

  /// Initializes the storage adapter.
  ///
  /// This method is called once when the storage adapter is created, and should
  /// be used to perform any necessary setup or initialization.
  Future<void> init();

  /// Reads the contents of a file as a string.
  ///
  /// Returns a future that completes with the contents of the file as a string.
  Future<String> readAsString(String path);

  /// Writes a string to a file.
  ///
  /// Returns a future that completes when the write operation is complete.
  Future<void> writeAsString(String path, String content);
}
