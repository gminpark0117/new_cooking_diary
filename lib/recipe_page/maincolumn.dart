import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import "recipeadditioncard.dart";
import "recipentry.dart";
import "../data/recipe_provider.dart";
import "../classes/recipe.dart";


class AddHeader extends ConsumerStatefulWidget {
  const AddHeader({
    super.key,
  });

  @override
  ConsumerState<AddHeader> createState() => _AddHeaderState();
}

class _AddHeaderState extends ConsumerState<AddHeader> {
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

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,

        decoration: InputDecoration(
          isDense: true,
          hintText: '검색...',
          prefixIcon: const Icon(Icons.search, size: 18),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRecipes.length + 3,
          itemBuilder: (context, index) {
            if (index == 0) {
              return AddHeader();
            } else if (index == 1) {
              return SearchField(controller: _searchController, onChanged: _onChangedCallback,);
            } else if (index == 2) {
              return const Divider(
                height: 24,
                thickness: 1,
                indent: 8,
                endIndent: 8,
              );
            }
            return RecipeEntry(recipe: filteredRecipes[index - 3]);
          },
        );
      }
    );
  }
}


