import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import "recipeadditioncard.dart";
import "recipentry.dart";
import "../providers.dart";
import "../recipe.dart";

class AddHeader extends ConsumerStatefulWidget {
  const AddHeader({
    super.key,
  });

  @override
  ConsumerState<AddHeader> createState() => _AddHeaderState();
}

class _AddHeaderState extends ConsumerState<AddHeader> {
  bool _showRecipeAdditionCard = false;

  void _onSubmit(Recipe recipe) { setState(() {
      ref.read(recipeProvider.notifier).addRecipe(recipe);
      _showRecipeAdditionCard = false;
    });
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
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('레시피 추가'),
              onPressed: () {
                setState(() {
                  _showRecipeAdditionCard = !_showRecipeAdditionCard;
                });
              },
              style: FilledButton.styleFrom(
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
    ref.watch(recipeProvider);
    final recipes = ref.read(recipeProvider.notifier).getRecipe(filter: _filterStr);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length + 3,
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
        return RecipeEntry(recipe: recipes[index - 3]);
      },
    );
  }
}


