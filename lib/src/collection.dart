import 'dart:convert';

import 'package:synchronized/synchronized.dart';

import 'exceptions.dart';
import 'storage_adapter.dart';
import 'transaction.dart';

class Collection {
  final String name;
  final String _storagePath;
  final StorageAdapter _storageAdapter;
  final Map<String, dynamic> _data = {};
  final Map<String, DateTime> _ttlData = {};
  bool _isLoaded = false;
  final Lock _loadSaveLock = Lock();
  final Lock _memoryLock = Lock();

  Collection(this.name, this._storagePath, this._storageAdapter);

  Future<void> delete(String key) async {
    await _loadData();
    await _delete(key);
    await _saveData();
  }

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
          // Extract value from the map if it's wrapped
          final storedValue = _data[key];
          if (storedValue is Map && storedValue.containsKey('value')) {
            return storedValue['value'];
          }
          return storedValue;
        }
        return null;
      });
    }
    return null;
  }

  Future<List<dynamic>> getAll({int limit = 0, int offset = 0}) async {
    await _loadData();

    return await _memoryLock.synchronized(() {
      var values = _data.entries.where((element) {
        if (_ttlData.containsKey(element.key) &&
            DateTime.now().isAfter(_ttlData[element.key]!)) {
          _delete(element.key);
          return false;
        }
        return true;
      }).map((e) {
        // Extract value from the map if it's wrapped
        if (e.value is Map && e.value.containsKey('value')) {
          return e.value['value'];
        }
        return e.value;
      }).toList();
      if (limit > 0) {
        return values.skip(offset).take(limit).toList();
      } else {
        return values;
      }
    });
  }

  Future<void> put(String key, dynamic value, {Duration? ttl}) async {
    await _loadData();
    // Wrap primitive values in a map
    final valueToStore = _wrapValue(value);
    await _put(key, valueToStore, ttl: ttl);
    await _saveData();
  }

  Future<Transaction> startTransaction() async {
    await _loadData();
    return Transaction(this);
  }

  Future<void> _delete(String key) async {
    await _memoryLock.synchronized(() {
      _data.remove(key);
      _ttlData.remove(key);
    });
  }

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
            if (decoded is Map) {
              await _memoryLock.synchronized(() {
                _data.addAll(Map<String, dynamic>.from(decoded));
              });

              for (var entry in _data.entries) {
                final ttl = (entry.value as Map?)?['ttl'];
                if (ttl != null) {
                  _ttlData[entry.key] = DateTime.parse(ttl);
                }
              }
            } else {
              // if is not a map we must store as a map with key 'value'
              await _memoryLock.synchronized(() {
                _data.addAll({
                  "default": {"value": decoded}
                });
              });
            }
          }
        } catch (e) {
          _isLoaded = false;
          throw CollectionLoadException('Failed to load data from file: $e');
        }
      }
    });
  }

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

  // Helper method to wrap primitive values in a map
  Map<String, dynamic> _wrapValue(dynamic value) {
    if (value is Map) {
      // If it's already a map, ensure String keys
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return {'value': value};
  }
}
