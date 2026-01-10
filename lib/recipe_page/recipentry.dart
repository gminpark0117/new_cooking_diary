import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_cooking_diary/recipe_page/recipeadditioncard.dart';

import "../recipe.dart";
import '../providers.dart';

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
            onPressed: () {
              //TODO: implement
              debugPrint("add to cart pressed, currently checked: $_checkedIngredientIndexes");
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
    );

  }
}


class RecipeEntry extends ConsumerStatefulWidget {
  const RecipeEntry({
    super.key,
    required this.recipe,
  });

  final Recipe recipe;

  @override
  ConsumerState<RecipeEntry> createState() => _RecipeEntryState();
}

class _RecipeEntryState extends ConsumerState<RecipeEntry> {
  bool _inEditMode = false;

  void _onSubmit(Recipe newRecipe) {
    setState(() {
      _inEditMode = false;
      ref.read(recipeProvider.notifier).updateRecipe(widget.recipe, newRecipe);
    });

  }
  void _onCancel() {
    setState(() {
      _inEditMode = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final meta = [
      '분량: ${widget.recipe.portionSize}인분',
      '소요시간: ${widget.recipe.timeTaken}분',
    ].join(' • ');

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
                    //TODO: 누르면 자동으로 수정란 튀어나오도록..
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
                onPressed: () {
                  ref.read(recipeProvider.notifier).deleteRecipe(widget.recipe);
                },
              ),
            ],
          ),
        
          title: Text(
            widget.recipe.name,
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
          children: [targetChild],
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

