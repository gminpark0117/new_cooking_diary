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

  Future<void> _pickImageFrom(ImageSource source) async {
    if (!_isEditing) return;

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (file != null) {
      setState(() {
        _imagePath = file.path;
      });
    }
  }

  Future<void> _showImageSourceSheet() async {
    if (!_isEditing) return;
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

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(diaryProvider.notifier).upsertEntry(
      DiaryEntry(
        id: widget.entry.id, // 기존 기록 업데이트
        recipeName: widget.entry.recipeName,
        imagePath: _imagePath,
        note: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        createdAt: widget.entry.createdAt,
      ),
    );
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(content: Text('기록을 수정하였습니다.')),
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
                      onTap: _showImageSourceSheet,
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
