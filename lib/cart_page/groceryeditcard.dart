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

  late final FocusNode _nameFocus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialGrocery.name);
    _nameFocus = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          focusNode: _nameFocus,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: '재료명',

            // ✅ 포커스 여부에 따라 라벨 색 변경
            labelStyle: TextStyle(
              color: _nameFocus.hasFocus
                  ? const Color(0xFFB65A2C)
                  : Colors.black54,
              fontWeight: FontWeight.w500,
            ),

            // ✅ 떠있는 라벨도 동일하게 (이거 안 하면 반만 바뀜)
            floatingLabelStyle: TextStyle(
              color: _nameFocus.hasFocus
                  ? const Color(0xFFB65A2C)
                  : Colors.black54,
              fontWeight: FontWeight.w600,
            ),

            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFB65A2C), width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // 취소(왼쪽)
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancelCallback,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '취소',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 재료 수정(오른쪽)
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);

                  final newName = _nameController.text.trim();
                  if (newName.isEmpty) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('재료의 이름을 입력하세요.')),
                    );
                    return;
                  }

                  final oldName = widget.initialGrocery.name.trim();

                  await widget.onSubmitCallback(
                    Grocery(
                      id: widget.initialGrocery.id,
                      name: newName,

                      // ✅ 이름이 바뀌면 출처 레시피는 끊는다(표시도 사라짐)
                      recipeName: (newName == oldName) ? widget.initialGrocery.recipeName : null,
                    ),
                  );

                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('재료를 수정하였습니다.')),
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB65A2C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '재료 수정',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
