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

    // ✅ 추가
    required this.checked,
    required this.onCheckedChanged,
  });

  final Grocery grocery;

  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool?> onSelectedChanged;

  // ✅ 기본 탭 체크(가로줄)
  final bool checked;
  final ValueChanged<bool?> onCheckedChanged;

  @override
  ConsumerState<GroceryEntry> createState() => _GroceryEntryTileState();
}

class _GroceryEntryTileState extends ConsumerState<GroceryEntry> {
  bool _isEditMode = false;

  static const Color brandColor = Color(0xFFB65A2C);

  Future<void> _onSubmitEdit(Grocery grocery) async {
    await ref.read(groceryProvider.notifier).upsertGrocery(grocery);

    if (!mounted) return;
    setState(() {
      _isEditMode = false;
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

    final bool isCheckedForStrike = widget.selectionMode
        ? widget.selected // 선택모드에서는 selected 기준으로 줄 그어도 되고(원하면)
        : widget.checked;  // 기본모드에서는 checked 기준

    final tile = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
              value: widget.selectionMode ? widget.selected : widget.checked,
              onChanged: (b) {
                if (widget.selectionMode) {
                  widget.onSelectedChanged(b);
                } else {
                  widget.onCheckedChanged(b);
                }
              },
            ),

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
                      decoration: isCheckedForStrike ? TextDecoration.lineThrough : null,
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
                        decoration: isCheckedForStrike ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (!widget.selectionMode)
              IconButton(
                icon: const Icon(Icons.edit),
                color: brandColor,
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
        margin: const EdgeInsets.symmetric(vertical: 6),
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
