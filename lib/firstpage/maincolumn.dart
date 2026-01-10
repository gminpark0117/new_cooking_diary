import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import "recipeadditioncard.dart";
import "recipentry.dart";
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


