import 'package:characters/characters.dart';

import 'public_db.dart';
import '../classes/recipe.dart';

class PublicRecipeSimilarity {
  // Singleton so every part of the app shares the same cache
  PublicRecipeSimilarity._(this._publicDb);

  static final PublicRecipeSimilarity instance =
  PublicRecipeSimilarity._(PublicRecipeDb.instance);

  final PublicRecipeDb _publicDb;

  static const int _returnLimit = 5;
  static const double _minScore = 0.15;

  static const Set<String> _staples = {
    "소금", "설탕", "후추", "물", "식용유", "올리브유", "참기름",
    "간장", "국간장", "다진마늘", "마늘", "파", "대파", "양파",
    "고춧가루", "고추장", "된장", "통깨", "다진 마늘", "맛술"
  };

  List<Recipe>? _cacheRecipes;

  /// Read-only view for other libraries
  List<Recipe> get cachedPublicRecipes =>
      List.unmodifiable(_cacheRecipes ?? const <Recipe>[]);

  /// Ensure cache is loaded (call at boot or lazily)
  Future<List<Recipe>> ensureLoaded() async {
    _cacheRecipes ??= await loadAllRecipes();
    return _cacheRecipes!;
  }

  Future<void> warmUp() async {
    await ensureLoaded();
  }

  Future<List<Recipe>> findSimilar(Recipe query) async {
    final all = await ensureLoaded();

    final queryNameNorm = _normalizeKo(query.name);
    final queryIngSet = _normalizedIngredientSet(query.ingredients);

    final scored = <({Recipe recipe, double score})>[];

    for (final r in all) {
      // Skip exact same recipe (by id)
      if (query.id == r.id) continue;

      final nameNorm = _normalizeKo(r.name);
      final ingSet = _normalizedIngredientSet(r.ingredients);

      final nameSimUni = _unigramJaccard(queryNameNorm, nameNorm);
      final nameSimBi = _bigramJaccard(queryNameNorm, nameNorm);
      final ingSim = _jaccard(queryIngSet, ingSet);

      final score = 0.50 * ingSim + 0.35 * nameSimBi + 0.15 * nameSimUni;
      if (score >= _minScore) {
        scored.add((recipe: r, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(_returnLimit).map((e) => e.recipe).toList();
  }

  /// Loads ALL public recipes fully (base + ingredients + steps)
  Future<List<Recipe>> loadAllRecipes() async {
    final db = await _publicDb.db;

    final baseRows = await db.rawQuery('''
      SELECT id, name, portion_size, time_taken
      FROM public_recipes
    ''');

    final ingRows = await db.rawQuery('''
      SELECT recipe_id, pos, text
      FROM public_recipe_ingredients
      ORDER BY recipe_id, pos;
    ''');

    final stepRows = await db.rawQuery('''
      SELECT recipe_id, pos, text
      FROM public_recipe_steps
      ORDER BY recipe_id, pos;
    ''');

    final ingsById = <String, List<String>>{};
    for (final r in ingRows) {
      final id = r['recipe_id'] as String;
      (ingsById[id] ??= []).add((r['text'] as String).trim());
    }

    final stepsById = <String, List<String>>{};
    for (final r in stepRows) {
      final id = r['recipe_id'] as String;
      (stepsById[id] ??= []).add((r['text'] as String).trim());
    }

    return baseRows.map((r) {
      final id = r['id'] as String;
      return Recipe(
        id: id, // keep public DB id
        name: r['name'] as String,
        timeTaken: r['time_taken'] as String?,
        portionSize: r['portion_size'] as String?,
        ingredients: ingsById[id] ?? const [],
        steps: stepsById[id] ?? const [],
        memos: const [],
      );
    }).toList();
  }

  // -----------------------------
  // Similarity utilities
  // -----------------------------

  String _normalizeKo(String s) {
    var x = s.trim();
    x = x.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    x = x.replaceAll(RegExp(r'[^0-9A-Za-z가-힣\s]'), ' ');
    x = x.replaceAll(RegExp(r'\s+'), ' ').trim();
    return x;
  }

  Set<String> _normalizedIngredientSet(List<String> ingredients) {
    final set = <String>{};
    for (final raw in ingredients) {
      final ing = _normalizeKo(raw);
      if (ing.isEmpty) continue;
      if (_staples.contains(ing)) continue;
      set.add(ing);
    }
    return set;
  }

  List<String> _bigrams(String s) {
    final compact = s.replaceAll(RegExp(r'\s+'), '');
    if (compact.length < 2) return const [];
    return List.generate(compact.length - 1, (i) => compact.substring(i, i + 2));
  }

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final inter = a.intersection(b).length;
    final uni = a.union(b).length;
    return inter / uni;
  }

  double _bigramJaccard(String a, String b) {
    final as = _bigrams(a).toSet();
    final bs = _bigrams(b).toSet();
    if (as.isEmpty || bs.isEmpty) return 0.0;
    final inter = as.intersection(bs).length;
    final uni = as.union(bs).length;
    return inter / uni;
  }

  double _unigramJaccard(String a, String b) {
    final as = a.characters.toSet();
    final bs = b.characters.toSet(); // FIX: was incorrectly using `a` twice
    if (as.isEmpty || bs.isEmpty) return 0.0;
    final inter = as.intersection(bs).length;
    final uni = as.union(bs).length;
    return inter / uni;
  }
}
