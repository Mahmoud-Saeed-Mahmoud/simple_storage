import 'collection.dart';
import 'exceptions.dart';
import 'platform_storage_stup.dart'
    if (dart.library.html) 'web_storage_adapter.dart'
    if (dart.library.io) 'file_storage_adapter.dart';
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
  /// If the storage adapter is not provided, it defaults to a [StorageAdapterImpl]
  /// if `dart:io` is available, and a [StorageAdapterImpl] otherwise.
  Database(this._storagePath, {StorageAdapter? storageAdapter})
      : _storageAdapter = StorageAdapterImpl();

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
}
