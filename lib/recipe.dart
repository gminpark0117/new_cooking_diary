import 'package:uuid/uuid.dart';

var uuid = Uuid();
class Recipe {
  Recipe({
    required this.name,
    required this.portionSize,
    required this.timeTaken,
    required this.ingredients,
    required this.steps,
  });
  final String id = uuid.v4();
  final String name;
  final int portionSize;
  final int timeTaken;
  final List<String> ingredients;
  final List<String> steps;
}