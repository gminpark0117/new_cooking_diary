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
  String name;
  int portionSize;
  int timeTaken;
  List<String> ingredients;
  List<String> steps;
}