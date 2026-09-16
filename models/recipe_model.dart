class RecipeModel {
  final int? id;
  final String name;
  final String category;
  final String ingredients;
  final String? lastCooked;
  final int cookCount;
  final String? imagePath;

  RecipeModel({
    this.id,
    required this.name,
    required this.category,
    required this.ingredients,
    this.lastCooked,
    this.cookCount = 0,
    this.imagePath,
  });

  factory RecipeModel.fromMap(Map<String, dynamic> map) {
    return RecipeModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      ingredients: map['ingredients'] as String,
      lastCooked: map['last_cooked'] as String?,
      cookCount: map['cook_count'] as int? ?? 0,
      imagePath: map['image_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'ingredients': ingredients,
      'last_cooked': lastCooked,
      'cook_count': cookCount,
      'image_path': imagePath,
    };
  }
}