class Recipe {
  Recipe({
    required this.name,
    this.portionSize,
    this.timeTaken,
    required this.ingredients,
    required this.steps,
  });
  String name;
  int? portionSize;
  int? timeTaken;
  List<String> ingredients;
  List<String> steps;
}