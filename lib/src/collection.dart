// src/collection.dart

import 'dart:convert';

import 'package:synchronized/synchronized.dart';

import 'exceptions.dart';
import 'storage_adapter.dart';
import 'transaction.dart';

/// A collection of key-value pairs that are stored in a persistent storage.
///
/// Each collection is stored in a separate file in the storage directory.
/// The data is loaded into memory when the collection is first accessed,
/// and is kept in memory until the collection is no longer needed.
class Collection {
  /// The name of the collection.
  final String name;

  /// The path to the storage directory.
  final String _storagePath;

  /// The storage adapter used to read and write data to the storage.
  final StorageAdapter _storageAdapter;

  /// In-memory cache for the collection data.
  final Map<String, dynamic> _data = {};

  /// In-memory cache for the TTL (Time-To-Live) data.
  final Map<String, DateTime> _ttlData = {};

  /// Flag to indicate whether the data has been loaded from storage.
  bool _isLoaded = false;

  /// Lock to protect concurrent load and save operations.
  final Lock _loadSaveLock = Lock();

  /// Lock to protect concurrent access to the in-memory data.
  final Lock _memoryLock = Lock();

  /// Creates a new [Collection] with the given [name], [storagePath], and [storageAdapter].
  Collection(this.name, this._storagePath, this._storageAdapter);

  /// Clears all data from the collection.
  ///
  /// This operation removes all key-value pairs from the in-memory cache and the persistent storage.
  Future<void> clear() async {
    await _loadData();
    await _memoryLock.synchronized(() {
      _data.clear();
      _ttlData.clear();
    });
    await _saveData();
  }

  /// Checks if the collection contains a value for the given [key].
  ///
  /// This is a more efficient way to check for key existence than using `get(key: key) != null`,
  /// as it avoids loading and deserializing the value.
  Future<bool> containsKey(String key) async {
    await _loadData();
    return await _memoryLock.synchronized(() {
      if (_data.containsKey(key)) {
        if (_ttlData.containsKey(key) &&
            DateTime.now().isAfter(_ttlData[key]!)) {
          _delete(key); // Clean up expired entry
          return false; // Key is considered not present due to TTL expiration
        }
        return true; // Key exists and is not expired
      }
      return false; // Key does not exist
    });
  }

  /// Deletes the value associated with the given [key] from the collection.
  ///
  /// If the key does not exist, this method does nothing.
  Future<void> delete(String key) async {
    await _loadData();
    await _delete(key);
    await _saveData();
  }

  /// Gets the value associated with the given [key] from the collection.
  ///
  /// If the [key] is provided, returns the value associated with that key.
  /// If the [key] is not found or if the TTL for the key has expired, returns null.
  ///
  /// If no [key] is provided, and a [value] is provided, it is not currently used in this implementation and will return null.
  /// Consider this method primarily for key-based retrieval.
  Future<dynamic> get({String? key, dynamic value}) async {
    await _loadData();
    if (key != null) {
      return await _memoryLock.synchronized(() {
        if (_data.containsKey(key)) {
          if (_ttlData.containsKey(key) &&
              DateTime.now().isAfter(_ttlData[key]!)) {
            _delete(key);
            return null; // Return null if TTL expired and entry is deleted
          }
          // Extract value from the map if it's wrapped (for TTL)
          final storedValue = _data[key];
          if (storedValue is Map && storedValue.containsKey('value')) {
            return storedValue['value'];
          }
          return storedValue;
        }
        return null; // Return null if key not found
      });
    }
    return null; // Return null if key is null
  }

  /// Gets all values from the collection, with optional [limit] and [offset] for pagination.
  ///
  /// Entries with expired TTLs are automatically deleted and not included in the result.
  ///
  /// [limit] specifies the maximum number of values to return. If 0, all values are returned.
  /// [offset] specifies the starting index for the returned values (for pagination).
  Future<List<dynamic>> getAll({int limit = 0, int offset = 0}) async {
    await _loadData();

    return await _memoryLock.synchronized(() {
      var values = _data.entries.where((element) {
        if (_ttlData.containsKey(element.key) &&
            DateTime.now().isAfter(_ttlData[element.key]!)) {
          _delete(element.key); // Delete expired entries during getAll
          return false; // Exclude expired entries from result
        }
        return true; // Include non-expired entries
      }).map((e) {
        // Extract value from the map if it's wrapped (for TTL)
        if (e.value is Map && e.value.containsKey('value')) {
          return e.value['value'];
        }
        return e.value;
      }).toList();

      // Apply limit and offset for pagination
      if (limit > 0) {
        return values.skip(offset).take(limit).toList();
      } else {
        return values;
      }
    });
  }

  /// Adds or updates a key-value pair in the collection.
  ///
  /// [key] The key to store the value under.
  /// [value] The value to store.
  /// [ttl] Optional Time-To-Live duration for the key-value pair. If provided, the entry will expire after this duration.
  Future<void> put(String key, dynamic value, {Duration? ttl}) async {
    await _loadData();
    // Wrap primitive values in a map to store TTL information if needed
    final valueToStore = _wrapValue(value);
    await _put(key, valueToStore, ttl: ttl);
    await _saveData();
  }

  /// Starts a new transaction on this collection.
  ///
  /// Returns a [Transaction] object that can be used to perform multiple operations atomically.
  Future<Transaction> startTransaction() async {
    await _loadData();
    return Transaction(this);
  }

  /// Internal method to delete a key from the in-memory cache.
  Future<void> _delete(String key) async {
    await _memoryLock.synchronized(() {
      _data.remove(key);
      _ttlData.remove(key);
    });
  }

  /// Loads data from persistent storage into the in-memory cache.
  ///
  /// This method is called automatically before any operation that requires access to the data.
  /// It uses a lock to ensure that only one load operation is in progress at a time.
  Future<void> _loadData() async {
    if (_isLoaded) return; // Data already loaded, no need to load again
    await _loadSaveLock.synchronized(() async {
      if (_isLoaded) {
        return; // Double check inside lock in case of concurrent calls
      }
      _isLoaded = true;
      final storagePath = '$_storagePath/$name.json';
      if (await _storageAdapter.exists(storagePath)) {
        try {
          final contents = await _storageAdapter.readAsString(storagePath);
          if (contents.isNotEmpty) {
            final decoded = jsonDecode(contents);
            if (decoded is Map) {
              await _memoryLock.synchronized(() {
                _data.addAll(Map<String, dynamic>.from(decoded));
              });

              // Rebuild TTL data from loaded data
              for (var entry in _data.entries) {
                final ttl = (entry.value as Map?)?['ttl'];
                if (ttl != null) {
                  try {
                    _ttlData[entry.key] = DateTime.parse(ttl);
                  } catch (e) {
                    print(
                        'Warning: Invalid TTL format for key "${entry.key}", ignoring TTL. Error: $e');
                    // Optionally handle invalid date format, e.g., remove the ttl entry or log a warning.
                    // For now, we just ignore it, effectively making the entry persistent.
                  }
                }
              }
            } else {
              // If the stored content is not a map, store it under a default key "default"
              await _memoryLock.synchronized(() {
                _data.addAll({
                  "default": {"value": decoded}
                });
              });
            }
          }
        } catch (e) {
          _isLoaded = false; // Reset loaded flag in case of error
          throw CollectionLoadException('Failed to load data from file: $e');
        }
      }
    });
  }

  /// Internal method to put a key-value pair into the in-memory cache.
  Future<void> _put(String key, dynamic value, {Duration? ttl}) async {
    await _memoryLock.synchronized(() {
      _data[key] = value;
      if (ttl != null) {
        _ttlData[key] = DateTime.now().add(ttl);
      } else {
        _ttlData.remove(key); // Remove TTL if no duration is provided
      }
    });
  }

  /// Saves the in-memory cache to persistent storage.
  ///
  /// This method is called automatically after any operation that modifies the data.
  /// It uses a lock to ensure that only one save operation is in progress at a time.
  Future<void> _saveData() async {
    await _loadSaveLock.synchronized(() async {
      try {
        // Prepare data for saving, including TTL information
        final dataToSave = _data.map((key, value) {
          if (_ttlData.containsKey(key)) {
            // Create a copy to avoid modifying the original _data
            final tempValue = Map.from(value);
            tempValue['ttl'] =
                _ttlData[key]!.toIso8601String(); // Store TTL as ISO string
            return MapEntry(key, tempValue);
          }
          return MapEntry(
              key, value); // Save value without TTL if no TTL is set
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

  /// Helper method to wrap primitive values in a map for storing TTL information consistently.
  ///
  /// If the value is already a map, it's returned as is (after ensuring string keys).
  /// Otherwise, it's wrapped in a map with a 'value' key.
  Map<String, dynamic> _wrapValue(dynamic value) {
    if (value is Map) {
      // Ensure keys are strings for consistency in JSON serialization
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return {'value': value}; // Wrap primitive values
  }
}
