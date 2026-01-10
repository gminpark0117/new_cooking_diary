import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import "../recipe.dart";


class RecipeAdditionCard extends StatefulWidget {
  const RecipeAdditionCard({
    super.key,
    required this.titleString,
    required this.onSubmitCallback,
    required this.onCancelCallback,
    this.initialRecipe,
  });

  final void Function(Recipe recipe) onSubmitCallback; // 레시피 저장 눌렀을 시의 callback.
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

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialRecipe?.name ?? '');
    _portionController = TextEditingController(text: widget.initialRecipe?.portionSize.toString() ?? '');
    _timeController = TextEditingController(text: widget.initialRecipe?.timeTaken.toString() ?? '');

    // wow
    _ingredientControllers = (widget.initialRecipe?.ingredients ?? []).map((ing) => TextEditingController(text: ing)).toList();
    _stepControllers = (widget.initialRecipe?.steps ?? []).map((step) => TextEditingController(text: step)).toList();
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

  @override
  Widget build(BuildContext context) {
    return Column(
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
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: '분량 (인분)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: '조리시간 (분)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 재료
        _buildSectionHeader('재료', _addIngredient),
        const SizedBox(height: 8),
        ..._ingredientControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: '재료 ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _removeIngredient(index),
                ),
              ],
            ),
          );
        }),
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
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _removeStep(index),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),

        // 저장, 삭제버튼
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () {
                  widget.onSubmitCallback(Recipe(
                    portionSize: int.tryParse(_portionController.text.trim())!,
                    timeTaken: int.tryParse(_timeController.text.trim())!,
                    name: _nameController.text.trim(),
                    ingredients: _ingredientControllers.map((controller) => controller.text.trim()).toList(),
                    steps: _stepControllers.map((controller) => controller.text.trim()).toList(),
                  ));
                },
                child: const Text('레시피 저장'),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton(
                onPressed: widget.onCancelCallback,
                child: const Text('취소'),
              ),
            ),
          ],
        ),
      ],
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
          icon: const Icon(Icons.add),
          onPressed: onAdd,
        ),
      ],
    );
  }
}
