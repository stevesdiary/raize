import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/athletic_button.dart';
import '../providers/assessment_provider.dart';
import 'blueprint_screen.dart';

class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(assessmentProvider.notifier).initAssessment());
  }

  void _onNext() async {
    final state = ref.read(assessmentProvider);
    final notifier = ref.read(assessmentProvider.notifier);

    // If on the final stage (STAGE_F), complete and navigate
    if (state.currentStageIndex == AssessmentState.stages.length - 1) {
      final success = await notifier.completeAssessment();
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (ctx, anim1, anim2) => const BlueprintScreen(),
            transitionsBuilder: (ctx, anim, secAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    } else {
      notifier.nextStage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);
    final notifier = ref.read(assessmentProvider.notifier);
    final authUser = ref.watch(authProvider).user;
    final currentStage = state.currentStage;
    final questions = state.currentStageQuestions;
    final canProceed = notifier.canProceed();
    final isLastStage = state.currentStageIndex == AssessmentState.stages.length - 1;

    // Check if E05 cardiac warning is triggered
    final isCardiacAlertActive =
        currentStage == 'STAGE_E' &&
        (state.responses['E05'] == 'yes' || state.responses['E05'] == 'prefer_not_to_say');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Stage ${String.fromCharCode(65 + state.currentStageIndex)}: ${state.currentStageTitle}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: state.currentStageIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => notifier.previousStage(),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Apple HIG Fluid Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STAGE ${String.fromCharCode(65 + state.currentStageIndex)} OF ${AssessmentState.stages.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '${(state.progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 6,
                      backgroundColor: AppColors.card,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Cardiac Critical Warning Banner (Stage E)
            if (isCardiacAlertActive)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.destructive, width: 1.5),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.destructive, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SAFETY CIRCUIT BREAKER ACTIVE',
                            style: TextStyle(
                              color: AppColors.destructive,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You reported experiencing chest pain, fainting, or dizziness during exercise. Standard recommendations will be paused for your safety, and medical clearance will be advised.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Questions List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                itemCount: questions.length,
                itemBuilder: (context, qIndex) {
                  final q = questions[qIndex];
                  final currentAnswer = state.responses[q.id];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verified Account Profile Data Banner on Stage A
                        if (currentStage == 'STAGE_A' && qIndex == 0) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.emerald.withAlpha(90)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.emerald.withAlpha(35),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.emerald.withAlpha(80)),
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_rounded,
                                    color: AppColors.emerald,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'VERIFIED ACCOUNT DATA',
                                        style: TextStyle(
                                          color: AppColors.emerald,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'DOB: ${authUser?.dateOfBirth ?? "Recorded"} • Units: ${(authUser?.preferredMeasurement ?? "Metric").toUpperCase()}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Auto-linked from registration • No re-entry required',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Question Header
                        Text(
                          q.questionText,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                        ),
                        if (q.helpText != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            q.helpText!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Options Cards
                        ...q.options.map((opt) {
                          final isSelected = currentAnswer == opt.value;

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              notifier.setResponse(q.id, opt.value);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.cardElevated : AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withAlpha(30),
                                          blurRadius: 12,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? AppColors.primary : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          opt.label,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : AppColors.textPrimary,
                                            fontSize: 14.5,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                        if (opt.description != null) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            opt.description!,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Fixed Bottom Action CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: AthleticButton(
                text: isLastStage
                    ? 'Generate Fitness Blueprint'
                    : 'Continue to Stage ${String.fromCharCode(66 + state.currentStageIndex)}',
                isLoading: state.isSubmitting,
                onPressed: canProceed ? _onNext : null,
                variant: isCardiacAlertActive
                    ? AthleticButtonVariant.destructive
                    : AthleticButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
