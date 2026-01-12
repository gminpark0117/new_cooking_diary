import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../classes/grocery.dart';
import 'database.dart';

class GroceryNotifier extends AsyncNotifier<List<Grocery>> {
  late final GroceryRepository _repo = ref.read(groceryRepoProvider);

  @override
  Future<List<Grocery>> build() async {
    return _repo.getAllGroceries();
  }

  // This guy searches for both name and recipeName!
  List<Grocery> getGroceries({String filter = ''}) {
    return (state.value ?? const <Grocery>[])
        .where((g) => g.name.contains(filter) || g.recipeName.contains(filter))
        .toList();
  }

  Future<void> upsertGrocery(Grocery grocery) async {
    final previous = state.value ?? const <Grocery>[];
    // optimistic
    state = AsyncData(_upsertInList(previous, grocery));

    // persist + refresh
    state = await AsyncValue.guard(() async {
      await _repo.upsertGrocery(grocery);
      return _repo.getAllGroceries();
    });
  }

  Future<void> deleteGrocery(Grocery grocery) async {
    final previous = state.value ?? const <Grocery>[];

    // optimistic
    state = AsyncData(previous.where((g) => g.id != grocery.id).toList());

    state = await AsyncValue.guard(() async {
      await _repo.deleteGrocery(grocery);
      return _repo.getAllGroceries();
    });
  }

  List<Grocery> _upsertInList(List<Grocery> list, Grocery grocery) {
    final idx = list.indexWhere((g) => g.id == grocery.id);
    if (idx == -1) return [...list, grocery];
    return [...list.sublist(0, idx), grocery, ...list.sublist(idx + 1)];
  }
}

final groceryProvider =
AsyncNotifierProvider<GroceryNotifier, List<Grocery>>(GroceryNotifier.new);

final groceryRepoProvider = Provider<GroceryRepository>((ref) {
  return GroceryRepository(AppDb.instance);
});
