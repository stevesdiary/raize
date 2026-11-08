import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/assessment_models.dart';

class AssessmentState {
  final bool isLoading;
  final String? assessmentId;
  final List<AssessmentQuestion> questions;
  final int currentStageIndex;
  final Map<String, dynamic> responses;
  final bool isSubmitting;
  final bool isCompleted;
  final bool isCriticalStop;
  final String? safetyDisclaimer;
  final AssessmentClassification? classification;
  final AssessmentNutrition? nutrition;
  final String? errorMessage;

  static const List<String> stages = [
    'STAGE_A',
    'STAGE_B',
    'STAGE_C',
    'STAGE_D',
    'STAGE_E',
    'STAGE_F',
  ];

  static const Map<String, String> stageTitles = {
    'STAGE_A': 'Personal Profile',
    'STAGE_B': 'Fitness Goals',
    'STAGE_C': 'Current Condition',
    'STAGE_D': 'Training Preferences',
    'STAGE_E': 'Health & Safety',
    'STAGE_F': 'Readiness & Habit',
  };

  const AssessmentState({
    this.isLoading = false,
    this.assessmentId,
    this.questions = const [],
    this.currentStageIndex = 0,
    this.responses = const {},
    this.isSubmitting = false,
    this.isCompleted = false,
    this.isCriticalStop = false,
    this.safetyDisclaimer,
    this.classification,
    this.nutrition,
    this.errorMessage,
  });

  String get currentStage => stages[currentStageIndex];
  String get currentStageTitle => stageTitles[currentStage] ?? '';
  double get progress => (currentStageIndex + 1) / stages.length;

  List<AssessmentQuestion> get currentStageQuestions {
    // In Stage A, omit A01 (Date of Birth) and A06 (Units) because they were already
    // verified and collected during account registration!
    return questions
        .where((q) => q.stage == currentStage && q.id != 'A01' && q.id != 'A06')
        .toList();
  }

  AssessmentState copyWith({
    bool? isLoading,
    String? assessmentId,
    List<AssessmentQuestion>? questions,
    int? currentStageIndex,
    Map<String, dynamic>? responses,
    bool? isSubmitting,
    bool? isCompleted,
    bool? isCriticalStop,
    String? safetyDisclaimer,
    AssessmentClassification? classification,
    AssessmentNutrition? nutrition,
    String? errorMessage,
  }) {
    return AssessmentState(
      isLoading: isLoading ?? this.isLoading,
      assessmentId: assessmentId ?? this.assessmentId,
      questions: questions ?? this.questions,
      currentStageIndex: currentStageIndex ?? this.currentStageIndex,
      responses: responses ?? this.responses,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCompleted: isCompleted ?? this.isCompleted,
      isCriticalStop: isCriticalStop ?? this.isCriticalStop,
      safetyDisclaimer: safetyDisclaimer ?? this.safetyDisclaimer,
      classification: classification ?? this.classification,
      nutrition: nutrition ?? this.nutrition,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final assessmentProvider =
    NotifierProvider<AssessmentNotifier, AssessmentState>(AssessmentNotifier.new);

class AssessmentNotifier extends Notifier<AssessmentState> {
  @override
  AssessmentState build() {
    // Provide full offline seed questions immediately so UI renders instantly
    final fallbackQuestions = _buildFallbackQuestions();
    return AssessmentState(questions: fallbackQuestions);
  }

  Future<void> initAssessment() async {
    final apiClient = ref.read(apiClientProvider);

    try {
      // 1. Fetch remote questions if available
      final qResponse = await apiClient.client.get(ApiEndpoints.assessmentQuestions);
      List<AssessmentQuestion> questions = state.questions;
      if (qResponse.statusCode == 200 && qResponse.data['data'] != null) {
        final list = qResponse.data['data'] as List<dynamic>;
        final remoteQuestions = list
            .map((item) => AssessmentQuestion.fromJson(item as Map<String, dynamic>))
            .toList();

        // Merge curated fallback options if remote options are empty
        final fallbackMap = {for (final q in _buildFallbackQuestions()) q.id: q};
        questions = remoteQuestions.map((q) {
          final fallback = fallbackMap[q.id];
          if (q.options.isEmpty && fallback != null && fallback.options.isNotEmpty) {
            return AssessmentQuestion(
              id: q.id,
              stage: q.stage,
              questionText: q.questionText.isNotEmpty ? q.questionText : fallback.questionText,
              questionType: q.questionType,
              isRequired: fallback.isRequired,
              helpText: q.helpText ?? fallback.helpText,
              options: fallback.options,
            );
          }
          return q;
        }).toList();
      }

      // 2. Initialize draft session
      String? assessmentId = state.assessmentId;
      Map<String, dynamic> responses = Map<String, dynamic>.from(state.responses);

      // Pre-fill responses from authenticated user profile (Date of Birth & Measurement Units)
      final authUser = ref.read(authProvider).user;
      if (authUser?.dateOfBirth != null && authUser!.dateOfBirth!.isNotEmpty) {
        responses['A01'] = authUser.dateOfBirth;
      }
      if (authUser?.preferredMeasurement != null) {
        responses['A06'] = authUser!.preferredMeasurement;
      }

      final draftResponse = await apiClient.client.post(ApiEndpoints.assessments, data: {});
      if (draftResponse.statusCode == 200 || draftResponse.statusCode == 201) {
        final data = draftResponse.data['data'];
        assessmentId = data['id'];
        if (data['responses'] != null) {
          responses.addAll(Map<String, dynamic>.from(data['responses']));
        }
      }

      state = state.copyWith(
        assessmentId: assessmentId,
        questions: questions,
        responses: responses,
        isLoading: false,
      );
    } catch (_) {
      // Offline mode: proceed seamlessly with fallback questions
      final responses = Map<String, dynamic>.from(state.responses);
      final authUser = ref.read(authProvider).user;
      if (authUser?.dateOfBirth != null && authUser!.dateOfBirth!.isNotEmpty) {
        responses['A01'] = authUser.dateOfBirth;
      }
      if (authUser?.preferredMeasurement != null) {
        responses['A06'] = authUser!.preferredMeasurement;
      }
      state = state.copyWith(responses: responses, isLoading: false);
    }
  }

  void setResponse(String questionId, dynamic value) {
    final updated = Map<String, dynamic>.from(state.responses);
    updated[questionId] = value;
    state = state.copyWith(responses: updated);

    // Auto-save to backend
    if (state.assessmentId != null) {
      final apiClient = ref.read(apiClientProvider);
      try {
        apiClient.client.put(
          '${ApiEndpoints.assessments}/${state.assessmentId}/responses',
          data: {
            'stage': state.currentStage,
            'responses': {questionId: value},
          },
        );
      } catch (_) {}
    }
  }

  void toggleMultiSelect(String questionId, String optionValue) {
    final updated = Map<String, dynamic>.from(state.responses);
    final currentList = (updated[questionId] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    if (currentList.contains(optionValue)) {
      currentList.remove(optionValue);
    } else {
      currentList.add(optionValue);
    }

    updated[questionId] = currentList;
    state = state.copyWith(responses: updated);

    if (state.assessmentId != null) {
      final apiClient = ref.read(apiClientProvider);
      try {
        apiClient.client.put(
          '${ApiEndpoints.assessments}/${state.assessmentId}/responses',
          data: {
            'stage': state.currentStage,
            'responses': {questionId: currentList},
          },
        );
      } catch (_) {}
    }
  }

  bool canProceed() {
    for (final q in state.currentStageQuestions) {
      if (q.isRequired) {
        final res = state.responses[q.id];
        if (res == null) return false;
        if (res is String && res.trim().isEmpty) return false;
        if (res is List && res.isEmpty) return false;
      }
    }
    return true;
  }

  void nextStage() {
    if (state.currentStageIndex < AssessmentState.stages.length - 1) {
      state = state.copyWith(currentStageIndex: state.currentStageIndex + 1);
    }
  }

  void previousStage() {
    if (state.currentStageIndex > 0) {
      state = state.copyWith(currentStageIndex: state.currentStageIndex - 1);
    }
  }

  Future<bool> completeAssessment() async {
    state = state.copyWith(isSubmitting: true);
    final apiClient = ref.read(apiClientProvider);

    try {
      final id = state.assessmentId ?? 'draft_assessment';
      final response = await apiClient.client.post(
        '${ApiEndpoints.assessments}/$id/complete',
        data: {},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        final isCritical = data['isCriticalStop'] == true;
        final disclaimer = data['safetyDisclaimer'] as String?;
        final classification = AssessmentClassification.fromJson(data['classification']);
        final nutrition = AssessmentNutrition.fromJson(data['nutrition']);

        state = state.copyWith(
          isSubmitting: false,
          isCompleted: true,
          isCriticalStop: isCritical,
          safetyDisclaimer: disclaimer,
          classification: classification,
          nutrition: nutrition,
        );
        return true;
      }
    } catch (_) {
      // Offline fallback calculation
      final e05 = state.responses['E05'];
      final isCritical = e05 == 'yes' || e05 == 'prefer_not_to_say';
      final goal = state.responses['B01'] ?? 'weight_management';
      final level = state.responses['C01'] ?? 'beginner';

      state = state.copyWith(
        isSubmitting: false,
        isCompleted: true,
        isCriticalStop: isCritical,
        safetyDisclaimer: isCritical
            ? 'URGENT: Exercise recommendations are paused. You reported symptoms such as chest pain or fainting during exercise. Please seek medical evaluation from a healthcare professional before engaging in physical training.'
            : null,
        classification: AssessmentClassification(
          primaryGoal: goal,
          experience: level,
          activityBaseline: state.responses['C05'] ?? 'low_active',
          trainingEnvironment: state.responses['D03'] ?? 'home',
          availabilityLevel: state.responses['D01'] ?? '3',
          safetyStatus: isCritical ? 'exercise_paused_pending_assessment' : 'standard',
        ),
        nutrition: const AssessmentNutrition(
          bmr: 1680,
          tdee: 2350,
          targetDailyCalories: 1850,
        ),
      );
      return true;
    }

    state = state.copyWith(isSubmitting: false);
    return false;
  }

  static List<AssessmentQuestion> _buildFallbackQuestions() {
    return [
      // STAGE A
      const AssessmentQuestion(
        id: 'A02',
        stage: 'STAGE_A',
        questionText: 'What is your biological sex?',
        questionType: 'single_select',
        isRequired: false,
        helpText: 'Used exclusively to calibrate metabolic basal rate (BMR).',
        options: [
          AssessmentOption(id: 'a02_1', label: 'Male', value: 'male'),
          AssessmentOption(id: 'a02_2', label: 'Female', value: 'female'),
          AssessmentOption(id: 'a02_3', label: 'Prefer not to say', value: 'prefer_not_to_say'),
        ],
      ),
      const AssessmentQuestion(
        id: 'A03',
        stage: 'STAGE_A',
        questionText: 'What is your height & weight?',
        questionType: 'single_select',
        isRequired: false,
        options: [
          AssessmentOption(id: 'a03_1', label: 'Standard Adult Metric (175 cm, 72 kg)', value: 'standard_metric'),
          AssessmentOption(id: 'a03_2', label: 'Custom Biometrics', value: 'custom'),
        ],
      ),

      // STAGE B
      const AssessmentQuestion(
        id: 'B01',
        stage: 'STAGE_B',
        questionText: 'What is your primary fitness goal?',
        questionType: 'single_select',
        isRequired: true,
        options: [
          AssessmentOption(id: 'b01_1', label: 'Weight Management', value: 'weight_management', description: 'Sustainable fat loss & lean body composition'),
          AssessmentOption(id: 'b01_2', label: 'Build Muscle', value: 'build_muscle', description: 'Hypertrophy & muscular development'),
          AssessmentOption(id: 'b01_3', label: 'Build Strength', value: 'build_strength', description: 'Peak physical strength & progressive overload'),
          AssessmentOption(id: 'b01_4', label: 'Improve Endurance', value: 'improve_endurance', description: 'Cardiovascular capacity & stamina'),
          AssessmentOption(id: 'b01_5', label: 'Functional Mobility', value: 'improve_flexibility', description: 'Joint health, balance & injury resilience'),
        ],
      ),
      const AssessmentQuestion(
        id: 'B04',
        stage: 'STAGE_B',
        questionText: 'What is your target timeline?',
        questionType: 'single_select',
        isRequired: true,
        options: [
          AssessmentOption(id: 'b04_1', label: 'Within 4 Weeks', value: '4_weeks'),
          AssessmentOption(id: 'b04_2', label: 'Within 8 Weeks', value: '8_weeks'),
          AssessmentOption(id: 'b04_3', label: 'Within 12 Weeks', value: '12_weeks'),
          AssessmentOption(id: 'b04_4', label: 'Within 6 Months', value: '6_months'),
        ],
      ),

      // STAGE C
      const AssessmentQuestion(
        id: 'C01',
        stage: 'STAGE_C',
        questionText: 'How would you describe your current fitness level?',
        questionType: 'single_select',
        isRequired: true,
        options: [
          AssessmentOption(id: 'c01_1', label: 'Beginner', value: 'beginner', description: 'Just starting or returning after a long break'),
          AssessmentOption(id: 'c01_2', label: 'Intermediate', value: 'intermediate', description: 'Consistently active for 6+ months'),
          AssessmentOption(id: 'c01_3', label: 'Advanced', value: 'advanced', description: 'Structured training with progressive overload for 2+ years'),
        ],
      ),
      const AssessmentQuestion(
        id: 'C05',
        stage: 'STAGE_C',
        questionText: 'How active is your typical day?',
        questionType: 'single_select',
        isRequired: true,
        options: [
          AssessmentOption(id: 'c05_1', label: 'Mostly Sitting (Desk Job)', value: 'sedentary'),
          AssessmentOption(id: 'c05_2', label: 'Some Movement / Standing', value: 'low_active'),
          AssessmentOption(id: 'c05_3', label: 'Frequently Walking', value: 'active'),
          AssessmentOption(id: 'c05_4', label: 'Physically Demanding', value: 'very_active'),
        ],
      ),

      // STAGE D
      const AssessmentQuestion(
        id: 'D01',
        stage: 'STAGE_D',
        questionText: 'How many days can you train weekly?',
        questionType: 'single_select',
        isRequired: true,
        options: [
          AssessmentOption(id: 'd01_1', label: '2 Days / Week', value: '1_2'),
          AssessmentOption(id: 'd01_2', label: '3 Days / Week (Optimal)', value: '3'),
          AssessmentOption(id: 'd01_3', label: '4-5 Days / Week', value: '4_5'),
          AssessmentOption(id: 'd01_4', label: '6 Days / Week', value: '6_7'),
        ],
      ),
      const AssessmentQuestion(
        id: 'D03',
        stage: 'STAGE_D',
        questionText: 'Where do you prefer training?',
        questionType: 'single_select',
        isRequired: true,
        options: [
          AssessmentOption(id: 'd03_1', label: 'Home (Bodyweight & Bands)', value: 'home'),
          AssessmentOption(id: 'd03_2', label: 'Commercial Gym (Full Equipment)', value: 'gym'),
          AssessmentOption(id: 'd03_3', label: 'Outdoors (Running & Calisthenics)', value: 'outdoors'),
          AssessmentOption(id: 'd03_4', label: 'Hybrid Combination', value: 'combination'),
        ],
      ),

      // STAGE E - Safety Critical
      const AssessmentQuestion(
        id: 'E01',
        stage: 'STAGE_E',
        questionText: 'Do you have an injury or joint limitation?',
        questionType: 'single_select',
        isRequired: true,
        options: [
          AssessmentOption(id: 'e01_1', label: 'No Limiting Injuries', value: 'no'),
          AssessmentOption(id: 'e01_2', label: 'Yes, Knees / Lower Body', value: 'yes'),
          AssessmentOption(id: 'e01_3', label: 'Yes, Shoulders / Upper Body', value: 'yes'),
        ],
      ),
      const AssessmentQuestion(
        id: 'E05',
        stage: 'STAGE_E',
        questionText: 'Do you experience chest pain, fainting, or severe dizziness during exercise?',
        questionType: 'single_select',
        isRequired: true,
        helpText: 'Safety-critical screening per ACSM & WHO guidelines.',
        options: [
          AssessmentOption(id: 'e05_1', label: 'No, Never', value: 'no'),
          AssessmentOption(id: 'e05_2', label: 'Yes, I have experienced these', value: 'yes', description: 'Triggers safety pause and medical evaluation advisory'),
          AssessmentOption(id: 'e05_3', label: 'Prefer not to say', value: 'prefer_not_to_say'),
        ],
      ),

      // STAGE F - Readiness
      const AssessmentQuestion(
        id: 'F01',
        stage: 'STAGE_F',
        questionText: 'What best describes your current motivation?',
        questionType: 'single_select',
        isRequired: true,
        options: [
          AssessmentOption(id: 'f01_1', label: 'Building Long-Term Consistency', value: 'high'),
          AssessmentOption(id: 'f01_2', label: 'Ready for Structured Discipline', value: 'very_high'),
          AssessmentOption(id: 'f01_3', label: 'Need Accountability & Support', value: 'moderate'),
        ],
      ),
      const AssessmentQuestion(
        id: 'F04',
        stage: 'STAGE_F',
        questionText: 'Are you willing to log meals and track daily calories?',
        questionType: 'single_select',
        isRequired: true,
        options: [
          AssessmentOption(id: 'f04_1', label: 'Yes, Daily Meal Tracking', value: 'yes_daily'),
          AssessmentOption(id: 'f04_2', label: 'Weekly General Estimates', value: 'weekly_estimates'),
          AssessmentOption(id: 'f04_3', label: 'Workout Only, No Diet Tracking', value: 'no'),
        ],
      ),
    ];
  }
}
