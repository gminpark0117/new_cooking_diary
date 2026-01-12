import 'package:uuid/uuid.dart';
import 'database.dart';
import 'package:sqflite/sqflite.dart';

var uuid = Uuid();
class Recipe {

  Recipe({
    String? id,
    required this.name,
    required this.portionSize,
    required this.timeTaken,
    required this.ingredients,
    required this.steps,
  }) : id = (id ?? uuid.v4());

  final String id;
  final String name;
  final String? portionSize;
  final String? timeTaken;
  final List<String> ingredients;
  final List<String> steps;
}

class RecipeRepository {
  RecipeRepository(this._db);

  final AppDb _db;

  Future<List<Recipe>> getAllRecipe() async {
    final db = await _db.db;

    final recipeRows = await db.query('recipes');
    final ingredientRows = await db.query('recipe_ingredients', orderBy: 'recipe_id, pos');
    final stepRows = await db.query('recipe_steps', orderBy: 'recipe_id, pos');

    final ingredientsBy = <String, List<String>>{};
    for (final r in ingredientRows) {
      final rid = r['recipe_id'] as String;
      (ingredientsBy[rid] ??= []).add(r['text'] as String);
    }

    final stepsBy = <String, List<String>>{};
    for (final r in stepRows) {
      final rid = r['recipe_id'] as String;
      (stepsBy[rid] ??= []).add(r['text'] as String);
    }

    return recipeRows.map((r) {
      final id = r['id'] as String;
      return Recipe(
        id: id,
        name: r['name'] as String,
        timeTaken: r['time'] as String?,
        portionSize: r['portion'] as String?,
        ingredients: ingredientsBy[id] ?? const [],
        steps: stepsBy[id] ?? const [],
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

      await batch.commit(noResult: true);
    });
  }

  Future<void> deleteRecipe(Recipe recipe) async {
    final db = await _db.db;
    await db.delete('recipes', where: 'id = ?', whereArgs: [recipe.id]); // DELETE CASCADE가 나머지는 처리해줘요.
  }
}