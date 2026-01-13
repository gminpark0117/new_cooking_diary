import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_cooking_diary/classes/grocery.dart';
import 'package:new_cooking_diary/data/recipe_provider.dart';
import 'package:new_cooking_diary/main.dart';

import "../classes/recipe.dart";
import "../data/grocery_provider.dart";
import "../public_db/public_search.dart";


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

class RecipeDetail extends StatelessWidget {

  RecipeDetail({
    super.key,
    required this.recipe,
    required this.onEditCallback,
    required this.onDeleteCallback,
  });

  final Recipe recipe;
  final publicRecipeSimilarity = PublicRecipeSimilarity();

  final VoidCallback onEditCallback; // the parent (mainColumn) should have the recipe info.
  final VoidCallback onDeleteCallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
              child: RecipeIngAndSteps(recipe: recipe),
            ),
          ],
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
class RecipeIngAndSteps extends ConsumerStatefulWidget {
  const RecipeIngAndSteps({
    super.key,
    required this.recipe,
  });
  final Recipe recipe;

  @override
  ConsumerState<RecipeIngAndSteps> createState() => _RecipeIngAndStepsState();
}
class _RecipeIngAndStepsState extends ConsumerState<RecipeIngAndSteps> {
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // so it works inside another scroll view
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 8,
              childAspectRatio: 4.5, // tweak for your UI
            ),
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              final ing = ingredients[index];
              final checked = _checkedIngredientIndexes.contains(index);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (checked) {
                      _checkedIngredientIndexes.remove(index);
                    } else {
                      _checkedIngredientIndexes.add(index);
                    }
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: checked,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _checkedIngredientIndexes.add(index);
                          } else {
                            _checkedIngredientIndexes.remove(index);
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        ing,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ,
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

class RecipeEntryPage extends ConsumerStatefulWidget {
  const RecipeEntryPage({
  super.key,
  required this.baseRecipe,
  required this.onEditCallback,
  required this.onDeleteCallback,
  required this.onGoBackCallback,
  });
  final Recipe baseRecipe;
  final VoidCallback onEditCallback; // the parent (mainColumn) should have the recipe info.
  final VoidCallback onDeleteCallback;
  final VoidCallback onGoBackCallback;

  @override
  ConsumerState<RecipeEntryPage> createState() => _RecipeEntryPageState();
}

class _RecipeEntryPageState extends ConsumerState<RecipeEntryPage> {
  List<Recipe> recipeStack = [];
  Future<List<Recipe>>? _similarFuture;

  @override
  void initState() {
    super.initState();
    recipeStack = [widget.baseRecipe];
    _similarFuture = publicRecipeSimilarity.findSimilar(recipeStack.last);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  final _scrollController = ScrollController();

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  void _popRecipeOrGoBack() {
    if (recipeStack.length == 1) {
      widget.onGoBackCallback();
    } else {
      setState(() {
        recipeStack.removeLast();
        _similarFuture = publicRecipeSimilarity.findSimilar(recipeStack.last);
      });
    }
  }

  void _pushRecipe(Recipe r) {
    setState(() {
      recipeStack.add(r);
      _similarFuture = publicRecipeSimilarity.findSimilar(recipeStack.last);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop());
  }

  @override
  Widget build(BuildContext context) {
    final widgetsInList = <Widget>[
      RecipeDetail(
        recipe: recipeStack.last,
        onEditCallback: widget.onEditCallback,
        onDeleteCallback: widget.onDeleteCallback,
      ),
      const Divider(height: 24, thickness: 1, indent: 8, endIndent: 8),
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12, left: 20),
        child: Text(
          '비슷한 추천 레시피:',
          style: Theme
              .of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Similar section lives here
      FutureBuilder<List<Recipe>>(
        future: _similarFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 200),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final similarRecipes = snapshot.data ?? const <Recipe>[];
          if (similarRecipes.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('추천 레시피가 없습니다.'),
            );
          }

          return Column(
            children: similarRecipes
                .map((r) =>
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: RecipePreview(
                    recipe: r,
                    pressedCallback: _pushRecipe,
                  ),
                ))
                .toList(),
          );
        },
      ),

      const SizedBox(height: 4),

      // Your bottom buttons (same as now)
      if (recipeStack.length == 1)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ElevatedButton(
            onPressed: _popRecipeOrGoBack,
            child: const Text('뒤로가기'),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await ref
                        .read(recipeProvider.notifier)
                        .upsertRecipe(recipeStack.last);
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('레시피를 추가했습니다.')),
                    );
                  },
                  child: const Text('레시피 저장'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _popRecipeOrGoBack,
                  child: const Text('뒤로가기'),
                ),
              ),
            ],
          ),
        ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _popRecipeOrGoBack();
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widgetsInList.length,
        itemBuilder: (context, index) => widgetsInList[index],
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