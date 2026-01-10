import "./recipe.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecipeState {
  final List<Recipe> recipes;
  const RecipeState(this.recipes);
}

class RecipeNotifier extends StateNotifier<RecipeState> {
  RecipeNotifier() : super(RecipeState([]));

  void addRecipe(Recipe recipe) {
    state = RecipeState([...state.recipes, recipe]);
  }

  List<Recipe> getRecipe({String filter = ''}) {
    return state.recipes.where((r) => r.name.contains(filter)).toList();
  }

  void updateRecipe(Recipe oldRecipe, Recipe newRecipe) {
    final targetIdx = state.recipes.indexWhere((r) => r.id == oldRecipe.id);
    if (targetIdx == -1) {
      throw Exception("exception in RecipeNotifier.updateRecipe: recipe not found in recipe list");
    }

    state = RecipeState([
      ...state.recipes.sublist(0, targetIdx),
      newRecipe,
      ...state.recipes.sublist(targetIdx+1),
    ]);
  }

  void deleteRecipe(Recipe recipe) {
    state = RecipeState(List.of(state.recipes)..remove(recipe));
  }
}

final recipeProvider =
StateNotifierProvider<RecipeNotifier, RecipeState>((ref) {
  return RecipeNotifier();
});
