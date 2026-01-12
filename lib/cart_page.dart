import 'package:flutter/material.dart';
import 'data/grocery_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(groceryProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('장바구니 로딩 중 오류: $e')),
      data: (groceries) {
        return Column(
          children: groceries.map((g) => Text("레시피 ${g.recipeName}에서 온 ${g.name}")).toList(),
        );
      },
    );
  }
}
