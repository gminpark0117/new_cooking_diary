import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import "./recipe.dart";
import './providers.dart';


class MainColumn extends ConsumerWidget {
  const MainColumn({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: .center,
      children: [
        FilledButton (
          child: Text('레시피 추가'),
          onPressed: () {
            ref.read(addRecipeCardProvider.notifier).state = true;
          },
        ),
        AddRecipeCard(),
        RecipeList(),
      ],
    );
  }
}

class RecipeList extends ConsumerWidget {
  const RecipeList({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeProviderWatcher = ref.watch(recipeProvider);

    final recipes = recipeProviderWatcher.recipes;
    return Expanded(
      child: ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          return RecipeEntry(recipe: recipes[index]);
        },
      ),
    );
  }
}

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

class AddRecipeCard extends ConsumerWidget {
  const AddRecipeCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityWatcher = ref.watch(addRecipeCardProvider);
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

