import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/grocery_provider.dart';
import '../classes/grocery.dart';
import 'groceryeditcard.dart';

class GroceryEntry extends ConsumerStatefulWidget {
  const GroceryEntry({
    super.key,
    required this.grocery,
  });

  final Grocery grocery;

  @override
  ConsumerState<GroceryEntry> createState() => _GroceryEntryTileState();
}

class _GroceryEntryTileState extends ConsumerState<GroceryEntry> {
  bool _isChecked = false;
  bool _isEditMode = false;

  Future<void> _onSubmitEdit(Grocery grocery) async {
    await ref.read(groceryProvider.notifier).upsertGrocery(grocery);
    setState(() {
      _isEditMode = false;
      _isChecked = false;
    });
  }

  void _onCancelEdit() {
    setState(() {
      _isEditMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      decoration: _isChecked ? TextDecoration.lineThrough : null,
      color: _isChecked ? Colors.blueGrey : null,
    );

    final subtitleStyle = theme.textTheme.labelSmall?.copyWith(
      decoration: _isChecked ? TextDecoration.lineThrough : null,
      color: _isChecked ? Colors.blueGrey : null,
    );

    final normalState = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            // Left toggle
            Checkbox(
              value: _isChecked,
              onChanged: (b) {
                setState(() {
                  _isChecked = b ?? false;
                });
              },
            ),

            // Main text area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.grocery.name, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (widget.grocery.recipeName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Text(
                        "레시피: ${widget.grocery.recipeName!}",
                        style: subtitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Right actions
            IconButton(
              icon: const Icon(Icons.edit),
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              tooltip: '재료 수정',
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              tooltip: '삭제',
              onPressed: () async {
                await ref.read(groceryProvider.notifier).deleteGrocery(widget.grocery);
              },
            ),
          ],
        ),
      ),
    );

    final editState = Listener(
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
                child: GroceryEditCard(
                    onSubmitCallback: _onSubmitEdit,
                    onCancelCallback: _onCancelEdit,
                    initialGrocery: widget.grocery),
              )
          )
      ),
    );
    return _isEditMode ? editState : normalState;
  }
}