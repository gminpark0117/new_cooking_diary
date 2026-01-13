import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import "recipeadditioncard.dart";
import "recipentry.dart";
import "../data/recipe_provider.dart";
import "../classes/recipe.dart";
import "../widgets/search_field.dart";
import '../main.dart';

class RecipeAddHeader extends ConsumerWidget {
  const RecipeAddHeader({
    super.key,
    required this.addCallback,
  });

  final VoidCallback addCallback;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 8, left: 16, right: 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text(
                '레시피 추가',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: addCallback,

              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB65A2C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        /*if (_showRecipeAdditionCard)
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Card(
                elevation: 4,
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: RecipeAdditionCard(titleString: "새 레시피", onSubmitCallback: _onSubmit, onCancelCallback: _onCancel,),
                    )
                )
            ),
          )*/
      ],
    );
  }
}

final tab0TapTokenProvider = StateProvider<int>((ref) => 0);

sealed class _DisplayMode {
  const _DisplayMode();
}

class _DefaultMode extends _DisplayMode {
  const _DefaultMode();
}

class _AddMode extends _DisplayMode {
  const _AddMode();
}

class _ViewMode extends _DisplayMode {
  const _ViewMode(this.recipe);
  final Recipe recipe;
}

class _EditMode extends _DisplayMode {
  const _EditMode(this.initialRecipe);
  final Recipe initialRecipe;
}

class RecipePageMainColumn extends ConsumerStatefulWidget {
  const RecipePageMainColumn({
    super.key,
  });

  @override
  ConsumerState<RecipePageMainColumn> createState() => _RecipePageMainColumnState();
}

class _RecipePageMainColumnState extends ConsumerState<RecipePageMainColumn> {
  String _filterStr = '';
  final _searchController = TextEditingController();

  bool viewPublicRecipes = false;

  void _searchChangedCallback(String filter) {
    setState(() {
      _filterStr = filter;
    });
  }

  // 콜백 지옥보다는 나은 디자인이 있지 않을까 싶은
  _DisplayMode _displayMode = _DefaultMode();

  void _fromDefaultViewCallback(Recipe recipe) {
    setState(() {
      _displayMode = _ViewMode(recipe);
    });
  }

  void _fromDefaultAddCallback() {
    setState(() {
      _displayMode = _AddMode();
    });
  }

  Future<void> _fromViewDeleteCallback() async {
    final messenger = ScaffoldMessenger.of(context);
    final recipe = switch (_displayMode) {
      _ViewMode(:final recipe) => recipe,
      _ => throw StateError('Expected _ViewMode!'),
    };
    await ref.read(recipeProvider.notifier).deleteRecipe(recipe);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(content: Text('레시피를 삭제하였습니다.')),
    );
    setState(() {
      _displayMode = _DefaultMode();
    });
  }

  void _fromViewGoBackCallback() {
    setState(() {
      _displayMode = _DefaultMode();
    });
  }

  VoidCallback get _fromAddGoBackCallback => _fromViewGoBackCallback;

  void _fromViewEditCallback() {
    final recipe = switch (_displayMode) {
      _ViewMode(:final recipe) => recipe,
      _ => throw StateError('Expected _ViewMode!'),
    };
    setState(() {
      _displayMode = _EditMode(recipe);
    });
  }

  void _fromEditGoBackCallback() {
    final recipe = (_displayMode as _EditMode).initialRecipe;

    setState(() {
      _displayMode = _ViewMode(recipe);
    });
  }

  Future<void> _fromEditConfirmCallback(Recipe recipe) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(recipeProvider.notifier).upsertRecipe(recipe);
    setState(() {
      _displayMode = _ViewMode(recipe);
    });
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(content: Text('레시피를 수정하였습니다.')),
    );
    
  }
  Future<void> _fromAddSubmitCallback(Recipe recipe) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(recipeProvider.notifier).upsertRecipe(recipe);
    setState(() {
      _displayMode = _DefaultMode();
    });
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(content: Text('레시피를 추가하였습니다.')),
    );
  }


  @override
  Widget build(BuildContext context) {
    ref.listen<int>(tab0TapTokenProvider, (prev, next) {
      setState(() {
        _displayMode = _DefaultMode();
      });
    });

    final defaultPage = ref.watch(recipeProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('레시피 로딩 중 오류: $e')),
      data: (recipes) {

        final List<Widget> allRecipes;

        final filteredRecipes = recipes
            .where((r) => r.name.contains(_filterStr))
            .map((r) => RecipePreview(recipe: r, pressedCallback: _fromDefaultViewCallback));
        if (viewPublicRecipes) {
          final filteredPublicRecipes = publicRecipeSimilarity.cachedPublicRecipes
              .where((r) => r.name.contains(_filterStr))
              .map((r) => RecipePreview(recipe: r, pressedCallback: _fromDefaultViewCallback));

          allRecipes = [...filteredRecipes, Divider(height: 12, thickness: 1, indent: 8, endIndent: 8), SizedBox(height: 8,), ...filteredPublicRecipes];
        } else {
          allRecipes = filteredRecipes.toList();
        }


        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              RecipeAddHeader(addCallback: _fromDefaultAddCallback,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: SearchField(
                      controller: _searchController,
                      onChanged: _searchChangedCallback,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: viewPublicRecipes,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) => setState(() => viewPublicRecipes = val),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '외부 레시피도\n 같이 보기',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Divider(height: 24, thickness: 1, indent: 0, endIndent: 0,),
              //SizedBox(height: 8,),
              Expanded(
                child: ListView.builder(
                  itemCount: allRecipes.length,
                  itemBuilder: (context, index) {
                    return allRecipes[index];
                  },
                ),
              ),
            ],
          ),
        );
      }
    );

    final addPage = PaddedRecipeAdditionCard(
      titleString: '레시피 추가',
      onSubmitCallback: _fromAddSubmitCallback,
      onCancelCallback: _fromAddGoBackCallback,
    );

    Widget editPage(Recipe recipe) {
      debugPrint("current recipe: ${recipe.name}");
    return PaddedRecipeAdditionCard(
        titleString: '레시피 수정',
        onSubmitCallback: _fromEditConfirmCallback,
        onCancelCallback: _fromEditGoBackCallback,
        initialRecipe: recipe,
      );
    }

    Widget viewPage(Recipe recipe) {
      return RecipeEntryPage(baseRecipe: recipe,
          onEditCallback: _fromViewEditCallback,
          onDeleteCallback: _fromViewDeleteCallback,
          onGoBackCallback: _fromViewGoBackCallback,
      );
    }

    return switch (_displayMode) {
      _DefaultMode() => defaultPage,
      _AddMode() => addPage,
      _ViewMode(:final recipe) => viewPage(recipe),
      _EditMode(:final initialRecipe) => editPage(initialRecipe),
    };
  }
}


