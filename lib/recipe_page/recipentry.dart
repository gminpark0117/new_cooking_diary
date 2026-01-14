import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_cooking_diary/classes/grocery.dart';
import 'package:new_cooking_diary/data/recipe_provider.dart';
import 'package:new_cooking_diary/main.dart';

import "../classes/recipe.dart";
import "../data/grocery_provider.dart";


class RecipePreview extends StatelessWidget {
  const RecipePreview({
    super.key,
    required this.recipe,
    required this.pressedCallback,
  });

  final Recipe recipe;
  final void Function(Recipe recipe) pressedCallback;

  static const Color brandColor = Color(0xFFB65A2C);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => pressedCallback(recipe),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6), // 3페이지 느낌
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long, color: brandColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold, // ✅ 장바구니처럼 bold
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipe.meta(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

const Color brandColor = Color(0xFFB65A2C);

class RecipeDetail extends StatelessWidget {

  RecipeDetail({
    super.key,
    required this.recipe,
    required this.onEditCallback,
    required this.onDeleteCallback,
    required this.isPreview,
  });

  final Recipe recipe;
  final bool isPreview;

  final VoidCallback onEditCallback; // the parent (mainColumn) should have the recipe info.
  final VoidCallback onDeleteCallback;


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white, // ✅ 핑크/보라 틴트 제거 핵심
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
                  if (!isPreview)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: brandColor),
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
                          icon: const Icon(Icons.delete_outline, color: brandColor),
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

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 1,
                thickness: 1,
              ),
            ),

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
          height: 48, // ✅ 지금 버튼 크기 유지
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB65A2C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              for (final idx in _checkedIngredientIndexes) {
                await ref.read(groceryProvider.notifier).upsertGrocery(
                  Grocery(
                    name: widget.recipe.ingredients[idx],
                    recipeName: widget.recipe.name,
                  ),
                );
              }
              if (_checkedIngredientIndexes.isNotEmpty) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(content: Text('장바구니에 추가되었습니다.')),
                );
              }
            },
            child: const Text(
              '장바구니에 추가',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 20),


        _SectionHeader(title: '순서'),
        const SizedBox(height: 6),
        if (steps.isEmpty)
          Text(
            '순서 없음.',
            style: theme.textTheme.bodySmall,
          )
        else
          ...steps.asMap().entries.map(
                (entry) {
              final i = entry.key;
              final step = entry.value;
              final isLast = i == steps.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 4 : 10),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text('${i + 1}.'),
                        ),
                        Expanded(child: Text(step)),
                      ],
                    ),
                    if (widget.recipe.stepImagePaths[i] != null)
                      Column(
                        children: [
                          SizedBox(height: 4,),
                          AspectRatio(
                            aspectRatio: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(widget.recipe.stepImagePaths[i]!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 6,),
                        ],
                      ),
                    if (!isLast)
                      Divider(height: 16),
                  ],
                ),
              );
            },
          ),
        if (memos.isNotEmpty)
          Divider(height: 12,thickness: 1,),

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
  required this.isPreview,
  required this.onEditCallback,
  required this.onDeleteCallback,
  required this.onGoBackCallback,
  });
  final Recipe baseRecipe;
  final bool isPreview;
  final VoidCallback onEditCallback; // the parent (mainColumn) should have the recipe info.
  final VoidCallback onDeleteCallback;
  final VoidCallback onGoBackCallback;

  @override
  ConsumerState<RecipeEntryPage> createState() => _RecipeEntryPageState();
}

class _RecipeEntryPageState extends ConsumerState<RecipeEntryPage> {
  List<Recipe> recipeStack = [];
  bool isPreview = false;
  Future<List<Recipe>>? _similarFuture;

  @override
  void initState() {
    super.initState();
    recipeStack = [widget.baseRecipe];
    isPreview = widget.isPreview;
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
      duration: const Duration(milliseconds: 250),
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
        if (recipeStack.length == 1) {
          isPreview = widget.isPreview;
        }
      });
    }
  }

  void _pushRecipe(Recipe r) {
    setState(() {
      recipeStack.add(r);
      isPreview = true;
      _similarFuture = publicRecipeSimilarity.findSimilar(recipeStack.last);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop());
  }

  @override
  Widget build(BuildContext context) {
    final widgetsInList = <Widget>[
      if (recipeStack.last.mainImagePath != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(recipeStack.last.mainImagePath!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      RecipeDetail(
        recipe: recipeStack.last,
        onEditCallback: widget.onEditCallback,
        onDeleteCallback: widget.onDeleteCallback,
        isPreview: isPreview,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Divider(height: 24, thickness: 1),
      ),

      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12, left: 20),
        child: Text(
          '이런 레시피도 있어요!',
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
              child: Text('추천 레시피가 없습니다. 미안해용'),
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
      if (!isPreview)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            height: 48, // ✅ 다른 뒤로가기 버튼과 동일
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey,
                elevation: 0,
                surfaceTintColor: Colors.white, // ✅ 틴트 제거
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onPressed: _popRecipeOrGoBack,
              child: const Text(
                '뒤로가기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        )

      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // ✅ 왼쪽: 뒤로가기 (취소 버튼 스타일)
              Expanded(
                child: SizedBox(
                  height: 48, // ✅ 지금 버튼 높이 유지
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // "취소" 버튼이 기본 ElevatedButton 느낌이면 이 세팅이 가장 비슷하게 나옴
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey,
                      elevation: 0,
                      surfaceTintColor: Colors.white, // ✅ 핑크 틴트 방지
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onPressed: _popRecipeOrGoBack,
                    child: const Text(
                      '뒤로가기',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ✅ 오른쪽: 레시피 저장 (2페이지 메인 버튼 스타일)
              Expanded(
                child: SizedBox(
                  height: 48, // ✅ 지금 버튼 높이 유지
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: brandColor, // ✅ #B65A2C
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ref.read(recipeProvider.notifier).upsertRecipe(recipeStack.last);
                      messenger.clearSnackBars();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('레시피를 추가했습니다.')),
                      );
                    },
                    child: const Text(
                      '레시피 저장',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
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