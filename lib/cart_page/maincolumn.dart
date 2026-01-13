import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:new_cooking_diary/classes/grocery.dart';
import '../data/grocery_provider.dart';
import '../widgets/search_field.dart';
import 'groceryentry.dart';

class CartAddHeader extends ConsumerStatefulWidget {
  const CartAddHeader({
    super.key,
    required this.selectionMode,
    required this.selectAllLabel,
    required this.onEnterSelectionMode,
    required this.onCancel,
    required this.onToggleSelectAll,
    required this.onDeleteSelected,
    required this.deleteEnabled,
  });

  final bool selectionMode;
  final String selectAllLabel;
  final VoidCallback onEnterSelectionMode;
  final VoidCallback onCancel;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onDeleteSelected;
  final bool deleteEnabled;

  @override
  ConsumerState<CartAddHeader> createState() => _CartAddHeaderState();
}

class _CartAddHeaderState extends ConsumerState<CartAddHeader> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 삭제 선택 모드 UI (2페이지 상단 버튼 규격에 맞춤)
    if (widget.selectionMode) {
      return SafeArea(
        bottom: false,
        child: Padding(
          // ⚠️ ListView에서 이미 all:16 주기 때문에 좌우 16 중복 방지 -> bottom 간격만
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // 취소
              Expanded(
                child: SizedBox(
                  height: 52, // ✅ 2페이지 기준
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 전체 선택/해제
              Expanded(
                child: SizedBox(
                  height: 52, // ✅ 2페이지 기준
                  child: ElevatedButton(
                    onPressed: widget.onToggleSelectAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.selectAllLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 삭제
              SizedBox(
                height: 52, // ✅ 2페이지 기준
                child: ElevatedButton(
                  onPressed: widget.deleteEnabled ? widget.onDeleteSelected : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    '삭제',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ 일반 모드 UI (재료 입력 + + 버튼 + 휴지통 버튼) -> 2페이지 상단 규격과 통일
    return SafeArea(
      bottom: false,
      child: Padding(
        // ⚠️ ListView에서 all:16 주기 때문에 좌우 16 중복 방지 -> bottom 간격만
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52, // ✅ 2페이지 기준
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: '재료를 추가하세요',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14, // ✅ 52 높이에 맞는 값
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // + 버튼 (52x52로 통일)
            SizedBox(
              height: 52,
              width: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB65A2C),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);

                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('재료의 이름을 입력하세요.')),
                    );
                    return;
                  }

                  await ref
                      .read(groceryProvider.notifier)
                      .upsertGrocery(Grocery(name: name));

                  controller.clear();

                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('재료를 추가하였습니다.')),
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),

            const SizedBox(width: 8),

            // 휴지통 버튼 (52x52로 통일)
            SizedBox(
              height: 52,
              width: 52,
              child: ElevatedButton(
                onPressed: widget.onEnterSelectionMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.delete_outline, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartPageMainColumn extends ConsumerStatefulWidget {
  const CartPageMainColumn({super.key});

  @override
  ConsumerState<CartPageMainColumn> createState() => _CartPageMainColumnState();
}

class _CartPageMainColumnState extends ConsumerState<CartPageMainColumn> {
  String _filterStr = '';
  final _searchController = TextEditingController();

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  void _onChangedCallback(String filter) {
    setState(() => _filterStr = filter);
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(groceryProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('재료 로딩 중 오류: $e')),
      data: (groceries) {
        final filteredGroceries = groceries
            .where((g) =>
        g.name.contains(_filterStr) ||
            (g.recipeName?.contains(_filterStr) ?? false))
            .toList();

        final allIds = filteredGroceries.map((g) => g.id).toSet();
        final isAllSelected =
            allIds.isNotEmpty && _selectedIds.length == allIds.length;
        final selectAllLabel = isAllSelected ? '전체 해제' : '전체 선택';

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredGroceries.length + 3,
          itemBuilder: (context, index) {
            if (index == 0) {
              return CartAddHeader(
                selectionMode: _selectionMode,
                selectAllLabel: selectAllLabel,
                deleteEnabled: _selectedIds.isNotEmpty,

                // ✅ 휴지통 진입 시: DB에서 checked=true인 애들을 선택 상태로 넘김
                onEnterSelectionMode: () {
                  setState(() {
                    _selectionMode = true;
                    _selectedIds
                      ..clear()
                      ..addAll(filteredGroceries
                          .where((g) => g.checked)
                          .map((g) => g.id));
                  });
                },

                onCancel: () {
                  setState(() {
                    _selectionMode = false;
                    _selectedIds.clear();
                  });
                },

                onToggleSelectAll: () {
                  setState(() {
                    if (isAllSelected) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds
                        ..clear()
                        ..addAll(allIds);
                    }
                  });
                },

                onDeleteSelected: () async {
                  final targets =
                  filteredGroceries.where((g) => _selectedIds.contains(g.id));

                  for (final g in targets) {
                    await ref.read(groceryProvider.notifier).deleteGrocery(g);
                  }

                  if (!mounted) return;

                  setState(() {
                    _selectionMode = false;
                    _selectedIds.clear();
                  });
                },
              );
            } else if (index == 1) {
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: SearchField(
                  controller: _searchController,
                  onChanged: _onChangedCallback,
                ),
              );
            } else if (index == 2) {
              return const Divider(height: 24, thickness: 1);
            }

            final grocery = filteredGroceries[index - 3];

            return GroceryEntry(
              key: ValueKey(grocery.id), // ✅ 상태 뒤바뀜 방지

              grocery: grocery,
              selectionMode: _selectionMode,
              selected: _selectedIds.contains(grocery.id),
              onSelectedChanged: (checkedSel) {
                setState(() {
                  if (checkedSel == true) {
                    _selectedIds.add(grocery.id);
                  } else {
                    _selectedIds.remove(grocery.id);
                  }
                });
              },

              // ✅ 기본 체크는 DB 값
              checked: grocery.checked,
              onCheckedChanged: (b) async {
                await ref.read(groceryProvider.notifier).setChecked(
                  id: grocery.id,
                  checked: b ?? false,
                );
              },
            );
          },
        );
      },
    );
  }
}

