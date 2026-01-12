import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_cooking_diary/classes/grocery.dart';

import "../classes/recipe.dart";
import "../data/grocery_provider.dart";

class RecipeDescription extends ConsumerStatefulWidget {
  const RecipeDescription({
    super.key,
    required this.recipe,
  });
  final Recipe recipe;

  @override
  ConsumerState<RecipeDescription> createState() => _RecipeDescriptionState();
}

class _RecipeDescriptionState extends ConsumerState<RecipeDescription> {
  final Set<int> _checkedIngredientIndexes = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ingredients = widget.recipe.ingredients
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final steps = widget.recipe.steps
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final memos = widget.recipe.memos
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: '재료'),
        const SizedBox(height: 6),
        if (ingredients.isEmpty)
          Text(
            '재료 없음.',
            style: theme.textTheme.bodySmall,
          )
        else
          ...ingredients.asMap().entries.map((entry) {
            final index = entry.key;
            final ing = entry.value;
            final checked = _checkedIngredientIndexes.contains(index);
            return CheckboxListTile(
                value: checked,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                dense: true,
                title: Text(ing),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _checkedIngredientIndexes.add(index);
                    } else {
                      _checkedIngredientIndexes.remove(index);
                    }
                  });
                }
            );
          }),
        const SizedBox(height:10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              for (final idx in _checkedIngredientIndexes) {
                await ref.read(groceryProvider.notifier).upsertGrocery(
                  Grocery(name: widget.recipe.ingredients[idx], recipeName: widget.recipe.name)
                );
              }
              if (_checkedIngredientIndexes.isNotEmpty) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(content: Text('장바구니에 추가되었습니다.')),
                );
              }
            },
            child: const Text('장바구니에 추가'),
          ),
        ),
        const SizedBox(height: 20),


        _SectionHeader(title: '단계'),
        const SizedBox(height: 6),
        if (steps.isEmpty)
          Text(
            '단계 없음.',
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
                      width: 20,
                      child: Text('${i + 1}.'),
                    ),
                    Expanded(child: Text(step)),
                  ],
                ),
              );
            },
          ),
        if (memos.isNotEmpty)
          Divider(height: 24,thickness: 1,indent: 8,endIndent: 8,),

        // this still shows nothing if memos is empty
        ...memos.map(
              (memo) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(' - '),
                  ),
                  Expanded(child: Text(memo)),
                ],
              ),
            );
          },
        ),

      ],
    );

  }
}

class RecipePreview extends StatelessWidget {

  const RecipePreview({
    super.key,
    required this.recipe,
    required this.pressedCallback,
  });

  final Recipe recipe;
  final void Function(Recipe recipe) pressedCallback;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: ElevatedButton(
          onPressed: () {
            pressedCallback(recipe);
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                recipe.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                recipe.meta(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeDetailPage extends StatelessWidget {

  const RecipeDetailPage({
    super.key,
    required this.recipe,
    required this.onEditCallback,
    required this.onDeleteCallback,
    required this.onGoBackCallback,
  });

  final Recipe recipe;
  final VoidCallback onEditCallback; // the parent (mainColumn) should have the recipe info.
  final VoidCallback onDeleteCallback;
  final VoidCallback onGoBackCallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onGoBackCallback();
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (recipe.meta().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                recipe.meta(),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            iconSize: 26,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.standard,
                            tooltip: '레시피 수정',
                            onPressed: () {
                              onEditCallback();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            iconSize: 26,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.standard ,
                            tooltip: '레시피 삭제',
                            onPressed: onDeleteCallback,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: RecipeDescription(recipe: recipe),
                ),
              ],
            ),
          ),
        ),
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
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/*
class RecipeEntryDepreciated extends ConsumerStatefulWidget {
  const RecipeEntryDepreciated({
    super.key,
    required this.recipe,
  });

  final Recipe recipe;

  @override
  ConsumerState<RecipeEntryDepreciated> createState() => _RecipeEntryDepreciatedState();
}

class _RecipeEntryDepreciatedState extends ConsumerState<RecipeEntryDepreciated> {
  bool _inEditMode = false;
  final _expansionController = ExpansibleController();

  @override void dispose() {
    _expansionController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(Recipe recipe) async {
    try {
      await ref.read(recipeProvider.notifier).upsertRecipe(recipe);

      if (!mounted) return;
      setState(() {
        _inEditMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('레시피 저장 중 오류: $e')),
      );
    }
  }

  void _onCancel() {
    setState(() {
      _inEditMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    final targetChild = _inEditMode
        ? RecipeAdditionCard(titleString: "레시피 수정", onSubmitCallback: _onSubmit, onCancelCallback: _onCancel, initialRecipe: widget.recipe,)
        : RecipeDescription(recipe: widget.recipe);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: ExpansionTile(
          controller: _expansionController,
          maintainState: true,
          initiallyExpanded: _inEditMode,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding:
          const EdgeInsets.only(left: 16, right: 16, bottom: 16),

          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                tooltip: '레시피 수정',
                onPressed: () {
                  setState(() {
                    _expansionController.expand();
                    _inEditMode = true;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                tooltip: '레시피 삭제',
                onPressed: () async {
                  try {
                    await ref.read(recipeProvider.notifier).deleteRecipe(
                        widget.recipe);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('레시피 삭제 중 오류: $e')),
                    );
                  }
                }
              ),
            ],
          ),

          title: Text(
            widget.recipe.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: widget.recipe.meta().isEmpty
              ? null
              : Text(
            widget.recipe.meta(),
            style: theme.textTheme.bodySmall,
          ),
          children: [targetChild],
        ),
      ),
    );
  }
}

*/