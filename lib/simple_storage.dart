/// A library for storing and retrieving data in a key-value store.
///
/// This library provides a simple, platform-agnostic API for storing and
/// retrieving data in a key-value store. The store can be backed by a variety
/// of different storage adapters, such as the file system or web storage.
///
/// The library consists of the following components:
///
/// * [Database] - the main entry point for the library. It provides a way to
///   create and access [Collection] objects.
/// * [Collection] - a collection of key-value pairs. It provides methods for
///   storing and retrieving data.
/// * [StorageAdapter] - an interface for storing and retrieving data. It is
///   implemented by the different storage adapters.
/// * [FileStorageAdapter] - a storage adapter that uses the file system to
///   store data.
/// * [WebStorageAdapter] - a storage adapter that uses the browser's local
///   storage to store data.
/// * [Transaction] - a class that provides a way to perform multiple operations
///   on a collection as a single, atomic unit of work.
library;

export 'src/collection.dart';
export 'src/database.dart';
export 'src/exceptions.dart';
export 'src/file_storage_adapter.dart';
export 'src/storage_adapter.dart';
export 'src/transaction.dart';
export 'src/web_storage_adapter.dart';
