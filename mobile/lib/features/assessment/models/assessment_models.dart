class AssessmentOption {
  final String id;
  final String label;
  final String value;
  final String? description;
  final String? icon;

  const AssessmentOption({
    required this.id,
    required this.label,
    required this.value,
    this.description,
    this.icon,
  });

  factory AssessmentOption.fromJson(Map<String, dynamic> json) {
    return AssessmentOption(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? json['displayText'] ?? json['text'] ?? '').toString(),
      value: (json['value'] ?? json['optionValue'] ?? '').toString(),
      description: json['description'] as String?,
      icon: json['icon'] as String?,
    );
  }
}

class AssessmentQuestion {
  final String id;
  final String stage;
  final String questionText;
  final String questionType; // single_select, multi_select, date_picker, text, slider
  final bool isRequired;
  final String? helpText;
  final List<AssessmentOption> options;

  const AssessmentQuestion({
    required this.id,
    required this.stage,
    required this.questionText,
    required this.questionType,
    this.isRequired = true,
    this.helpText,
    this.options = const [],
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    final rawType = json['questionType'] ?? json['inputType'] ?? 'single_select';
    final normalizedType = rawType == 'single_choice'
        ? 'single_select'
        : rawType == 'multi_choice'
            ? 'multi_select'
            : rawType.toString();

    return AssessmentQuestion(
      id: json['id'] as String? ?? '',
      stage: json['stage'] as String? ?? 'STAGE_A',
      questionText: json['questionText'] as String? ?? '',
      questionType: normalizedType,
      isRequired: json['isRequired'] as bool? ?? true,
      helpText: json['helpText'] as String?,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => AssessmentOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AssessmentClassification {
  final String primaryGoal;
  final String experience;
  final String activityBaseline;
  final String trainingEnvironment;
  final String availabilityLevel;
  final String safetyStatus;

  const AssessmentClassification({
    required this.primaryGoal,
    required this.experience,
    required this.activityBaseline,
    required this.trainingEnvironment,
    required this.availabilityLevel,
    required this.safetyStatus,
  });

  factory AssessmentClassification.fromJson(Map<String, dynamic> json) {
    return AssessmentClassification(
      primaryGoal: json['primaryGoal'] as String? ?? 'weight_management',
      experience: json['experience'] as String? ?? 'beginner',
      activityBaseline: json['activityBaseline'] as String? ?? 'moderate',
      trainingEnvironment: json['trainingEnvironment'] as String? ?? 'home',
      availabilityLevel: json['availabilityLevel'] as String? ?? 'moderate',
      safetyStatus: json['safetyStatus'] as String? ?? 'standard',
    );
  }
}

class AssessmentNutrition {
  final int bmr;
  final int tdee;
  final int targetDailyCalories;

  const AssessmentNutrition({
    required this.bmr,
    required this.tdee,
    required this.targetDailyCalories,
  });

  factory AssessmentNutrition.fromJson(Map<String, dynamic> json) {
    return AssessmentNutrition(
      bmr: (json['bmr'] as num?)?.toInt() ?? 1600,
      tdee: (json['tdee'] as num?)?.toInt() ?? 2200,
      targetDailyCalories: (json['targetDailyCalories'] as num?)?.toInt() ?? 1800,
    );
  }
}

