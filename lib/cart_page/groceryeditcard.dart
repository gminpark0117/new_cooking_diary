import 'package:flutter/material.dart';

import "../classes/grocery.dart";


class GroceryEditCard extends StatefulWidget {
  const GroceryEditCard({
    super.key,
    required this.onSubmitCallback,
    required this.onCancelCallback,
    required this.initialGrocery,
  });

  final Future<void> Function(Grocery grocery) onSubmitCallback;
  final VoidCallback onCancelCallback;

  final Grocery initialGrocery;

  @override
  State<GroceryEditCard> createState() => _GroceryEditCardState();
}

class _GroceryEditCardState extends State<GroceryEditCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _recipeNameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialGrocery.name);
    _recipeNameController = TextEditingController(text: widget.initialGrocery.recipeName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _recipeNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /*// 제목
        Text(
          "재료 수정",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),*/

        // name, recipeName
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '재료명',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _recipeNameController,
                decoration: const InputDecoration(
                  labelText: 'placeholder for now..',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 저장, 삭제버튼
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  if (_nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('재료의 이름을 입력하세요.')),
                    );
                    return;
                  }
                  await widget.onSubmitCallback(Grocery(
                      id: widget.initialGrocery.id,
                      name: _nameController.text.trim(),
                      recipeName: _recipeNameController.text.trim().isEmpty ? null : _recipeNameController.text.trim(),
                  ));
                },
                child: const Text('재료 수정'),
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
}
