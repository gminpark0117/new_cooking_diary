import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import "../recipe.dart";
import '../providers.dart';

/*
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

 */

class RecipeEntry extends StatelessWidget {
  const RecipeEntry({
    super.key,
    required this.recipe,
  });

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final meta = [
      '${recipe.portionSize} servings',
      '${recipe.timeTaken} min',
    ].join(' • ');

    final ingredients = recipe.ingredients
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final steps = recipe.steps
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding:
        const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        title: Text(
          recipe.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: meta.isEmpty
            ? null
            : Text(
          meta,
          style: theme.textTheme.bodySmall,
        ),
        children: [
          _SectionHeader(title: 'Ingredients'),
          const SizedBox(height: 6),
          if (ingredients.isEmpty)
            Text(
              'No ingredients.',
              style: theme.textTheme.bodySmall,
            )
          else
            ...ingredients.map(
                  (ing) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(ing)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          _SectionHeader(title: 'Steps'),
          const SizedBox(height: 6),
          if (steps.isEmpty)
            Text(
              'No steps.',
              style: theme.textTheme.bodySmall,
            )
          else
            ...steps.asMap().entries.map(
                  (entry) {
                final i = entry.key;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text('${i + 1}.'),
                      ),
                      Expanded(child: Text(step)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
