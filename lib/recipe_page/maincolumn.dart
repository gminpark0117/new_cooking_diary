import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import "recipeadditioncard.dart";
import "recipentry.dart";
import "../data/recipe_provider.dart";
import "../classes/recipe.dart";
import "../widgets/search_field.dart";

class RecipeAddHeader extends ConsumerStatefulWidget {
  const RecipeAddHeader({
    super.key,
  });

  @override
  ConsumerState<RecipeAddHeader> createState() => _RecipeAddHeaderState();
}

class _RecipeAddHeaderState extends ConsumerState<RecipeAddHeader> {
  bool _showRecipeAdditionCard = false;

  Future<void> _onSubmit(Recipe recipe) async {
    try {
      await ref.read(recipeProvider.notifier).upsertRecipe(recipe);

      if (!mounted) return;
      setState(() {
        _showRecipeAdditionCard = false;
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
      _showRecipeAdditionCard = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: () {
                setState(() {
                  _showRecipeAdditionCard = !_showRecipeAdditionCard;
                });
              },
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
        if (_showRecipeAdditionCard)
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
          )
      ],
    );
  }
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

  void _onChangedCallback(String filter) {
    setState(() {
      _filterStr = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(recipeProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('레시피 로딩 중 오류: $e')),
      data: (recipes) {
        final filteredRecipes = recipes.where((r) => r.name.contains(_filterStr)).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              RecipeAddHeader(),
              SearchField(controller: _searchController, onChanged: _onChangedCallback,),
              Divider(height: 24, thickness: 1, indent: 8, endIndent: 8,),
              Expanded(
                child: ListView.builder(
                  //padding: const EdgeInsets.all(16),
                  itemCount: filteredRecipes.length,
                  itemBuilder: (context, index) {

                    //return RecipeEntry(recipe: filteredRecipes[index]);
                    return RecipePreview(recipe: filteredRecipes[index], pressedCallback: (_) => {});
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}


