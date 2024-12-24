# Dart NoSQL Database

A simple, lightweight NoSQL database written in pure Dart, designed for educational purposes and exploring the fundamentals of database development. This project demonstrates concepts like concurrency control, indexing, pagination, transactions, and TTL.

## Features

*   **Collections:** Organize data into named collections, similar to tables in a relational database.
*   **Key-Value Storage:** Store data as key-value pairs, allowing flexibility in your data structure.
*   **Concurrency Control:** Uses the `synchronized` library for thread-safe access to data, with locks.
*   **Indexing:** Supports in-memory indexing on specified fields for faster lookups.
*   **Pagination:** Fetch data in chunks using `limit` and `offset` to improve performance.
*   **Transactions:** Ensures atomic operations by grouping multiple changes within a transaction scope using a lock.
*   **TTL (Time-To-Live):** Allows setting an expiry time for data, ideal for caching and temporary data management.
*   **Pure Dart:** Built entirely in Dart, making it easy to understand and modify.
*   **File Persistence:** Stores all data in JSON files, with a clear and well-defined structure.

## Getting Started

1.  **Add the `synchronized` dependency:**

    ```bash
    flutter pub add synchronized
    ```

2.  **Import:**

    ```dart
    import 'package:synchronized/synchronized.dart';
    ```

3.  **Create a Database Instance:**

    ```dart
    final db = Database('./my_database'); // Specify the storage path
    ```

    *   The constructor argument specifies the directory where your database files will be stored.

4.  **Create or Access a Collection:**

    ```dart
    final users = await db.collection('users', indexes: ['age', 'name']);
    ```

    *   The first argument is the name of the collection. If a collection with that name doesn't exist it will be created.
    *   The optional `indexes` parameter is a `List<String>` of properties that should be indexed. Indexing can speed up lookups based on these properties but can also slow down insertions if used too much.

5.  **Store Data (with optional TTL):**

    ```dart
    await users.put('1', {'name': 'Alice', 'age': 30}, ttl: Duration(seconds: 60));
    ```

    *   Use the `put` method to store data using a key and a value.
    *   The optional `ttl` parameter specifies a time-to-live for the data. After that time, the data will be removed when loading from disk, or when accessing using `get` or `getAll`.

6.  **Retrieve Data:**

    ```dart
    // By key
    final user = await users.get(key: '1');
    print('User by key: $user');

    // By index
    final usersByAge = await users.get(key: 'age', value: 30);
    print('Users by age: $usersByAge');
    ```

    *   Use the `get` method to retrieve data using a key.
    *   If you use the `key` parameter as a field that has been indexed you should also provide the `value` to filter the results.

7.  **Retrieve Data with Pagination:**

    ```dart
    final pagedUsers = await users.getAll(limit: 10, offset: 0);
    print('Paged users (limit 10, offset 0): ${pagedUsers.length}');
    final allUsers = await users.getAll();
    print('Total number of users: ${allUsers.length}');
    ```

    *   Use `getAll` with `limit` and `offset` to get data in pages.
    *   The `limit` specifies the maximum amount of data returned, and the `offset` specifies which entry is the start of the page.
    *   You can use the total number of users to create pagination controls.

8.  **Perform Operations Inside a Transaction:**

    ```dart
    final tx = await users.startTransaction();
    await tx.put('1', {'name': 'Alice Updated', 'age': 31});
    await tx.delete('2');
    await tx.commit();
    ```

    *   Transactions help group operations in one action that can be committed or rolled back if one of the operations fails.

9.  **Handle Errors:**

    The application throws specific errors:

    *   `DatabaseCreateException`: when the database fails to create the storage directory.
    *   `CollectionLoadException`: when a collection fails to load from the disk.
    *   `CollectionSaveException`: when a collection fails to save to disk.
    *   `CollectionNotFoundException`: when a collection is not found.

    These exceptions should be caught by the application to handle specific error cases. For example:

    ```dart
    try {
        // your code here
    } on DatabaseCreateException catch (e) {
        print("Database creation failed ${e.toString()}");
    } on CollectionLoadException catch (e) {
        print('Error loading collection: ${e.toString()}');
    } on CollectionSaveException catch (e) {
        print('Error saving collection: ${e.toString()}');
    } on CollectionNotFoundException catch (e) {
        print("Collection not found: ${e.toString()}");
    } catch (e) {
        print('An unexpected error occurred: $e');
    }
    ```

## Core Classes

*   **`Database`:**
    *   Manages the storage path and access to collections.
    *   The `collection` method returns a collection for a specific name.

*   **`Collection`:**
    *   Represents a data collection and stores data as key-value pairs, with the optional `ttl`.
    *   Methods to `put`, `get`, `getAll`, and `delete` data.
    *   Manages indexing for faster lookups based on the specified fields.
    *   Manages pagination for retrieving the data in chunks.
    *   Provides transaction capabilities using the `startTransaction` method.

*   **`Transaction`:**
    *   Manages a transaction's state, to perform a series of operations atomically using locks.
    *   Has methods `put`, `delete`, `commit` and `rollback` to manage the transaction.

## Error Handling

The database uses custom exception classes for clear and detailed error reporting:

*   `DatabaseCreateException`
*   `CollectionLoadException`
*   `CollectionSaveException`
*   `CollectionNotFoundException`

These exceptions provide specific error messages, which you can use to provide feedback to your user, and to help debug.

## Contributions

Contributions are welcome! If you have ideas for enhancements or find any bugs, please feel free to:

1.  Fork the repository.
2.  Create a new branch for your feature or bug fix.
3.  Submit a pull request with your changes.

## Limitations

This project is intended for educational purposes and has a few limitations:

*   It is not a full-featured database.
*   Indexes are stored in memory and might slow down the application with a large number of indexed fields or with big datasets.
*   There is no support for complex queries or different types of storage formats.
*   Transactions have a simple locking mechanism that might block operations.
*   There is no scheduling for the TTL cleanup that will only happen when reading or retrieving all data.
*   The code has not been thoroughly tested and might have edge cases.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.