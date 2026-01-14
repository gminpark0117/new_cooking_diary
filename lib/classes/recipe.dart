import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class Recipe {
  static const Uuid _uuid = Uuid();
  Recipe({
    String? id,
    required this.name,
    required this.portionSize,
    required this.timeTaken,
    required this.ingredients,
    required this.steps,
    required this.memos,
    required this.mainImagePath,
    required List<String?> stepImagePaths,
  }) : id = (id ?? _uuid.v4()),
        stepImagePaths = _normalizeStepImagePaths(steps, stepImagePaths);

  final String id;
  final String name;
  final String? portionSize;
  final String? timeTaken;
  final List<String> ingredients;
  final List<String> steps;
  final List<String> memos;
  final String? mainImagePath;
  final List<String?> stepImagePaths;

  String meta() {
    return [
      if (portionSize != null) '분량: $portionSize',
      if (timeTaken != null) '시간: $timeTaken',
    ].join(' • ');
  }

  Recipe copyWith({
    String? name,
    String? portionSize,
    String? timeTaken,
    List<String>? ingredients,
    List<String>? steps,
    List<String>? memos,
    String? mainImagePath,
    List<String?>? stepImagePaths,
  }) {
    final newSteps = steps ?? this.steps;
    return Recipe(
      id: id,
      name: name ?? this.name,
      portionSize: portionSize ?? this.portionSize,
      timeTaken: timeTaken ?? this.timeTaken,
      ingredients: ingredients ?? this.ingredients,
      steps: newSteps,
      memos: memos ?? this.memos,
      mainImagePath: mainImagePath ?? this.mainImagePath,
      stepImagePaths: stepImagePaths ?? this.stepImagePaths,
    );
  }


  static List<String?> _normalizeStepImagePaths(
      List<String> steps,
      List<String?>? incoming,
      ) {
    if (incoming == null) return List<String?>.filled(steps.length, null);
    if (incoming.length == steps.length) return List<String?>.from(incoming);

    // If mismatch, pad/truncate to keep it safe.
    final out = List<String?>.filled(steps.length, null);
    for (var i = 0; i < steps.length && i < incoming.length; i++) {
      out[i] = incoming[i];
    }
    return out;
  }
}


class RecipeRepository {
  RecipeRepository(this._db);

  final AppDb _db;

  static const String _imagesDirName = 'recipe_images';

  Future<List<Recipe>> getAllRecipe() async {
    final db = await _db.db;

    final recipeRows = await db.query('recipes');
    final ingredientRows =
    await db.query('recipe_ingredients', orderBy: 'recipe_id, pos');
    final stepRows =
    await db.query('recipe_steps', orderBy: 'recipe_id, pos');
    final memoRows =
    await db.query('recipe_memos', orderBy: 'recipe_id, pos');

    final ingredientsBy = <String, List<String>>{};
    for (final r in ingredientRows) {
      final rid = r['recipe_id'] as String;
      (ingredientsBy[rid] ??= []).add(r['text'] as String);
    }

    final stepsBy = <String, List<String>>{};
    final stepImagesBy = <String, List<String?>>{};
    for (final r in stepRows) {
      final rid = r['recipe_id'] as String;
      (stepsBy[rid] ??= []).add(r['text'] as String);
      (stepImagesBy[rid] ??= []).add(_normalizeNullablePath(r['image_path'] as String?));
    }

    final memosBy = <String, List<String>>{};
    for (final r in memoRows) {
      final rid = r['recipe_id'] as String;
      (memosBy[rid] ??= []).add(r['text'] as String);
    }

    return recipeRows.map((r) {
      final id = r['id'] as String;
      final steps = stepsBy[id] ?? const [];
      final imgs = stepImagesBy[id] ?? const [];

      final normalizedImgs = List<String?>.filled(steps.length, null);
      for (var i = 0; i < steps.length && i < imgs.length; i++) {
        normalizedImgs[i] = imgs[i];
      }

      return Recipe(
        id: id,
        name: r['name'] as String,
        timeTaken: r['time'] as String?,
        portionSize: r['portion'] as String?,
        mainImagePath: _normalizeNullablePath(r['image_path'] as String?),
        ingredients: ingredientsBy[id] ?? const [],
        steps: steps,
        stepImagePaths: normalizedImgs,
        memos: memosBy[id] ?? const [],
      );
    }).toList();
  }

  /// Upsert recipe + copy images into app-managed directory.
  ///
  /// Behavior:
  /// - If recipe.mainImagePath is null/empty: stores NULL, deletes old managed main image (best-effort).
  /// - If recipe.stepImagePaths[i] is null/empty: stores NULL, deletes old managed step image for that pos (best-effort).
  /// - If provided path is outside app dir: copies to app dir and stores copied path.
  /// - If already under app dir: stores as-is.
  /// - After successful commit, deletes orphan managed images that are no longer referenced.
  Future<Recipe> upsertRecipe(Recipe recipe) async {
    final db = await _db.db;

    // Load old stored paths for cleanup comparison
    final oldMain = await _getExistingMainImagePath(db, recipe.id);
    final oldSteps = await _getExistingStepImagePathsByPos(db, recipe.id);

    final imagesDir = await _ensureImagesDir();

    // Normalize + decide main image path
    String? newMain = _normalizeNullablePath(recipe.mainImagePath);
    String? newlyCopiedMain;

    if (newMain != null) {
      final changed = oldMain == null || newMain != oldMain;
      if (changed) {
        newlyCopiedMain = await _copyIntoAppDir(
          sourcePath: newMain,
          imagesDir: imagesDir,
          filenamePrefix: 'recipe_${recipe.id}_main',
        );
        newMain = newlyCopiedMain;
      }
    }

    // Normalize + decide step image paths
    final newStepPaths = List<String?>.filled(recipe.steps.length, null);
    final newlyCopiedSteps = <String>[]; // for cleanup if DB fails

    for (var i = 0; i < recipe.steps.length; i++) {
      final incoming = _normalizeNullablePath(
        (i < recipe.stepImagePaths.length) ? recipe.stepImagePaths[i] : null,
      );

      if (incoming == null) {
        newStepPaths[i] = null;
        continue;
      }

      final oldAtPos = oldSteps[i];
      final changed = oldAtPos == null || incoming != oldAtPos;

      if (!changed) {
        // Keep as-is
        newStepPaths[i] = incoming;
        continue;
      }

      final copied = await _copyIntoAppDir(
        sourcePath: incoming,
        imagesDir: imagesDir,
        filenamePrefix: 'recipe_${recipe.id}_step_$i',
      );
      newlyCopiedSteps.add(copied);
      newStepPaths[i] = copied;
    }

    try {
      await db.transaction((txn) async {
        // upsert recipes row
        await txn.insert(
          'recipes',
          {
            'id': recipe.id,
            'name': recipe.name,
            'time': recipe.timeTaken,
            'portion': recipe.portionSize,
            'image_path': newMain,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Replace child rows (your original approach)
        await txn.delete('recipe_ingredients',
            where: 'recipe_id = ?', whereArgs: [recipe.id]);
        await txn.delete('recipe_steps',
            where: 'recipe_id = ?', whereArgs: [recipe.id]);
        await txn.delete('recipe_memos',
            where: 'recipe_id = ?', whereArgs: [recipe.id]);

        final batch = txn.batch();

        for (var i = 0; i < recipe.ingredients.length; i++) {
          batch.insert('recipe_ingredients', {
            'recipe_id': recipe.id,
            'pos': i,
            'text': recipe.ingredients[i],
          });
        }

        for (var i = 0; i < recipe.steps.length; i++) {
          batch.insert('recipe_steps', {
            'recipe_id': recipe.id,
            'pos': i,
            'text': recipe.steps[i],
            'image_path': newStepPaths[i],
          });
        }

        for (var i = 0; i < recipe.memos.length; i++) {
          batch.insert('recipe_memos', {
            'recipe_id': recipe.id,
            'pos': i,
            'text': recipe.memos[i],
          });
        }

        await batch.commit(noResult: true);
      });
    } catch (_) {
      // DB failed: delete any newly-copied files to avoid orphans
      if (newlyCopiedMain != null) {
        await _deleteFileBestEffort(newlyCopiedMain);
      }
      for (final p in newlyCopiedSteps) {
        await _deleteFileBestEffort(p);
      }
      rethrow;
    }

    // DB succeeded: cleanup old managed images that are no longer referenced
    final newReferenced = <String>{
      if (newMain != null) newMain,
      for (final s in newStepPaths)
        if (s != null) s,
    };

    final oldReferenced = <String>{
      if (oldMain != null) oldMain,
      for (final s in oldSteps.values)
        if (s != null) s,
    };

    // Delete any old managed path not referenced anymore
    for (final old in oldReferenced.difference(newReferenced)) {
      if (_isUnderDir(old, imagesDir)) {
        await _deleteFileBestEffort(old);
      }
    }

    return recipe.copyWith(
      mainImagePath: newMain,
      stepImagePaths: newStepPaths,
    );
  }

  Future<void> deleteRecipe(Recipe recipe) async {
    final db = await _db.db;

    final oldMain = await _getExistingMainImagePath(db, recipe.id);
    final oldSteps = await _getExistingStepImagePathsByPos(db, recipe.id);
    final imagesDir = await _ensureImagesDir();

    await db.delete('recipes', where: 'id = ?', whereArgs: [recipe.id]);

    // Best-effort delete managed images
    final toDelete = <String>{
      if (oldMain != null) oldMain,
      for (final s in oldSteps.values)
        if (s != null) s,
    };

    for (final path in toDelete) {
      if (_isUnderDir(path, imagesDir)) {
        await _deleteFileBestEffort(path);
      }
    }
  }

  // ---------- Helpers (very similar to your DiaryEntryRepository) ----------

  Future<String?> _getExistingMainImagePath(Database db, String recipeId) async {
    final rows = await db.query(
      'recipes',
      columns: ['image_path'],
      where: 'id = ?',
      whereArgs: [recipeId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _normalizeNullablePath(rows.first['image_path'] as String?);
  }

  /// Map pos -> image_path (nullable).
  Future<Map<int, String?>> _getExistingStepImagePathsByPos(
      Database db,
      String recipeId,
      ) async {
    final rows = await db.query(
      'recipe_steps',
      columns: ['pos', 'image_path'],
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'pos',
    );

    final out = <int, String?>{};
    for (final r in rows) {
      final pos = (r['pos'] as int?) ?? 0;
      out[pos] = _normalizeNullablePath(r['image_path'] as String?);
    }
    return out;
  }

  String? _normalizeNullablePath(String? path) {
    final s = path?.trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  Future<String> _ensureImagesDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = p.join(dir.path, _imagesDirName);

    final d = Directory(imagesDir);
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return imagesDir;
  }

  bool _isUnderDir(String filePath, String dirPath) {
    final normalizedFile = p.normalize(filePath);
    final normalizedDir = p.normalize(dirPath);

    final dirWithSep = normalizedDir.endsWith(p.separator)
        ? normalizedDir
        : '$normalizedDir${p.separator}';

    return normalizedFile.startsWith(dirWithSep);
  }

  Future<String> _copyIntoAppDir({
    required String sourcePath,
    required String imagesDir,
    required String filenamePrefix,
  }) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw StateError('Selected image file does not exist: $sourcePath');
    }

    final ext = p.extension(sourcePath); // ".jpg", ".png", ...
    final filename = '${filenamePrefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(imagesDir, filename);

    await sourceFile.copy(destPath);
    return destPath;
  }

  Future<void> _deleteFileBestEffort(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {
      // ignore
    }
  }
}


/*
class RecipeRepository {
  RecipeRepository(this._db);

  final AppDb _db;

  Future<List<Recipe>> getAllRecipe() async {
    final db = await _db.db;

    final recipeRows = await db.query('recipes');
    final ingredientRows = await db.query('recipe_ingredients', orderBy: 'recipe_id, pos');
    final stepRows = await db.query('recipe_steps', orderBy: 'recipe_id, pos');
    final memoRows = await db.query('recipe_memos', orderBy: 'recipe_id, pos');

    final ingredientsBy = <String, List<String>>{};

    for (final r in ingredientRows) {
      final rid = r['recipe_id'] as String;
      (ingredientsBy[rid] ??= []).add(r['text'] as String);
    }

    final stepsBy = <String, List<String>>{};
    final stepImagesBy = <String, List<String?>>{};
    for (final r in stepRows) {
      final rid = r['recipe_id'] as String;
      (stepsBy[rid] ??= []).add(r['text'] as String);
      (stepImagesBy[rid] ??= []).add(_normalizeNullablePath(r['image_path'] as String?));
    }

    final memosBy = <String, List<String>>{};
    for (final r in memoRows) {
      final rid = r['recipe_id'] as String;
      (memosBy[rid] ??= []).add(r['text'] as String);
    }

    return recipeRows.map((r) {
      final id = r['id'] as String;
      return Recipe(
        id: id,
        name: r['name'] as String,
        mainImagePath: r['image_path'] as String?,
        timeTaken: r['time'] as String?,
        portionSize: r['portion'] as String?,
        ingredients: ingredientsBy[id] ?? const [],
        steps: stepsBy[id] ?? const [],
        stepImagePaths: stepImagesBy[id] ?? const [],
        memos: memosBy[id] ?? const [],
      );
    }).toList();
  }

  Future<void> upsertRecipe(Recipe recipe) async {
    final db = await _db.db;

    await db.transaction((txn) async {
      await txn.insert(
        'recipes',
        {
          'id': recipe.id,
          'name': recipe.name,
          'time': recipe.timeTaken,
          'portion': recipe.portionSize,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete('recipe_ingredients',
          where: 'recipe_id = ?', whereArgs: [recipe.id]);
      await txn.delete('recipe_steps',
          where: 'recipe_id = ?', whereArgs: [recipe.id]);
      await txn.delete('recipe_memos',
          where: 'recipe_id = ?', whereArgs: [recipe.id]);

      final batch = txn.batch();

      for (var i = 0; i < recipe.ingredients.length; i++) {
        batch.insert('recipe_ingredients', {
          'recipe_id': recipe.id,
          'pos': i,
          'text': recipe.ingredients[i],
        });
      }

      for (var i = 0; i < recipe.steps.length; i++) {
        batch.insert('recipe_steps', {
          'recipe_id': recipe.id,
          'pos': i,
          'text': recipe.steps[i],
        });
      }

      for (var i = 0; i < recipe.memos.length; i++) {
        batch.insert('recipe_memos', {
          'recipe_id': recipe.id,
          'pos': i,
          'text': recipe.memos[i],
        });
      }

      await batch.commit(noResult: true);
    });
  }

  Future<void> deleteRecipe(Recipe recipe) async {
    final db = await _db.db;
    await db.delete('recipes', where: 'id = ?', whereArgs: [recipe.id]); // DELETE CASCADE가 나머지는 처리해줘요.
  }
}*/
