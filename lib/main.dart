import 'package:flutter/material.dart';
import 'views/decklist.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> initializeApp() async {
  // ensure that flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await loadJsonDataToDB();
}

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  await initializeApp();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DeckList(),
  ));
}
