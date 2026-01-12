import 'package:flutter_riverpod/flutter_riverpod.dart';

import "../classes/diary_entry.dart";
import "database.dart";

class DiaryEntryNotifier extends AsyncNotifier<List<DiaryEntry>> {
  late final DiaryEntryRepository _repo = ref.read(diaryRepoProvider);

  @override
  Future<List<DiaryEntry>> build() async {
    return _repo.getAllDiaryEntries();
  }

  List<DiaryEntry> getEntries({String filter = ''}) {
    return (state.value ?? []).where((e) => e.recipeName.contains(filter)).toList();
  }

  // This copies the file and stores internally, and updates the entry so that the it points to the internal path.
  Future<void> upsertEntry(DiaryEntry entry) async {
    // No optimistic update here
    final previous = state.value ?? const <DiaryEntry>[];

    state = await AsyncValue.guard(() async {
      final saved = await _repo.upsertDiaryEntry(entry);
      return _upsertInList(previous, saved); // state now has copied path
    });
  }

  Future<void> deleteEntry(DiaryEntry entry) async {
    final previous = state.value ?? const <DiaryEntry>[];

    // Optimistic delete
    state = AsyncData(previous.where((e) => e.id != entry.id).toList());

    state = await AsyncValue.guard(() async {
      await _repo.deleteDiaryEntry(entry);
      return _repo.getAllDiaryEntries();
    });
  }

  List<DiaryEntry> _upsertInList(List<DiaryEntry> list, DiaryEntry entry) {
    final idx = list.indexWhere((e) => e.id == entry.id);
    if (idx == -1) return [...list, entry];
    return [...list.sublist(0, idx), entry, ...list.sublist(idx + 1)];
  }
}

final diaryProvider =
AsyncNotifierProvider<DiaryEntryNotifier, List<DiaryEntry>>(DiaryEntryNotifier.new);

final diaryRepoProvider = Provider<DiaryEntryRepository>((ref) {
  return DiaryEntryRepository(AppDb.instance);
});