import 'package:flutter/material.dart';
import 'package:simple_storage/simple_storage.dart';
// import 'package:path_provider/path_provider.dart';

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

    final users = await db.collection('users');

    final tasks = <Future>[];

    for (var i = 0; i < 10; i++) {
      tasks.add((() async {
        try {
          await users.put('$i', {'name': 'User $i', 'age': i},
              ttl: Duration(seconds: 5));
          print('User $i added with ttl');
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          print("Error adding user: $e");
        }
      })());
    }
    await Future.wait(tasks);

    await Future.delayed(Duration(seconds: 5));

    final allUsers3 = await users.getAll();
    print('All users (after all TTL): ${allUsers3.length}');

    for (var i = 0; i < 10; i++) {
      final user = await users.get(key: '$i');
      print("User $i (after all TTL): $user");
    }
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
