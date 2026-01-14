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
    // ✅ 2/3페이지 규격: 바깥(ListView)에서 all:16을 주고
    // 여기서는 bottom 간격만 준다.
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: SizedBox(
        width: double.infinity,
        height: 52, // ✅ 2페이지 버튼 높이와 통일
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
  const _ViewMode(this.recipe, this.isPreview);
  final Recipe recipe;
  final bool isPreview;
}

class _EditMode extends _DisplayMode {
  const _EditMode(this.initialRecipe);
  final Recipe initialRecipe;
}

class RecipePageMainColumn extends ConsumerStatefulWidget {
  const RecipePageMainColumn({super.key});

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

  _DisplayMode _displayMode = const _DefaultMode();

  void _fromDefaultViewCallback(Recipe recipe, bool isPreview) {
    setState(() {
      _displayMode = _ViewMode(recipe, isPreview);
    });
  }

  void _fromDefaultAddCallback() {
    setState(() {
      _displayMode = const _AddMode();
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
    messenger.showSnackBar(const SnackBar(content: Text('레시피를 삭제하였습니다.')));
    setState(() {
      _displayMode = const _DefaultMode();
    });
  }

  void _fromViewGoBackCallback() {
    setState(() {
      _displayMode = const _DefaultMode();
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
      _displayMode = _ViewMode(recipe, false);
    });
  }

  Future<void> _fromEditConfirmCallback(Recipe recipe) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(recipeProvider.notifier).upsertRecipe(recipe);
    setState(() {
      _displayMode = _ViewMode(recipe, false);
    });
    messenger.clearSnackBars();
    messenger.showSnackBar(const SnackBar(content: Text('레시피를 수정하였습니다.')));
  }

  Future<void> _fromAddSubmitCallback(Recipe recipe) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(recipeProvider.notifier).upsertRecipe(recipe);
    setState(() {
      _displayMode = const _DefaultMode();
    });
    messenger.clearSnackBars();
    messenger.showSnackBar(const SnackBar(content: Text('레시피를 추가하였습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(tab0TapTokenProvider, (prev, next) {
      setState(() {
        _displayMode = const _DefaultMode();
      });
    });

    final defaultPage = ref.watch(recipeProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('레시피 로딩 중 오류: $e')),
      data: (recipes) {
        // ✅ 기존 로직 유지: 개인 레시피 필터링
        final filteredRecipes = recipes
            .where((r) => r.name.contains(_filterStr))
            .map((r) => RecipePreview(
          recipe: r,
          pressedCallback: (r) => _fromDefaultViewCallback(r, false),
        ))
            .toList();

        // ✅ 공개 레시피 섹션 옵션
        final filteredPublicRecipes = viewPublicRecipes
            ? publicRecipeSimilarity.cachedPublicRecipes
            .where((r) => r.name.contains(_filterStr))
            .map((r) => RecipePreview(
          recipe: r,
          pressedCallback: (r) => _fromDefaultViewCallback(r, true),
        ))
            .toList()
            : const <Widget>[];

        // ✅ 리스트 데이터 합치기 (구분선/간격은 위젯으로)
        final allListItems = <Widget>[
          ...filteredRecipes,
          if (viewPublicRecipes) ...[
            const Divider(height: 24, thickness: 1), // 2/3페이지 규격
            const SizedBox(height: 8),
            ...filteredPublicRecipes,
          ],
        ];

        // ✅ 2/3페이지와 동일한 구조: ListView.builder + header 3개
        return ListView.builder(
          padding: const EdgeInsets.all(16), // ✅ 전체 기준선 통일
          itemCount: allListItems.length + 3, // 헤더 3개 + 리스트
          itemBuilder: (context, index) {
            if (index == 0) {
              return RecipeAddHeader(addCallback: _fromDefaultAddCallback);
            }

            if (index == 1) {
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SearchField(
                        controller: _searchController,
                        onChanged: _searchChangedCallback,
                      ),
                    ),
                    const SizedBox(width: 8), // ✅ 2페이지 스타일
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Switch(
                            value: viewPublicRecipes,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) => setState(() => viewPublicRecipes = val),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '외부 레시피도\n 같이 보기',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (index == 2) {
              return const Column(
                children: [
                  Divider(height: 24, thickness: 1),
                  SizedBox(height: 8), // ✅ 여기 값 늘릴수록 리스트가 더 아래로 내려감
                ],
              );
            }

            // 리스트 아이템
            return allListItems[index - 3];
          },
        );
      },
    );

    final addPage = PaddedRecipeAdditionCard(
      titleString: '레시피 추가',
      onSubmitCallback: _fromAddSubmitCallback,
      onCancelCallback: _fromAddGoBackCallback,
    );

    Widget editPage(Recipe recipe) {
      return PaddedRecipeAdditionCard(
        titleString: '레시피 수정',
        onSubmitCallback: _fromEditConfirmCallback,
        onCancelCallback: _fromEditGoBackCallback,
        initialRecipe: recipe,
      );
    }

    Widget viewPage(Recipe recipe, bool isPreview) {
      return RecipeEntryPage(
        baseRecipe: recipe,
        onEditCallback: _fromViewEditCallback,
        onDeleteCallback: _fromViewDeleteCallback,
        onGoBackCallback: _fromViewGoBackCallback,
        isPreview: isPreview,
      );
    }

    return switch (_displayMode) {
      _DefaultMode() => defaultPage,
      _AddMode() => addPage,
      _ViewMode(:final recipe, :final isPreview) => viewPage(recipe, isPreview),
      _EditMode(:final initialRecipe) => editPage(initialRecipe),
    };
  }
}
