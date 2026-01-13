import 'package:sqflite/sqflite.dart';
import 'public_db.dart';

import '../classes/recipe.dart';


class PublicRecipeSimilarity {
  PublicRecipeSimilarity({PublicRecipeDb? publicDb})
      : _publicDb = publicDb ?? PublicRecipeDb.instance;

  final PublicRecipeDb _publicDb;

  static const int _returnLimit = 5;
  static const double _minScore = 0.07;

  static const Set<String> _staples = {
    "소금", "설탕", "후추", "물", "식용유", "올리브유", "참기름",
    "간장", "국간장", "다진마늘", "마늘", "파", "대파", "양파"
  };

  List<_PublicIndexRow>? _cache; // in-memory index

  Future<void> warmUp() async {
    _cache ??= await _loadIndex();
  }

  Future<List<Recipe>> findSimilar(Recipe query) async {
    // Ensure cache loaded
    _cache ??= await _loadIndex();

    final queryNameNorm = _normalizeKo(query.name);
    final queryIngSet = _normalizedIngredientSet(query.ingredients);

    final scored = <({String id, double score})>[];

    for (final r in _cache!) {
      final nameSim = _bigramJaccard(queryNameNorm, r.nameNorm);
      final ingSim = _jaccard(queryIngSet, r.ingSet);

      final score = 0.6 * ingSim + 0.4 * nameSim;
      if (query.id != r.id && score >= _minScore) {
        scored.add((id: r.id, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    final topIds = scored.take(_returnLimit).map((e) => e.id).toList();
    if (topIds.isEmpty) return [];

    // Load full recipes for top IDs
    final db = await _publicDb.db;
    return _loadRecipesByIds(db, topIds);
  }

  // -----------------------------
  // One-time index load (fast)
  // -----------------------------

  Future<List<_PublicIndexRow>> _loadIndex() async {
    final db = await _publicDb.db;

    // Load recipe base info
    final base = await db.rawQuery('SELECT id, name FROM public_recipes;');

    // Load all ingredients
    final ingRows = await db.rawQuery('''
      SELECT recipe_id, pos, text
      FROM public_recipe_ingredients
      ORDER BY recipe_id, pos;
    ''');

    final ingsById = <String, List<String>>{};
    for (final r in ingRows) {
      final id = r['recipe_id'] as String;
      final text = (r['text'] as String).trim();
      (ingsById[id] ??= []).add(text);
    }

    final out = <_PublicIndexRow>[];
    for (final row in base) {
      final id = row['id'] as String;
      final name = row['name'] as String;

      final ingList = ingsById[id] ?? const [];
      out.add(_PublicIndexRow(
        id: id,
        nameNorm: _normalizeKo(name),
        ingSet: _normalizedIngredientSet(ingList),
      ));
    }
    return out;
  }

  // -----------------------------
  // Load full recipes for results
  // -----------------------------

  Future<List<Recipe>> _loadRecipesByIds(Database db, List<String> idsInOrder) async {
    final placeholders = List.filled(idsInOrder.length, '?').join(',');

    final baseRows = await db.rawQuery('''
      SELECT id, name, portion_size, time_taken
      FROM public_recipes
      WHERE id IN ($placeholders);
    ''', idsInOrder);

    final ingRows = await db.rawQuery('''
      SELECT recipe_id, pos, text
      FROM public_recipe_ingredients
      WHERE recipe_id IN ($placeholders)
      ORDER BY recipe_id, pos;
    ''', idsInOrder);

    final stepRows = await db.rawQuery('''
      SELECT recipe_id, pos, text
      FROM public_recipe_steps
      WHERE recipe_id IN ($placeholders)
      ORDER BY recipe_id, pos;
    ''', idsInOrder);

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

    final byId = <String, Recipe>{};
    for (final row in baseRows) {
      final id = row['id'] as String;
      byId[id] = Recipe(
        id: id, // public DB id 그대로
        name: row['name'] as String,
        portionSize: row['portion_size'] as String?,
        timeTaken: row['time_taken'] as String?,
        ingredients: ingsById[id] ?? const [],
        steps: stepsById[id] ?? const [],
        memos: const [],
      );
    }

    return idsInOrder.where(byId.containsKey).map((id) => byId[id]!).toList();
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
}

class _PublicIndexRow {
  _PublicIndexRow({
    required this.id,
    required this.nameNorm,
    required this.ingSet,
  });

  final String id;
  final String nameNorm;
  final Set<String> ingSet;
}
