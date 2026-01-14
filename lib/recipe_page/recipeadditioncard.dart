import 'package:flutter/material.dart';

import "../classes/recipe.dart";

class RecipeAdditionCard extends StatefulWidget {
  const RecipeAdditionCard({
    super.key,
    required this.titleString,
    required this.onSubmitCallback,
    required this.onCancelCallback,
    this.initialRecipe,
  });

  final Future<void> Function(Recipe recipe) onSubmitCallback; // 레시피 저장 눌렀을 시의 callback, 에러 핸들링까지 해줘요!
  final VoidCallback onCancelCallback; // 레시피 취소 눌렀을 시의 callback.

  final Recipe? initialRecipe;
  final String titleString;

  @override
  State<RecipeAdditionCard> createState() => _RecipeAdditionCardState();
}

class _RecipeAdditionCardState extends State<RecipeAdditionCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _portionController;
  late final TextEditingController _timeController;
  late final List<TextEditingController> _ingredientControllers;
  late final List<TextEditingController> _stepControllers;
  late final List<TextEditingController> _memoControllers;
  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialRecipe?.name ?? '');
    _portionController = TextEditingController(text: widget.initialRecipe?.portionSize ?? '');
    _timeController = TextEditingController(text: widget.initialRecipe?.timeTaken ?? '');

    // wow
    _ingredientControllers = (widget.initialRecipe?.ingredients ?? []).map((ing) => TextEditingController(text: ing)).toList();
    _stepControllers = (widget.initialRecipe?.steps ?? []).map((step) => TextEditingController(text: step)).toList();
    _memoControllers = (widget.initialRecipe?.memos ?? []).map((memo) => TextEditingController(text: memo)).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _portionController.dispose();
    _timeController.dispose();

    for (final c in _ingredientControllers) {
      c.dispose();
    }
    for (final c in _stepControllers) {
      c.dispose();
    }
    for (final c in _memoControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _addMemo() {
    setState(() {
      _memoControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
    });
  }

  void _removeMemo(int index) {
    setState(() {
      _memoControllers[index].dispose();
      _memoControllers.removeAt(index);
    });
  }


  @override
  Widget build(BuildContext context) {

    final ingredientRows = <Widget>[];
    for (int i = 0; i < _ingredientControllers.length; i += 2) {
      ingredientRows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ingredientControllers[i],
                          decoration: InputDecoration(
                            labelText: '재료 ${i+1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFB65A2C)),
                        onPressed: () => _removeIngredient(i),
                      ),
                    ],
                  )
              ),
              const SizedBox(width: 8),
              Expanded(
                child: (i + 1 < _ingredientControllers.length)
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ingredientControllers[i+1],
                              decoration: InputDecoration(
                                labelText: '재료 ${i+2}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFB65A2C)),
                            onPressed: () => _removeIngredient(i+1),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }



    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        widget.onCancelCallback();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            widget.titleString,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 이름
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '레시피 이름',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // 분량, 소요시간
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _portionController,
                  decoration: const InputDecoration(
                    labelText: '분량 (선택사항)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    labelText: '시간 (선택사항)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 34, thickness: 1),

          // 재료
          _buildSectionHeader('재료', _addIngredient),
          const SizedBox(height: 8),
          ...ingredientRows,
          const SizedBox(height: 12),

          // 단계
          _buildSectionHeader('단계', _addStep),
          const SizedBox(height: 8),
          ..._stepControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: '단계 ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFB65A2C)),
                    onPressed: () => _removeStep(index),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          // 메모
          _buildSectionHeader('메모', _addMemo),
          const SizedBox(height: 8),
          ..._memoControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: '메모 ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFB65A2C)),
                    onPressed: () => _removeMemo(index),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // 저장, 취소 버튼 (위치/디자인 통일)
          Row(
            children: [
              // ✅ 왼쪽: 취소 (뒤로가기/취소 스타일)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey, // ✅ 너가 통일하려던 그 글씨색
                      elevation: 0,
                      surfaceTintColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onPressed: widget.onCancelCallback,
                    child: const Text(
                      '취소',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ✅ 오른쪽: 레시피 저장 (저장 버튼 스타일)
              Expanded(
                child: SizedBox(
                  height: 48,
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

                      if (_nameController.text.trim().isEmpty) {
                        messenger.clearSnackBars();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('레시피의 이름을 입력하세요.')),
                        );
                        return;
                      }

                      await widget.onSubmitCallback(
                        Recipe(
                          id: widget.initialRecipe?.id,
                          name: _nameController.text.trim(),
                          portionSize: _portionController.text.trim().isEmpty
                              ? null
                              : _portionController.text,
                          timeTaken: _timeController.text.trim().isEmpty
                              ? null
                              : _timeController.text,
                          ingredients: _ingredientControllers
                              .map((c) => c.text.trim())
                              .toList(),
                          steps: _stepControllers.map((c) => c.text.trim()).toList(),
                          memos: _memoControllers.map((c) => c.text.trim()).toList(),
                        ),
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
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Color(0xFFB65A2C)),
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class PaddedRecipeAdditionCard extends StatelessWidget {
  const PaddedRecipeAdditionCard({
    super.key,
    required this.titleString,
    required this.onSubmitCallback,
    required this.onCancelCallback,
    this.initialRecipe,
  });

  final Future<void> Function(Recipe recipe) onSubmitCallback;
  final VoidCallback onCancelCallback;

  final Recipe? initialRecipe;
  final String titleString;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white, // ✅ 틴트 제거
      elevation: 0, // (원하면)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: RecipeAdditionCard(
          titleString: titleString,
          onSubmitCallback: onSubmitCallback,
          onCancelCallback: onCancelCallback,
          initialRecipe: initialRecipe,
        ),
      ),
    );
  }
}