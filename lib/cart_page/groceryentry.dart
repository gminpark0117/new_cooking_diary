import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/grocery_provider.dart';
import '../classes/grocery.dart';
import 'groceryeditcard.dart';

class GroceryEntry extends ConsumerStatefulWidget {
  const GroceryEntry({
    super.key,
    required this.grocery,
    required this.selectionMode,
    required this.selected,
    required this.onSelectedChanged,
  });

  final Grocery grocery;

  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool?> onSelectedChanged;

  @override
  ConsumerState<GroceryEntry> createState() => _GroceryEntryTileState();
}

class _GroceryEntryTileState extends ConsumerState<GroceryEntry> {
  bool _isChecked = false; // (개인 체크용)
  bool _isEditMode = false;

  static const Color brandColor = Color(0xFFB65A2C);

  Future<void> _onSubmitEdit(Grocery grocery) async {
    await ref.read(groceryProvider.notifier).upsertGrocery(grocery);

    if (!mounted) return;
    setState(() {
      _isEditMode = false;
      _isChecked = false;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(const SnackBar(content: Text('재료를 수정하였습니다.')));
  }

  void _onCancelEdit() {
    setState(() {
      _isEditMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasRecipe =
        widget.grocery.recipeName != null && widget.grocery.recipeName!.trim().isNotEmpty;

    final tile = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Checkbox(
              activeColor: brandColor,
              value: widget.selectionMode ? widget.selected : _isChecked,
              onChanged: (b) {
                if (widget.selectionMode) {
                  widget.onSelectedChanged(b);
                  return;
                }
                setState(() => _isChecked = b ?? false);
              },
            ),

            // ✅ 이름 + (있으면) 레시피 표시
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.grocery.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      decoration: _isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),

                  if (hasRecipe) ...[
                    const SizedBox(height: 2),
                    Text(
                      '레시피: ${widget.grocery.recipeName!.trim()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.black54,
                        decoration: _isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ✅ selectionMode일 때는 우측 아이콘 숨기기
            if (!widget.selectionMode)
              IconButton(
                icon: const Icon(Icons.edit),
                color: brandColor, // ✅ 체크박스와 같은 색
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                tooltip: '재료 수정',
                onPressed: () => setState(() => _isEditMode = true),
              ),
          ],
        ),
      ),
    );

    final editState = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GroceryEditCard(
            onSubmitCallback: _onSubmitEdit,
            onCancelCallback: _onCancelEdit,
            initialGrocery: widget.grocery,
          ),
        ),
      ),
    );

    if (widget.selectionMode) return tile;
    return _isEditMode ? editState : tile;
  }
}
