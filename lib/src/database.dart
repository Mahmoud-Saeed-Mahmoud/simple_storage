import 'dart:io';

import 'collection.dart';
import 'exceptions.dart';
import 'file_storage_adapter.dart'
    if (dart.library.js) 'web_storage_adapter.dart';
import 'storage_adapter.dart';

/// A database that stores collections of key-value pairs in a storage
/// directory. The collections are stored as files in the storage directory,
/// and are loaded into memory as a [Map] when first accessed.
///
/// The database provides a convenient way to store and retrieve data in a
/// persistent manner. It is designed to be used in a variety of scenarios,
/// from mobile apps to web apps.
class Database {
  /// The path to the directory where the collections are stored.
  final String _storagePath;

  /// The collections in this database.
  /// The collections are stored in a [Map], where the key is the name of the
  /// collection and the value is the [Collection] object.
  final Map<String, Collection> _collections = {};

  /// The storage adapter that is used to read and write the collections.
  final StorageAdapter _storageAdapter;

  /// Creates a new [Database] with the given storage path and storage adapter.
  /// If the storage adapter is not provided, it defaults to a [FileStorageAdapter]
  /// if `dart:io` is available, and a [WebStorageAdapter] otherwise.
  Database(this._storagePath, {StorageAdapter? storageAdapter})
      : _storageAdapter = storageAdapter ?? _getDefaultStorageAdapter() {
    _createStorageDir();
  }

  /// Returns a [Future] that completes with a [Collection] with the given name.
  /// If the collection does not exist, it is created.
  Future<Collection> collection(String name) async {
    if (!_collections.containsKey(name)) {
      _collections[name] = Collection(name, _storagePath, _storageAdapter);
    }
    if (_collections[name] == null) {
      throw CollectionNotFoundException('Collection $name was not created');
    }
    return _collections[name]!;
  }

  /// Creates the storage directory if it does not exist.
  void _createStorageDir() {
    if (_storageAdapter is StorageAdapterImpl) {
      try {
        Directory(_storagePath).createSync(recursive: true);
      } on IOException catch (e) {
        throw DatabaseCreateException("Failed to create storage directory $e");
      } catch (e) {
        _getDefaultStorageAdapter();
      }
    }
  }

  /// Returns the default storage adapter based on the platform.
  /// If `dart:io` is available, it returns a [FileStorageAdapter].
  /// Otherwise, it returns a [WebStorageAdapter].
  static StorageAdapter _getDefaultStorageAdapter() {
    try {
      return StorageAdapterImpl();
    } catch (e) {
      throw DatabaseCreateException(
          "Unknown error creating database: ${e.toString()}");
    }
  }
}
