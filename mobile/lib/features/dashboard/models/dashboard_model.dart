class DashboardNutrition {
  final int consumedCalories;
  final int targetCalories;
  final int remainingCalories;
  final int proteinGrams;
  final int targetProteinGrams;
  final int carbsGrams;
  final int targetCarbsGrams;
  final int fatGrams;
  final int targetFatGrams;

  const DashboardNutrition({
    required this.consumedCalories,
    required this.targetCalories,
    required this.remainingCalories,
    required this.proteinGrams,
    this.targetProteinGrams = 140,
    required this.carbsGrams,
    this.targetCarbsGrams = 185,
    required this.fatGrams,
    this.targetFatGrams = 50,
  });

  factory DashboardNutrition.fromJson(Map<String, dynamic> json) {
    final target = (json['targetCalories'] as num?)?.toInt() ?? 1920;
    final consumed = (json['consumedCalories'] as num?)?.toInt() ?? 0;
    return DashboardNutrition(
      consumedCalories: consumed,
      targetCalories: target,
      remainingCalories: (json['remainingCalories'] as num?)?.toInt() ?? (target - consumed),
      proteinGrams: (json['proteinGrams'] as num?)?.toInt() ?? 0,
      carbsGrams: (json['carbsGrams'] as num?)?.toInt() ?? 0,
      fatGrams: (json['fatGrams'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardWorkout {
  final String id;
  final String title;
  final String status;
  final bool isCompleted;
  final int durationMinutes;
  final int exerciseCount;

  const DashboardWorkout({
    required this.id,
    required this.title,
    required this.status,
    required this.isCompleted,
    this.durationMinutes = 45,
    this.exerciseCount = 5,
  });

  factory DashboardWorkout.fromJson(Map<String, dynamic> json) {
    return DashboardWorkout(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Upper Body Hypertrophy',
      status: json['status'] as String? ?? 'scheduled',
      isCompleted: json['isCompleted'] as bool? ?? false,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 45,
      exerciseCount: (json['exerciseCount'] as num?)?.toInt() ?? 5,
    );
  }
}

class DashboardStepTelemetry {
  final int todayCount;
  final int targetCount;
  final double distanceKm;
  final int caloriesBurned;

  const DashboardStepTelemetry({
    this.todayCount = 8420,
    this.targetCount = 10000,
    this.distanceKm = 6.2,
    this.caloriesBurned = 345,
  });

  double get progressRatio =>
      (todayCount / (targetCount <= 0 ? 1 : targetCount)).clamp(0.0, 1.0);
  int get progressPercentage => (progressRatio * 100).toInt();

  factory DashboardStepTelemetry.fromJson(Map<String, dynamic> json) {
    return DashboardStepTelemetry(
      todayCount: (json['todayCount'] as num?)?.toInt() ?? 8420,
      targetCount: (json['targetCount'] as num?)?.toInt() ?? 10000,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 6.2,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt() ?? 345,
    );
  }
}

class DashboardSummary {
  final String greeting;
  final String primaryGoal;
  final String classificationBadge;
  final DashboardWorkout? todayWorkout;
  final DashboardNutrition nutrition;
  final DashboardStepTelemetry steps;
  final int streakDays;
  final List<dynamic> recentWorkouts;
  final List<dynamic> recentGpsRuns;

  const DashboardSummary({
    required this.greeting,
    required this.primaryGoal,
    required this.classificationBadge,
    this.todayWorkout,
    required this.nutrition,
    this.steps = const DashboardStepTelemetry(),
    this.streakDays = 4,
    this.recentWorkouts = const [],
    this.recentGpsRuns = const [],
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      greeting: json['greeting'] as String? ?? 'Good morning, Athlete!',
      primaryGoal: json['primaryGoal'] as String? ?? 'weight_management',
      classificationBadge: json['classificationBadge'] as String? ?? 'INTERMEDIATE_WEIGHT_MANAGEMENT',
      todayWorkout: json['todayWorkout'] != null
          ? DashboardWorkout.fromJson(json['todayWorkout'] as Map<String, dynamic>)
          : null,
      nutrition: json['nutrition'] != null
          ? DashboardNutrition.fromJson(json['nutrition'] as Map<String, dynamic>)
          : const DashboardNutrition(consumedCalories: 0, targetCalories: 1920, remainingCalories: 1920, proteinGrams: 0, carbsGrams: 0, fatGrams: 0),
      steps: json['steps'] != null
          ? DashboardStepTelemetry.fromJson(json['steps'] as Map<String, dynamic>)
          : const DashboardStepTelemetry(),
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 4,
      recentWorkouts: json['recentWorkouts'] as List<dynamic>? ?? [],
      recentGpsRuns: json['recentGpsRuns'] as List<dynamic>? ?? [],
    );
  }
}

