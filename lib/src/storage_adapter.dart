// src/storage_adapter.dart
/// An abstract class that defines the interface for a storage adapter.
///
/// A storage adapter is responsible for storing and retrieving data from a
/// specific storage location. For example, a file system storage adapter would
/// store and retrieve data from the local file system, while a web storage
/// adapter would store and retrieve data from the browser's local storage.
abstract class StorageAdapter {
  /// Deletes a file or storage entry.
  ///
  /// Returns a future that completes when the delete operation is complete.
  Future<void> deleteFile(String path);

  /// Checks if a file or storage entry exists at the given path.
  ///
  /// Returns a future that completes with true if the file/entry exists, and false
  /// otherwise.
  Future<bool> exists(String path);

  /// Initializes the storage adapter.
  ///
  /// This method is called once when the storage adapter is created, and should
  /// be used to perform any necessary setup or initialization.
  Future<void> init();

  /// Reads the contents of a file or storage entry as a string.
  ///
  /// Returns a future that completes with the contents of the file/entry as a string.
  Future<String> readAsString(String path);

  /// Writes a string to a file or storage entry.
  ///
  /// Returns a future that completes when the write operation is complete.
  Future<void> writeAsString(String path, String content);
}

/// Thrown when a storage operation fails.
class StorageException implements Exception {
  /// The message associated with the exception.
  final String message;

  /// The underlying exception, if any.
  final dynamic cause;

  /// Creates a new [StorageException] with the given [message] and optional [cause].
  StorageException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'StorageException: $message caused by: $cause';
    }
    return 'StorageException: $message';
  }
}
