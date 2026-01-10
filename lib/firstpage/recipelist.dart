import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import "../recipe.dart";
import '../providers.dart';

/*
class RecipeList extends ConsumerWidget {
  const RecipeList({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeProviderWatcher = ref.watch(recipeProvider);

    final recipes = recipeProviderWatcher.recipes;
    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return RecipeEntry(recipe: recipes[index]);
      },
    );
  }
}
*/
class RecipeEntry extends ConsumerWidget {
  final Recipe recipe;

  const RecipeEntry({
    required this.recipe,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExpansionTile(
      title: Text(recipe.name),
      children: [
        // TODO: 레시피 디스플레이 구현 필요
        Text((recipe.portionSize == null) ? "not provided" : recipe.portionSize.toString()),
        Text((recipe.timeTaken == null) ? "not provided" : recipe.timeTaken.toString()),
        Text(recipe.ingredients[0]),
        Text(recipe.steps[0]),
        FilledButton (
          child: Text('삭제'),
          onPressed: () {
            ref.read(recipeProvider.notifier).deleteRecipe(recipe);
          },
        ),
      ],
    );
  }
}