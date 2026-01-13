import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDb {
  static final AppDb instance = AppDb._();
  AppDb._();

  Database? _db;

  Future<Database> get db async {
    final existing = _db;
    if (existing != null) return existing;

    _db = await openDatabase(
      p.join(await getDatabasesPath(), 'app_database.db'),
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recipes (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            time TEXT,
            portion TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE recipe_ingredients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recipe_id TEXT NOT NULL,
            pos INTEGER NOT NULL,
            text TEXT NOT NULL,
            FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
            UNIQUE(recipe_id, pos)
          );
        ''');

        await db.execute('''
          CREATE TABLE recipe_steps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recipe_id TEXT NOT NULL,
            pos INTEGER NOT NULL,
            text TEXT NOT NULL,
            FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
            UNIQUE(recipe_id, pos)
          );
        ''');

        await db.execute('''
          CREATE TABLE recipe_memos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recipe_id TEXT NOT NULL,
            pos INTEGER NOT NULL,
            text TEXT NOT NULL,
            FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
            UNIQUE(recipe_id, pos)
          );
        ''');

        await db.execute('''
            CREATE TABLE diary_entries (
            id TEXT PRIMARY KEY,
            image_path TEXT,
            recipe_name TEXT NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL
          );
          '''); //TODO: create index?

        await db.execute('''
          CREATE TABLE groceries (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          recipe_name TEXT
        );
        ''');

        await db.execute(
          'CREATE INDEX idx_ingredients_recipe ON recipe_ingredients(recipe_id, pos);',
        );
        await db.execute(
          'CREATE INDEX idx_steps_recipe ON recipe_steps(recipe_id, pos);',
        );
        await db.execute(
          'CREATE INDEX idx_memos_recipe ON recipe_memos(recipe_id, pos);',
        );
      },
    );

    return _db!;
  }
}
