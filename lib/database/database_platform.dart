import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<String> configureDatabasePlatform(String databaseName) async =>
    join(await getDatabasesPath(), databaseName);
