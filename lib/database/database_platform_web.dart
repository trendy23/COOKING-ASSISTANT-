import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<String> configureDatabasePlatform(String databaseName) async {
  databaseFactory = databaseFactoryFfiWeb;
  return databaseName;
}
