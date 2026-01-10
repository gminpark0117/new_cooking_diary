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

  void deleteRecipe(Recipe recipe) {
    state = RecipeState(List.of(state.recipes)..remove(recipe));
  }
}

final recipeProvider =
StateNotifierProvider<RecipeNotifier, RecipeState>((ref) {
  return RecipeNotifier();
});

final addRecipeCardProvider = StateProvider<bool>((ref) => false);