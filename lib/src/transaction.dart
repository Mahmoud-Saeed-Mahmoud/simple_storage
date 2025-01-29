// src/transaction.dart
import 'package:synchronized/synchronized.dart';

import 'collection.dart';
import 'exceptions.dart';

/// A transaction allows you to perform multiple operations on a [Collection] as
/// a single, atomic unit of work. If any of the operations fail, the entire
/// transaction will be rolled back to its original state.
class Transaction {
  /// The lock used to ensure thread safety for transaction operations.
  final Lock _lock = Lock();

  /// The [Collection] this transaction is operating on.
  final Collection _collection;

  /// Local data changes stored during the transaction.
  /// These changes are applied to the collection only when the transaction is committed.
  final Map<String, dynamic> _localData = {};

  /// Flag indicating whether the transaction has been committed.
  bool _isCommitted = false;

  /// Flag indicating whether the transaction has been rolled back.
  bool _isRolledBack = false;

  /// Creates a new transaction on the given [Collection].
  Transaction(this._collection);

  /// Commits the transaction, applying all operations to the collection.
  ///
  /// After commit, the transaction is closed and cannot be used further.
  Future<void> commit() async {
    await _lock.synchronized(() async {
      _checkTransactionState(); // Ensure transaction is still active
      _isCommitted = true;
      for (var entry in _localData.entries) {
        if (entry.value == null) {
          await _collection
              .delete(entry.key); // Delete operation in transaction
        } else {
          await _collection.put(entry.key, entry.value['value'],
              ttl: entry.value['ttl']); // Put operation in transaction
        }
      }
      _localData.clear(); // Clear local data after commit
    });
  }

  /// Deletes a key from the collection within the context of this transaction.
  ///
  /// The deletion is not applied to the collection until the transaction is committed.
  Future<void> delete(String key) async {
    await _lock.synchronized(() {
      _checkTransactionState(); // Ensure transaction is still active
      _localData[key] = null; // Mark the key for deletion
    });
  }

  /// Adds or updates a key in the collection within the context of this transaction.
  ///
  /// The put operation is not applied to the collection until the transaction is committed.
  Future<void> put(String key, dynamic value, {Duration? ttl}) async {
    await _lock.synchronized(() {
      _checkTransactionState(); // Ensure transaction is still active
      _localData[key] = {
        'value': value,
        'ttl': ttl
      }; // Store the value and TTL for put operation
    });
  }

  /// Rolls back the transaction, discarding all operations made in this transaction.
  ///
  /// After rollback, the transaction is closed and cannot be used further.
  Future<void> rollback() async {
    await _lock.synchronized(() {
      _checkTransactionState(); // Ensure transaction is still active
      _isRolledBack = true;
      _localData.clear(); // Discard local data changes
    });
  }

  /// Checks if the transaction is in a valid state for operations (i.e., not committed or rolled back).
  void _checkTransactionState() {
    if (_isCommitted || _isRolledBack) {
      throw TransactionStateException(
          "Transaction was already committed or rolled back and cannot be modified further.");
    }
  }
}
