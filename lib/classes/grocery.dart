import 'package:flutter/rendering.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database.dart';

class Grocery {
  static const Uuid _uuid = Uuid();
  Grocery({
    String? id,
    required this.name,
    this.recipeName,
  }) : id = id ?? _uuid.v4();

  final String id;
  final String name;
  final String? recipeName;
}

class GroceryRepository {
  GroceryRepository(this._db);

  final AppDb _db;

  Future<List<Grocery>> getAllGroceries() async {
    final db = await _db.db;

    final rows = await db.query('groceries');
    return rows.map((r) {
      return Grocery(
        id: r['id'] as String,
        name: r['name'] as String,
        recipeName: r['recipe_name'] as String?,
      );
    }).toList();
  }

  Future<void> upsertGrocery(Grocery grocery) async {
    final db = await _db.db;
    debugPrint("\n\n\ncalling upsert.. grocery: ${grocery.id}\n\n\n\n");
    await db.insert(
      'groceries',
      {
        'id': grocery.id,
        'name': grocery.name,
        'recipe_name': grocery.recipeName,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteGrocery(Grocery grocery) async {
    final db = await _db.db;

    await db.delete(
      'groceries',
      where: 'id = ?',
      whereArgs: [grocery.id],
    );
  }
}