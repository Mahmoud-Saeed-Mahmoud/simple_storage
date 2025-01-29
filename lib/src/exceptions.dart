// src/exceptions.dart

// Custom Exception Classes
/// Thrown when a collection fails to load from the disk.
class CollectionLoadException implements Exception {
  /// The message associated with the exception.
  final String message;

  /// Creates a new [CollectionLoadException] with the given [message].
  CollectionLoadException(this.message);

  @override

  /// Returns a string representation of the exception.
  String toString() => 'CollectionLoadException: $message';
}

/// Thrown when a collection is not found.
class CollectionNotFoundException implements Exception {
  /// The message associated with the exception.
  final String message;

  /// Creates a new [CollectionNotFoundException] with the given [message].
  CollectionNotFoundException(this.message);

  @override

  /// Returns a string representation of the exception.
  String toString() => 'CollectionNotFoundException: $message';
}

/// Thrown when a collection fails to save to disk.
class CollectionSaveException implements Exception {
  /// The message associated with the exception.
  final String message;

  /// Creates a new [CollectionSaveException] with the given [message].
  CollectionSaveException(this.message);

  @override

  /// Returns a string representation of the exception.
  String toString() => 'CollectionSaveException: $message';
}

/// Thrown when the database fails to create the storage directory.
class DatabaseCreateException implements Exception {
  /// The message associated with the exception.
  final String message;

  /// Creates a new [DatabaseCreateException] with the given [message].
  DatabaseCreateException(this.message);

  @override

  /// Returns a string representation of the exception.
  String toString() => 'DatabaseCreateException: $message';
}

/// Thrown when a transaction operation is attempted after the transaction has been committed or rolled back.
class TransactionStateException implements Exception {
  /// The message associated with the exception.
  final String message;

  /// Creates a new [TransactionStateException] with the given [message].
  TransactionStateException(this.message);

  @override
  String toString() => 'TransactionStateException: $message';
}
