// test/collection_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_storage/src/collection.dart';
import 'package:simple_storage/src/exceptions.dart';
import 'package:simple_storage/src/storage_adapter.dart';

void main() {
  group('Collection', () {
    late MockStorageAdapter mockStorageAdapter;
    late Collection collection;
    const collectionName = 'test_collection';
    const storagePath = 'test_storage';
    const filePath = '$storagePath/$collectionName.json';

    setUp(() {
      mockStorageAdapter = MockStorageAdapter();
      collection = Collection(collectionName, storagePath, mockStorageAdapter);
      mockStorageAdapter.shouldThrowErrorOnRead = false;
      mockStorageAdapter.shouldThrowErrorOnWrite = false;
      mockStorageAdapter.shouldThrowErrorOnExists = false;
      mockStorageAdapter.shouldThrowErrorOnDelete = false;
      mockStorageAdapter.storage.clear();
    });

    tearDown(() {
      mockStorageAdapter.storage.clear();
    });

    test('put and get data', () async {
      await collection.put('key1', 'value1');
      var value = await collection.get(key: 'key1');
      expect(value, 'value1');
    });

    test('get non-existent key returns null', () async {
      var value = await collection.get(key: 'non_existent_key');
      expect(value, null);
    });

    test('delete key', () async {
      await collection.put('key_to_delete', 'value_to_delete');
      await collection.delete('key_to_delete');
      var value = await collection.get(key: 'key_to_delete');
      expect(value, null);
    });

    test('getAll values', () async {
      await collection.put('key1', 'value1');
      await collection.put('key2', 123);
      await collection.put('key3', true);
      var allValues = await collection.getAll();
      expect(allValues, contains('value1'));
      expect(allValues, contains(123));
      expect(allValues, contains(true));
      expect(allValues.length, 3);
    });

    test('getAll with limit and offset', () async {
      for (int i = 1; i <= 5; i++) {
        await collection.put('key$i', 'value$i');
      }
      var limitedValues = await collection.getAll(limit: 2, offset: 1);
      expect(limitedValues.length, 2);
      expect(limitedValues, contains('value2'));
      expect(limitedValues, contains('value3'));
    });

    test('put and get data with TTL', () async {
      await collection.put('ttl_key', 'ttl_value',
          ttl: const Duration(seconds: 1));
      await Future.delayed(const Duration(milliseconds: 500));
      var valueBeforeExpiry = await collection.get(key: 'ttl_key');
      expect(valueBeforeExpiry, 'ttl_value');
      await Future.delayed(const Duration(seconds: 1));
      var valueAfterExpiry = await collection.get(key: 'ttl_key');
      expect(valueAfterExpiry, null);
    });

    test('getAll excludes expired TTL values', () async {
      await collection.put('key1', 'value1');
      await collection.put('ttl_key', 'ttl_value',
          ttl: const Duration(seconds: 1));
      await Future.delayed(const Duration(seconds: 2));
      var allValues = await collection.getAll();
      expect(allValues, contains('value1'));
      expect(allValues, isNot(contains('ttl_value')));
      expect(allValues.length, 1);
    });

    test('containsKey returns true for existing key', () async {
      await collection.put('key1', 'value1');
      bool exists = await collection.containsKey('key1');
      expect(exists, true);
    });

    test('containsKey returns false for non-existent key', () async {
      bool exists = await collection.containsKey('non_existent_key');
      expect(exists, false);
    });

    test('containsKey returns false for expired TTL key', () async {
      await collection.put('ttl_key', 'ttl_value',
          ttl: const Duration(seconds: 1));
      await Future.delayed(const Duration(seconds: 2));
      bool exists = await collection.containsKey('ttl_key');
      expect(exists, false);
    });

    test('clear collection', () async {
      await collection.put('key1', 'value1');
      await collection.put('key2', 'value2');
      await collection.clear();
      expect(await collection.get(key: 'key1'), isNull);
      expect(await collection.get(key: 'key2'), isNull);
      expect(await collection.getAll(), isEmpty);

      // Verify persistence after clear by creating a new instance and loading data
      MockStorageAdapter mockStorageAdapter2 = MockStorageAdapter();
      mockStorageAdapter2.storage.addAll(mockStorageAdapter.storage);
      Collection collection2 =
          Collection(collectionName, storagePath, mockStorageAdapter2);
      expect(await collection2.getAll(), isEmpty,
          reason: 'Data should be cleared persistently');

      expect(mockStorageAdapter.storage[filePath],
          '{}'); // Corrected assertion to expect '{}'
    });

    test('loadData handles empty file', () async {
      mockStorageAdapter.storage[filePath] = '';
      // Loading is implicitly tested when any get/put/getAll/containsKey/clear is called.
      // Let's check getAll after "loading" from empty file by triggering getAll.
      expect(await collection.getAll(), isEmpty);
    });

    test('loadData handles non-map json', () async {
      mockStorageAdapter.storage[filePath] = jsonEncode(['value1', 'value2']);
      // Loading is implicitly tested when any get/put/getAll/containsKey/clear is called.
      // Check if data is loaded correctly via getAll after triggering getAll.
      expect(
          await collection.getAll(),
          equals([
            ['value1', 'value2']
          ]));
      // Corrected assertion below to expect a List, not a Map
      expect(await collection.get(key: 'default'),
          ['value1', 'value2']); // Corrected assertion: Expect a List
    });

    test('loadData handles invalid TTL format and ignores it', () async {
      mockStorageAdapter.storage[filePath] = jsonEncode({
        'keyWithInvalidTTL': {
          'value': 'valueWithInvalidTTL',
          'ttl': 'invalid-date-format'
        },
        'keyWithoutTTL': {'value': 'valueWithoutTTL'},
      });
      await collection.get(
          key:
              'keyWithInvalidTTL'); // Implicitly trigger loadData by calling get
      expect(await collection.get(key: 'keyWithInvalidTTL'),
          'valueWithInvalidTTL');
      expect(await collection.get(key: 'keyWithoutTTL'), 'valueWithoutTTL');
      // Cannot directly assert _ttlData is empty, but behavior is tested via get/containsKey TTL checks
    });

    test('saveData and loadData persistence', () async {
      await collection.put('key_persist', 'value_persist');
      await collection.put('ttl_persist', 'ttl_value',
          ttl: const Duration(minutes: 1));

      // Create a new collection instance to simulate app restart and data reload
      MockStorageAdapter mockStorageAdapter2 = MockStorageAdapter();
      mockStorageAdapter2.storage.addAll(mockStorageAdapter.storage);
      Collection collection2 =
          Collection(collectionName, storagePath, mockStorageAdapter2);

      expect(await collection2.get(key: 'key_persist'), 'value_persist');
      expect(await collection2.get(key: 'ttl_persist'), 'ttl_value');
      expect(await collection2.containsKey('ttl_persist'),
          true); // Check TTL presence indirectly
    });

    test('saveData throws CollectionSaveException on storage write error',
        () async {
      mockStorageAdapter.shouldThrowErrorOnWrite = true;
      expect(
          () async => await collection.put(
              'key_for_error', 'value_for_error'), // Trigger saveData via put
          throwsA(isA<CollectionSaveException>()));
    });

    test(
        'delete throws CollectionSaveException on storage delete error during saveData',
        () async {
      mockStorageAdapter.shouldThrowErrorOnWrite = true;
      await collection.put('key_for_delete_error', 'value_for_delete_error');
      expect(() async {
        // Wrap the call in an async function
        await collection
            .delete('key_for_delete_error'); // Await the delete call
      }, throwsA(isA<CollectionSaveException>()));
    });
  });
}

class MockStorageAdapter implements StorageAdapter {
  final Map<String, String> storage = {};
  bool shouldThrowErrorOnRead = false;
  bool shouldThrowErrorOnWrite = false;
  bool shouldThrowErrorOnExists = false;
  bool shouldThrowErrorOnDelete = false;

  @override
  Future<void> deleteFile(String path) async {
    if (shouldThrowErrorOnDelete) {
      throw StorageException('Mock delete error');
    }
    storage.remove(path);
  }

  @override
  Future<bool> exists(String path) async {
    if (shouldThrowErrorOnExists) {
      throw StorageException('Mock exists error');
    }
    return storage.containsKey(path);
  }

  @override
  Future<void> init() async {}

  @override
  Future<String> readAsString(String path) async {
    if (shouldThrowErrorOnRead) {
      throw StorageException('Mock read error');
    }
    return storage[path] ?? '';
  }

  @override
  Future<void> writeAsString(String path, String content) async {
    if (shouldThrowErrorOnWrite) {
      throw StorageException('Mock write error');
    }
    storage[path] = content;
  }
}
