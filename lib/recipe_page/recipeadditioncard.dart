import 'package:flutter/material.dart';

import "../classes/recipe.dart";
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RecipeAdditionCard extends StatefulWidget {
  const RecipeAdditionCard({
    super.key,
    required this.titleString,
    required this.onSubmitCallback,
    required this.onCancelCallback,
    this.initialRecipe,
  });

  final Future<void> Function(Recipe recipe) onSubmitCallback; // 레시피 저장 눌렀을 시의 callback, 에러 핸들링까지 해줘요!
  final VoidCallback onCancelCallback; // 레시피 취소 눌렀을 시의 callback.

  final Recipe? initialRecipe;
  final String titleString;

  @override
  State<RecipeAdditionCard> createState() => _RecipeAdditionCardState();
}

class _RecipeAdditionCardState extends State<RecipeAdditionCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _portionController;
  late final TextEditingController _timeController;
  late final List<TextEditingController> _ingredientControllers;
  late final List<TextEditingController> _stepControllers;
  late final List<TextEditingController> _memoControllers;

  final _picker = ImagePicker();
  String? _pickedMainImagePath;
  List<String?> _pickedStepImagePaths = [];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialRecipe?.name ?? '');
    _portionController = TextEditingController(text: widget.initialRecipe?.portionSize ?? '');
    _timeController = TextEditingController(text: widget.initialRecipe?.timeTaken ?? '');

    // wow
    _ingredientControllers = (widget.initialRecipe?.ingredients ?? []).map((ing) => TextEditingController(text: ing)).toList();
    _stepControllers = (widget.initialRecipe?.steps ?? []).map((step) => TextEditingController(text: step)).toList();
    _memoControllers = (widget.initialRecipe?.memos ?? []).map((memo) => TextEditingController(text: memo)).toList();
    _pickedMainImagePath = widget.initialRecipe?.mainImagePath;
    _pickedStepImagePaths = widget.initialRecipe?.stepImagePaths ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _portionController.dispose();
    _timeController.dispose();

    for (final c in _ingredientControllers) {
      c.dispose();
    }
    for (final c in _stepControllers) {
      c.dispose();
    }
    for (final c in _memoControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
      _pickedStepImagePaths.add(null);
    });
  }

  void _addMemo() {
    setState(() {
      _memoControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
      _pickedStepImagePaths.removeAt(index);
    });
  }

  void _removeMemo(int index) {
    setState(() {
      _memoControllers[index].dispose();
      _memoControllers.removeAt(index);
    });
  }

  Future<void> _pickImageFrom(ImageSource source, void Function(String path) callbackWithFilePath) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file != null) {
      callbackWithFilePath(file.path);
    }
  }

  Future<void> _showImageSourceSheet(void Function(String path) callbackWithFilePath) async {
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
                  await _pickImageFrom(ImageSource.gallery, callbackWithFilePath);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('카메라로 촬영'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFrom(ImageSource.camera, callbackWithFilePath);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final ingredientRows = <Widget>[];
    for (int i = 0; i < _ingredientControllers.length; i += 2) {
      ingredientRows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ingredientControllers[i],
                          decoration: InputDecoration(
                            labelText: '재료 ${i+1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFB65A2C)),
                        onPressed: () => _removeIngredient(i),
                      ),
                    ],
                  )
              ),
              const SizedBox(width: 8),
              Expanded(
                child: (i + 1 < _ingredientControllers.length)
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ingredientControllers[i+1],
                              decoration: InputDecoration(
                                labelText: '재료 ${i+2}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFB65A2C)),
                            onPressed: () => _removeIngredient(i+1),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }



    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        widget.onCancelCallback();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 제목
          Text(
            widget.titleString,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickedMainImagePath == null
                ? () => _showImageSourceSheet((path) {
              setState(() {
                _pickedMainImagePath = path;
              });
            })
                : null,
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
              child: _pickedMainImagePath == null
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
                      File(_pickedMainImagePath!),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () => _showImageSourceSheet((path) {
                        setState(() {
                          _pickedMainImagePath = path;
                        });
                      }),
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
          const SizedBox(height: 16),

          // 이름
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '레시피 이름',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // 분량, 소요시간
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _portionController,
                  decoration: const InputDecoration(
                    labelText: '분량 (선택사항)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    labelText: '시간 (선택사항)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),


          const Divider(height: 34, thickness: 1),

          // 재료
          _buildSectionHeader('재료', _addIngredient),
          const SizedBox(height: 8),
          ...ingredientRows,
          //const SizedBox(height: 12),

          // 단계
          _buildSectionHeader('단계', _addStep),
          const SizedBox(height: 8),
          ..._stepControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;

            return Column(
              children: [
                InkWell(
                  onTap: _pickedStepImagePaths[index] == null
                      ? () => _showImageSourceSheet((path) {
                        setState(() {
                          _pickedStepImagePaths[index] = path;
                        });
                      })
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: _pickedStepImagePaths[index] == null ? 88 : 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                      color: Colors.grey.shade50,
                    ),
                    child: _pickedStepImagePaths[index] == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.photo_camera_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
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
                            File(_pickedStepImagePaths[index]!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () => _showImageSourceSheet((path) {
                              setState(() {
                                _pickedStepImagePaths[index] = path;
                              });
                            }),
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
/*<<<<<<< HEAD*/
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: '순서 ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFB65A2C)),
                        onPressed: () => _removeStep(index),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 16, ),
              ],
            );
          }),
          // 메모
          _buildSectionHeader('메모', _addMemo),
          const SizedBox(height: 8),
          ..._memoControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: '메모 ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFB65A2C)),
                    onPressed: () => _removeMemo(index),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // 저장, 취소 버튼 (위치/디자인 통일)
          Row(
            children: [
              // ✅ 왼쪽: 취소 (뒤로가기/취소 스타일)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey, // ✅ 너가 통일하려던 그 글씨색
                      elevation: 0,
                      surfaceTintColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onPressed: widget.onCancelCallback,
                    child: const Text(
                      '취소',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ✅ 오른쪽: 레시피 저장 (저장 버튼 스타일)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB65A2C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);

                      if (_nameController.text.trim().isEmpty) {
                        messenger.clearSnackBars();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('레시피의 이름을 입력하세요.')),
                        );
                        return;
                      }

                      await widget.onSubmitCallback(
                        Recipe(
                          id: widget.initialRecipe?.id,
                          name: _nameController.text.trim(),
                          portionSize: _portionController.text.trim().isEmpty
                              ? null
                              : _portionController.text,
                          timeTaken: _timeController.text.trim().isEmpty
                              ? null
                              : _timeController.text,
                          ingredients: _ingredientControllers
                              .map((c) => c.text.trim())
                              .toList(),
                          steps: _stepControllers.map((c) => c.text.trim()).toList(),
                          memos: _memoControllers.map((c) => c.text.trim()).toList(),
                          mainImagePath: _pickedMainImagePath,
                          stepImagePaths: _pickedStepImagePaths,
                        ),
                      );
                    },
                    child: const Text(
                      '레시피 저장',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Color(0xFFB65A2C)),
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class PaddedRecipeAdditionCard extends StatelessWidget {
  const PaddedRecipeAdditionCard({
    super.key,
    required this.titleString,
    required this.onSubmitCallback,
    required this.onCancelCallback,
    this.initialRecipe,
  });

  final Future<void> Function(Recipe recipe) onSubmitCallback;
  final VoidCallback onCancelCallback;

  final Recipe? initialRecipe;
  final String titleString;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white, // ✅ 틴트 제거
      elevation: 0, // (원하면)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: RecipeAdditionCard(
          titleString: titleString,
          onSubmitCallback: onSubmitCallback,
          onCancelCallback: onCancelCallback,
          initialRecipe: initialRecipe,
        ),
      ),
    );
  }
}