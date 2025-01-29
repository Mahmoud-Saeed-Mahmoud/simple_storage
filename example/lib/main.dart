import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:simple_storage/simple_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MainApp());

  try {
    // final dir = await getApplicationDocumentsDirectory();
    // final dbPath = dir.path;
    // This example uses a file storage adapter, which is not suitable for
    // production use. For a production-ready solution, you should use a
    // web storage adapter, such as the browser's local storage.
    final dbPath = './database';
    final db = Database(dbPath);

    final collection = await db.collection('test');

    await collection.put('int', 10);
    await collection.put('double', 10.5);
    await collection.put('bool', true);
    await collection.put('string', 'hello world');
    await collection.put('map', {"key": "value"});

    var intValue = await collection.get(key: 'int');
    var doubleValue = await collection.get(key: 'double');
    var boolValue = await collection.get(key: 'bool');
    var stringValue = await collection.get(key: 'string');
    var mapValue = await collection.get(key: 'map');

    debugPrint('int: $intValue type: ${intValue.runtimeType}');
    debugPrint('double: $doubleValue type: ${doubleValue.runtimeType}');
    debugPrint('bool: $boolValue type: ${boolValue.runtimeType}');
    debugPrint('string: $stringValue type: ${stringValue.runtimeType}');
    debugPrint('map: $mapValue type: ${mapValue.runtimeType}');

    var listAllValues = await collection.getAll();
    debugPrint(
        'listAllValues: $listAllValues type: ${listAllValues.runtimeType}');

    //   final users = await db.collection('users');

    //   final tasks = <Future>[];

    //   for (var i = 0; i < 10; i++) {
    //     tasks.add((() async {
    //       try {
    //         await users.put('$i', {'name': 'User $i', 'age': i},
    //             ttl: Duration(seconds: 5));
    //         print('User $i added with ttl');
    //         await Future.delayed(Duration(milliseconds: 500));
    //       } catch (e) {
    //         print("Error adding user: $e");
    //       }
    //     })());
    //   }
    //   await Future.wait(tasks);

    //   await Future.delayed(Duration(seconds: 5));

    //   final allUsers3 = await users.getAll();
    //   print('All users (after all TTL): ${allUsers3.length}');

    //   for (var i = 0; i < 10; i++) {
    //     final user = await users.get(key: '$i');
    //     print("User $i (after all TTL): $user");
    //   }
  } on DatabaseCreateException catch (e) {
    debugPrint("Database creation failed ${e.toString()}");
  } on CollectionLoadException catch (e) {
    debugPrint('Error loading collection: ${e.toString()}');
  } on CollectionSaveException catch (e) {
    debugPrint('Error saving collection: ${e.toString()}');
  } on CollectionNotFoundException catch (e) {
    debugPrint("Collection not found: ${e.toString()}");
  } catch (e) {
    debugPrint('An unexpected error occurred: $e');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
