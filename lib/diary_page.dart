import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'classes/recipe.dart';
import 'classes/diary_entry.dart';

import 'data/recipe_provider.dart';
import 'data/diary_entry_provider.dart';
import 'diary_detail_page.dart';
import 'utils.dart';

// 얘 왜케 커요. 리팩토링 하기에는 귀찮지만
class DiaryPage extends ConsumerStatefulWidget {
  const DiaryPage({super.key});

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends ConsumerState<DiaryPage> {
  bool _showAddArea = false;

  bool _selectionMode = false; // 삭제 선택 모드 여부
  final Set<String> _selectedIds = {}; // 선택된 diaryEntry id들

  String? _pickedImagePath; // 선택한 사진 파일 경로
  final _picker = ImagePicker();

  final ScrollController _scrollController = ScrollController();

  Recipe? _selectedRecipe;
  final TextEditingController _memoController = TextEditingController();

  Future<void> _pickImageFrom(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (file != null) {
      setState(() {
        _pickedImagePath = file.path;
      });
    }
  }

  Future<void> _showImageSourceSheet() async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),

              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('갤러리에서 선택'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFrom(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('카메라로 촬영'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFrom(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openRecipePicker() async {
    final recipes = ref.watch(recipeProvider).value ?? [];
    String keyword = '';

    final picked = await showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredRecipes = recipes
                .where((r) => r.name.toLowerCase().contains(keyword.toLowerCase()))
                .toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      '레시피 선택',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // 검색창
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        textInputAction: TextInputAction.search,
                        onChanged: (value) {
                          setModalState(() {
                            keyword = value;
                          });
                        },
                        onSubmitted: (_) {}, // 완료 눌러도 유지
                        decoration: InputDecoration(
                          hintText: '레시피 이름 검색',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFB65A2C),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1),

                    Expanded(
                      child: filteredRecipes.isEmpty
                          ? const Center(
                        child: Text(
                          '검색 결과가 없습니다',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                          : ListView.separated(
                        itemCount: filteredRecipes.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final r = filteredRecipes[index];
                          return ListTile(
                            title: Text(r.name),
                            onTap: () => Navigator.pop(context, r),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedRecipe = picked);
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canSave = _selectedRecipe != null && _pickedImagePath != null;
    final entriesAsync = ref.watch(diaryProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 Row
            Row(
              children: _selectionMode
                  ? [
                // 취소
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectionMode = false;
                          _selectedIds.clear();
                        });
                      },
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
                SizedBox(
                  width: 110,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: entriesAsync.maybeWhen(
                      data: (entries) {
                        if (entries.isEmpty) return null;
                        return () {
                          setState(() {
                            final allIds = entries.map((e) => e.id).toSet();
                            final isAllSelected = _selectedIds.length == allIds.length;

                            if (isAllSelected) {
                              _selectedIds.clear();
                            } else {
                              _selectedIds
                                ..clear()
                                ..addAll(allIds);
                            }
                          });
                        };
                      },
                      orElse: () => null,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      entriesAsync.maybeWhen(
                        data: (entries) {
                          final allIds = entries.map((e) => e.id).toSet();
                          final isAllSelected =
                              _selectedIds.length == allIds.length && allIds.isNotEmpty;
                          return isAllSelected ? '전체 해제' : '전체 선택';
                        },
                        orElse: () => '전체 선택',
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 삭제
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () async {
                      final entries = entriesAsync.value ?? [];
                      final targets = entries.where((e) => _selectedIds.contains(e.id));
                      final messenger = ScaffoldMessenger.of(context);
                      for (final entry in targets) {
                        await ref.read(diaryProvider.notifier).deleteEntry(entry);
                      }
                      messenger.clearSnackBars();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('기록을 삭제하였습니다.')),
                      );

                      setState(() {
                        _selectionMode = false;
                        _selectedIds.clear();
                      });
                    },
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ]
                  : [
                // 새 요리 기록하기
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAddArea = !_showAddArea;
                          if (_showAddArea) {
                            _selectedRecipe = null;
                            _pickedImagePath = null;
                            _memoController.clear();
                          }
                        });

                        if (_showAddArea) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text(
                        '새 요리 기록하기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB65A2C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 휴지통
                SizedBox(
                  width: 52,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectionMode = true;
                        _selectedIds.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.delete_outline, size: 24),
                    ),
                  ),
                ),
              ],
            ),

            // 상단 Row 아래 구분선 추가 (3페이지와 동일 규격)
            const SizedBox(height: 8),
            const Divider(
              height: 24,
              thickness: 1,
            ),
            // const SizedBox(height: 0),

            // 새 기록 입력 영역
            if (_showAddArea)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SizedBox(height: 10),
                          Text(
                            '새 요리 기록',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.black,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            '레시피 선택',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),

                      InkWell(
                        onTap: _openRecipePicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300, width: 1.5),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedRecipe?.name ?? '레시피를 선택하세요',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey.shade600,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _memoController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '기록',
                          hintStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            borderSide: const BorderSide(
                              color: Color(0xFFB65A2C),
                              width: 1.8,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      InkWell(
                        onTap: _pickedImagePath == null ? _showImageSourceSheet : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 260,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                            color: Colors.grey.shade50,
                          ),
                          child: _pickedImagePath == null
                              ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.photo_camera_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '사진을 추가하세요',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                              : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_pickedImagePath!),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: _showImageSourceSheet,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _showAddArea = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey,
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                '취소',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: canSave
                                  ? () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final recipe = _selectedRecipe!;
                                final imagePath = _pickedImagePath!;
                                final memo = _memoController.text.trim();

                                await ref.read(diaryProvider.notifier).upsertEntry(
                                  DiaryEntry(
                                    recipeName: recipe.name,
                                    imagePath: imagePath,
                                    note: memo.isEmpty ? null : memo,
                                    createdAt: DateTime.now(),
                                  ),
                                );
                                messenger.clearSnackBars();
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('기록을 추가하였습니다.')),
                                );

                                setState(() {
                                  _showAddArea = false;
                                  _selectedRecipe = null;
                                  _pickedImagePath = null;
                                  _memoController.clear();
                                });

                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                });
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB65A2C),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                '저장',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // 기록 목록
            entriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => const SizedBox(),
              data: (entries) {
                if (entries.isEmpty) return const SizedBox();

                final shown = entries.reversed.toList();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: shown.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1 / 1.25,
                  ),
                  itemBuilder: (context, index) {
                    final entry = shown[index];

                    return Stack(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _selectionMode
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DiaryDetailPage(entry: entry),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: entry.imagePath != null
                                      ? Image.file(
                                    File(entry.imagePath!),
                                    fit: BoxFit.cover,
                                  )
                                      : Container(color: Colors.grey.shade200),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.recipeName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 100,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      Text(
                                        formatYyyyMmDd(entry.createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      if (entry.note != null &&
                                          entry.note!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          entry.note!.trim(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectionMode)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Checkbox(
                              value: _selectedIds.contains(entry.id),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedIds.add(entry.id);
                                  } else {
                                    _selectedIds.remove(entry.id);
                                  }
                                });
                              },
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
