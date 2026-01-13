import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../classes/grocery.dart';
import 'database.dart';

class GroceryNotifier extends AsyncNotifier<List<Grocery>> {
  late final GroceryRepository _repo = ref.read(groceryRepoProvider);

  @override
  Future<List<Grocery>> build() async {
    return _repo.getAllGroceries();
  }

  List<Grocery> getGroceries({String filter = ''}) {
    return (state.value ?? const <Grocery>[])
        .where((g) => g.name.contains(filter) || (g.recipeName?.contains(filter) ?? false))
        .toList();
  }

  Future<void> upsertGrocery(Grocery grocery) async {
    final previous = state.value ?? const <Grocery>[];
    state = AsyncData(_upsertInList(previous, grocery));

    state = await AsyncValue.guard(() async {
      await _repo.upsertGrocery(grocery);
      return _repo.getAllGroceries();
    });
  }

  Future<void> deleteGrocery(Grocery grocery) async {
    final previous = state.value ?? const <Grocery>[];
    state = AsyncData(previous.where((g) => g.id != grocery.id).toList());

    state = await AsyncValue.guard(() async {
      await _repo.deleteGrocery(grocery);
      return _repo.getAllGroceries();
    });
  }

  // ✅ 체크 토글: DB에 저장 + 상태 갱신
  Future<void> setChecked({
    required String id,
    required bool checked,
  }) async {
    final previous = state.value ?? const <Grocery>[];

    // optimistic
    state = AsyncData(previous.map((g) {
      if (g.id != id) return g;
      return g.copyWith(checked: checked);
    }).toList());

    // persist + refresh
    state = await AsyncValue.guard(() async {
      await _repo.setChecked(id: id, checked: checked);
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
