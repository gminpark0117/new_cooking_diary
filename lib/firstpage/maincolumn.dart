import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import "addrecipecard.dart";
import "recipelist.dart";
import "../providers.dart";

class MainColumn extends ConsumerWidget {
  const MainColumn({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeProviderWatcher = ref.watch(recipeProvider);
    final recipes = recipeProviderWatcher.recipes;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return RecipeAdditionCard();
        }
        return RecipeEntry(recipe: recipes[index - 1]);
      },
    );
  }
}



/*
class AddRecipeCard extends ConsumerWidget {
  const AddRecipeCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final visibilityWatcher = ref.watch(addRecipeCardProvider);
    return (visibilityWatcher) ? RecipeAdditionCard() : SizedBox.shrink();

    return (visibilityWatcher)
      ? Column (
        children: [
          Text("추가!"),
          Row(
            children: [
              FilledButton (
                child: Text('추가'),
                onPressed: () {
                  // TODO: 더미 레시피 일단은...
                  final idx = Random().nextInt(10);
                  ref.read(recipeProvider.notifier).addRecipe(Recipe(
                      name: "Recipe $idx",
                      ingredients: ["test ingredient 0"],
                      steps: ["test steps 0"],
                    )
                  );
                },
              ),
              FilledButton (
                child: Text('취소'),
                onPressed: () {
                  ref.read(addRecipeCardProvider.notifier).state = false;
                },
              ),
            ],
          )
        ],
      )
    : SizedBox.shrink();

  }
}

*/