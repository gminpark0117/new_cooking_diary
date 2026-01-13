import 'package:flutter/material.dart';
import 'package:new_cooking_diary/classes/grocery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/grocery_provider.dart';
import '../widgets/search_field.dart';
import 'groceryentry.dart';

class CartAddHeader extends ConsumerWidget {
  CartAddHeader({
    super.key,
  });

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '재료를 추가하세요..',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              width: 44,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (controller.text.isEmpty) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('재료의 이름을 입력하세요.')),
                    );
                    return;
                  }
                  await ref.read(groceryProvider.notifier).upsertGrocery(Grocery(name: controller.text));
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('재료를 추가하였습니다.')),
                  );
                },
                child: const Icon(Icons.add),
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

  void _onChangedCallback(String filter) {
    setState(() {
      _filterStr = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(groceryProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('재료 로딩 중 오류: $e')),
      data: (groceries) {
        final filteredGroceries = groceries.where((g) =>
          g.name.contains(_filterStr) || (g.recipeName?.contains(_filterStr) ?? false)
        ).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredGroceries.length + 3,
          itemBuilder: (context, index) {
            if (index == 0) {
              return CartAddHeader();
            } else if (index == 1) {
              return SearchField(controller: _searchController, onChanged: _onChangedCallback,);
            } else if (index == 2) {
              return const Divider(
                height: 24,
                thickness: 1,
                indent: 8,
                endIndent: 8,
              );
            }
            return GroceryEntry(grocery: filteredGroceries[index-3]);
          },
        );
      },
    );
  }
}
