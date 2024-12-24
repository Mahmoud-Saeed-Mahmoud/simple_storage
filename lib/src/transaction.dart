// lib/src/transaction.dart
import 'package:synchronized/synchronized.dart';

import 'collection.dart';

/// A transaction allows you to perform multiple operations on a [Collection] as
/// a single, atomic unit of work. If any of the operations fail, the entire
/// transaction will be rolled back to its original state.
class Transaction {
  /// The lock used to ensure thread safety.
  final Lock _lock = Lock();

  /// The [Collection] this transaction is operating on.
  final Collection _collection;

  /// Local data stored during the transaction, which will be applied to the
  /// collection when the transaction is committed.
  final Map<String, dynamic> _localData = {};

  /// Whether the transaction has been committed.
  bool _isCommitted = false;

  /// Whether the transaction has been rolled back.
  bool _isRolledBack = false;

  /// Creates a new transaction on the given [Collection].
  Transaction(this._collection);

  /// Commits the transaction, applying all operations to the collection.
  Future<void> commit() async {
    await _lock.synchronized(() async {
      if (_isCommitted || _isRolledBack) {
        throw StateError("Transaction was already committed or rolled back");
      }
      _isCommitted = true;
      for (var entry in _localData.entries) {
        if (entry.value == null) {
          await _collection.delete(entry.key);
        } else {
          await _collection.put(entry.key, entry.value['value'],
              ttl: entry.value['ttl']);
        }
      }
    });
  }

  /// Deletes a key from the collection in the context of the transaction.
  Future<void> delete(String key) async {
    await _lock.synchronized(() {
      if (_isCommitted || _isRolledBack) {
        throw StateError("Transaction was already committed or rolled back");
      }
      _localData[key] = null; // Mark for deletion with null
    });
  }

  /// Adds or updates a key in the collection in the context of the transaction.
  Future<void> put(String key, dynamic value, {Duration? ttl}) async {
    await _lock.synchronized(() {
      if (_isCommitted || _isRolledBack) {
        throw StateError("Transaction was already committed or rolled back");
      }
      _localData[key] = {'value': value, 'ttl': ttl};
    });
  }

  /// Rolls back the transaction, discarding all operations made in the
  /// context of the transaction.
  Future<void> rollback() async {
    await _lock.synchronized(() {
      if (_isCommitted || _isRolledBack) {
        throw StateError("Transaction was already committed or rolled back");
      }
      _isRolledBack = true;
    });
  }
}
