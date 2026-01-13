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
    this.checked = false, // ✅ 추가
  }) : id = id ?? _uuid.v4();

  final String id;
  final String name;
  final String? recipeName;
  final bool checked; // ✅ 추가

  Grocery copyWith({
    String? id,
    String? name,
    String? recipeName,
    bool? checked,
  }) {
    return Grocery(
      id: id ?? this.id,
      name: name ?? this.name,
      recipeName: recipeName ?? this.recipeName,
      checked: checked ?? this.checked,
    );
  }
}

class GroceryRepository {
  GroceryRepository(this._db);

  final AppDb _db;

  Future<List<Grocery>> getAllGroceries() async {
    final db = await _db.db;

    final rows = await db.query(
      'groceries',
      orderBy: 'rowid DESC', // 최신 수정된 것이 맨 위
    );

    return rows.map((r) {
      return Grocery(
        id: r['id'] as String,
        name: r['name'] as String,
        recipeName: r['recipe_name'] as String?,
        checked: ((r['checked'] as int?) ?? 0) == 1, // ✅ 로딩
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
        'checked': grocery.checked ? 1 : 0, // ✅ 저장
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ✅ 체크만 빠르게 토글하고 싶을 때 (추천)
  Future<void> setChecked({
    required String id,
    required bool checked,
  }) async {
    final db = await _db.db;
    await db.update(
      'groceries',
      {'checked': checked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
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
