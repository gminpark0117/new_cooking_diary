import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import "../recipe.dart";
import "../providers.dart";

class RecipeAdditionCard extends ConsumerStatefulWidget {
  const RecipeAdditionCard({super.key});

  @override
  ConsumerState<RecipeAdditionCard> createState() => _RecipeAdditionCardState();
}

class _RecipeAdditionCardState extends ConsumerState<RecipeAdditionCard> {
  bool _showRecipeAdditionCard = false;

  final _nameController = TextEditingController();
  final _portionController = TextEditingController();
  final _timeController = TextEditingController();

  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _stepControllers = [];

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
    });
  }

  void _submitRecipe(Recipe recipe) {
    ref.read(recipeProvider.notifier).addRecipe(recipe);
    setState(() {
      _showRecipeAdditionCard = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("rebuilding, showcard: $_showRecipeAdditionCard");
    return Column(
      children: [
        FilledButton (
          child: Text('레시피 추가'),
          onPressed: () {
            setState(() {
              _showRecipeAdditionCard = !_showRecipeAdditionCard;
            });
          },
        ),
        if (_showRecipeAdditionCard)
          Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Recipe',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    /// Name
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Recipe Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Portion Size
                    TextField(
                      controller: _portionController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Portion Size (in servings)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Estimated Time
                    TextField(
                      controller: _timeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Estimated Time (minutes)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// Ingredients
                    _buildSectionHeader('Ingredients', _addIngredient),
                    const SizedBox(height: 8),
                    ..._ingredientControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Ingredient ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeIngredient(index),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    /// Steps
                    _buildSectionHeader('Steps', _addStep),
                    const SizedBox(height: 8),
                    ..._stepControllers.asMap().entries.map((entry) {
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
                                  labelText: 'Step ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeStep(index),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),


                    Row(
                      children: [
                        /// Submit Button
                         Expanded(
                          child: FilledButton(
                            onPressed: () =>
                              _submitRecipe(Recipe(
                                  portionSize: int.tryParse(_portionController.text.trim()),
                                  timeTaken: int.tryParse(_timeController.text.trim()),
                                  name: _nameController.text.trim(),
                                  ingredients: _ingredientControllers.map((controller) => controller.text.trim()).toList(),
                                  steps: _stepControllers.map((controller) => controller.text.trim()).toList(),
                              )),
                            child: const Text('Save Recipe'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        /// Cancel Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                setState(() {
                                  _showRecipeAdditionCard = false;
                                }),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
          icon: const Icon(Icons.add),
          onPressed: onAdd,
        ),
      ],
    );
  }
}
