// Collection Class
/// A collection of data stored as key-value pairs, with optional TTL (Time-To-Live)
/// for each entry.
///
/// The collection is stored in a file in the storage directory, and is loaded
/// from the file when the collection is first accessed. The data is stored in
/// memory as a Map, and is saved to the file whenever the collection is modified.
library;

import 'dart:convert';

import 'package:synchronized/synchronized.dart';

import 'exceptions.dart';
import 'storage_adapter.dart';
import 'transaction.dart';

class Collection {
  /// The name of the collection.
  final String name;

  /// The path to the storage directory.
  final String _storagePath;

  /// The storage adapter to use for storing the collection.
  final StorageAdapter _storageAdapter;

  /// The data stored in the collection.
  final Map<String, dynamic> _data = {};

  /// The TTL (Time-To-Live) for each entry in the collection.
  final Map<String, DateTime> _ttlData = {};

  /// Whether the collection has been loaded from the file yet.
  bool _isLoaded = false;

  /// A lock to ensure that only one thread can load or save the collection at
  /// a time.
  final Lock _loadSaveLock = Lock();

  /// A lock to ensure that only one thread can access the collection at a time.
  final Lock _memoryLock = Lock();

  Collection(this.name, this._storagePath, this._storageAdapter);

  /// Deletes the entry with the given key from the collection.
  ///
  /// If the key does not exist in the collection, this method does nothing.
  Future<void> delete(String key) async {
    await _loadData();
    await _delete(key);
    await _saveData();
  }

  /// Retrieves the value associated with the given key from the collection.
  ///
  /// If the key does not exist in the collection, or if the TTL for the key has
  /// expired, this method returns null.
  Future<dynamic> get({String? key, dynamic value}) async {
    await _loadData();
    if (key != null) {
      return await _memoryLock.synchronized(() {
        if (_data.containsKey(key)) {
          if (_ttlData.containsKey(key) &&
              DateTime.now().isAfter(_ttlData[key]!)) {
            _delete(key);
            return null;
          }
          return _data[key];
        }
        return null;
      });
    }
    return null;
  }

  /// Retrieves all the values in the collection.
  ///
  /// If a limit is specified, this method returns at most that many values.
  /// If an offset is specified, this method returns values starting from that
  /// offset.
  Future<List<dynamic>> getAll({int limit = 0, int offset = 0}) async {
    await _loadData();

    return await _memoryLock.synchronized(() {
      var values = _data.entries
          .where((element) {
            if (_ttlData.containsKey(element.key) &&
                DateTime.now().isAfter(_ttlData[element.key]!)) {
              _delete(element.key);
              return false;
            }
            return true;
          })
          .map((e) => e.value)
          .toList();
      if (limit > 0) {
        return values.skip(offset).take(limit).toList();
      } else {
        return values;
      }
    });
  }

  /// Adds a new entry to the collection, or updates an existing entry.
  ///
  /// If the key does not exist in the collection, this method adds a new entry
  /// with the given key and value. If the key does exist, this method updates the
  /// existing entry with the given value.
  ///
  /// If a TTL is specified, this method sets the TTL for the entry to the given
  /// value.
  Future<void> put(String key, dynamic value, {Duration? ttl}) async {
    await _loadData();
    await _put(key, value, ttl: ttl);
    await _saveData();
  }

  /// Starts a transaction on the collection.
  ///
  /// A transaction is a series of operations that are executed as a single unit of
  /// work. If any of the operations fail, the entire transaction is rolled back.
  Future<Transaction> startTransaction() async {
    await _loadData();
    return Transaction(this);
  }

  /// Deletes the entry with the given key from the collection.
  ///
  /// This method is used internally by the collection to delete expired entries.
  Future<void> _delete(String key) async {
    await _memoryLock.synchronized(() {
      _data.remove(key);
      _ttlData.remove(key);
    });
  }

  /// Loads the collection from the file.
  ///
  /// This method is used internally by the collection to load the data from the
  /// file when the collection is first accessed.
  Future<void> _loadData() async {
    if (_isLoaded) return;
    await _loadSaveLock.synchronized(() async {
      if (_isLoaded) return;
      _isLoaded = true;
      final storagePath = '$_storagePath/$name.json';
      if (await _storageAdapter.exists(storagePath)) {
        try {
          final contents = await _storageAdapter.readAsString(storagePath);
          if (contents.isNotEmpty) {
            final decoded = jsonDecode(contents);
            await _memoryLock.synchronized(() {
              _data.addAll(Map<String, dynamic>.from(decoded));
            });

            for (var entry in _data.entries) {
              final ttl = (entry.value as Map?)?['ttl'];
              if (ttl != null) {
                _ttlData[entry.key] = DateTime.parse(ttl);
              }
            }
          }
        } catch (e) {
          _isLoaded = false; // Indicate that loading failed
          throw CollectionLoadException('Failed to load data from file: $e');
        }
      }
    });
  }

  /// Adds a new entry to the collection, or updates an existing entry.
  ///
  /// This method is used internally by the collection to add or update an entry.
  Future<void> _put(String key, dynamic value, {Duration? ttl}) async {
    await _memoryLock.synchronized(() {
      _data[key] = value;
      if (ttl != null) {
        _ttlData[key] = DateTime.now().add(ttl);
      } else {
        _ttlData.remove(key);
      }
    });
  }

  /// Saves the collection to the file.
  ///
  /// This method is used internally by the collection to save the data to the
  /// file whenever the collection is modified.
  Future<void> _saveData() async {
    await _loadSaveLock.synchronized(() async {
      try {
        final dataToSave = _data.map((key, value) {
          if (_ttlData.containsKey(key)) {
            final tempValue = Map.from(value);
            tempValue['ttl'] = _ttlData[key]!.toIso8601String();
            return MapEntry(key, tempValue);
          }
          return MapEntry(key, value);
        });

        final encoded = jsonEncode(dataToSave);
        await _storageAdapter.writeAsString(
            '$_storagePath/$name.json', encoded);
      } catch (e) {
        throw CollectionSaveException(
            'Unknown error saving data for collection "$name": $e');
      }
    });
  }
}
