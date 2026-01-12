import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'classes/diary_entry.dart';
import 'data/diary_entry_provider.dart';

class DiaryDetailPage extends ConsumerStatefulWidget {
  final DiaryEntry entry;

  const DiaryDetailPage({super.key, required this.entry});

  @override
  ConsumerState<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends ConsumerState<DiaryDetailPage> {
  bool _isEditing = false;

  late String? _imagePath;
  late TextEditingController _memoController;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _imagePath = widget.entry.imagePath;
    _memoController = TextEditingController(text: widget.entry.note ?? '');
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file != null) {
      setState(() {
        _imagePath = file.path;
      });
    }
  }

  Future<void> _save() async {
    await ref.read(diaryProvider.notifier).upsertEntry(
      DiaryEntry(
        id: widget.entry.id, // ⭐ 기존 기록 업데이트
        recipeName: widget.entry.recipeName,
        imagePath: _imagePath,
        note: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
      ),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.recipeName),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _save();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 📷 사진 영역
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _imagePath != null
                        ? Image.file(
                      File(_imagePath!),
                      fit: BoxFit.cover,
                    )
                        : Container(color: Colors.grey.shade200),
                  ),
                ),

                // ✏️ 편집 모드일 때만 아이콘 표시
                if (_isEditing)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

// 📝 메모 영역
            if (_isEditing || widget.entry.note?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),

              const Text(
                '메모',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB65A2C), // 로고 색
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFB65A2C), // 로고 색 테두리
                    width: 1.5,
                  ),
                ),
                child: _isEditing
                    ? TextField(
                  controller: _memoController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: '메모를 입력하세요',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                )
                    : Text(
                  widget.entry.note!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
