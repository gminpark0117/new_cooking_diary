import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class PublicRecipeDb {
  static final PublicRecipeDb instance = PublicRecipeDb._();
  PublicRecipeDb._();

  Database? _db;

  Future<Database> get db async {
    final existing = _db;
    if (existing != null) return existing;

    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'public_recipes.db');

    final file = File(dbPath);
    if (!await file.exists()) {
      final bytes = await rootBundle.load('assets/db/public_recipes.db');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    }

    _db = await openDatabase(dbPath, readOnly: true);
    return _db!;
  }
}
