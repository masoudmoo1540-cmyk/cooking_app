class StepModel {
  final int? id;
  final int recipeId;
  final int stepNumber;
  final String description;
  final int timerMinutes; // زمان به ثانیه

  StepModel({
    this.id,
    required this.recipeId,
    required this.stepNumber,
    required this.description,
    required this.timerMinutes,
  });

  factory StepModel.fromMap(Map<String, dynamic> map) {
    return StepModel(
      id: map['id'] as int?,
      recipeId: map['recipe_id'] as int,
      stepNumber: map['step_number'] as int,
      description: map['description'] as String,
      timerMinutes: map['timer_minutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'step_number': stepNumber,
      'description': description,
      'timer_minutes': timerMinutes,
    };
  }
}