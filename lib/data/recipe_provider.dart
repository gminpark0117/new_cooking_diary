import 'package:flutter_riverpod/flutter_riverpod.dart';

import "../classes/recipe.dart";
import "database.dart";

class RecipeNotifier extends AsyncNotifier<List<Recipe>> {
  late final _repo = ref.read(recipeRepoProvider);

  @override
  Future<List<Recipe>> build() async {
    return _repo.getAllRecipe();
  }

  List<Recipe> getRecipe({String filter = ''}) {
    return (state.value ?? const <Recipe>[]).where((r) => r.name.contains(filter)).toList();
  }

  Future<void> upsertRecipe(Recipe recipe) async {
    final previous = state.value ?? const <Recipe>[];
    state = AsyncData(_upsertInList(previous, recipe));

    state = await AsyncValue.guard(() async {
      await _repo.upsertRecipe(recipe);
      return _repo.getAllRecipe();
    });
  }

  List<Recipe> _upsertInList(List<Recipe> list, Recipe recipe) {
    final idx = list.indexWhere((r) => r.id == recipe.id);
    if (idx == -1) return [...list, recipe];
    return [...list.sublist(0, idx), recipe, ...list.sublist(idx + 1)];
  }

  Future<void> deleteRecipe(Recipe recipe) async {
    final previous = state.value ?? const <Recipe>[];
    state = AsyncData(previous.where((r) => r.id != recipe.id).toList());

    state = await AsyncValue.guard(() async {
      await _repo.deleteRecipe(recipe);
      return _repo.getAllRecipe();
    });
  }
}

final recipeProvider =
AsyncNotifierProvider<RecipeNotifier, List<Recipe>>(RecipeNotifier.new);

// AI 말로는 recipeNotifier가 리빌드되도 같은 RecipeRepository 인스턴스를 가리키도록? 얘를 provider로 감싸라네요. 사실 AppDb.instance도 한번 싸야된다는데
final recipeRepoProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(AppDb.instance);
});
