import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/workout_provider.dart';
import '../widgets/exercise_hero_card.dart';
import '../widgets/exercise_video_demo_sheet.dart';
import '../widgets/set_logging_table.dart';
import '../widgets/rest_timer_hud.dart';
import '../widgets/volume_tonnage_footer.dart';

class LiveWorkoutScreen extends ConsumerStatefulWidget {
  final bool autoStartTimer;
  final bool syncBackend;
  const LiveWorkoutScreen({
    super.key,
    this.autoStartTimer = false,
    this.syncBackend = true,
  });

  @override
  ConsumerState<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends ConsumerState<LiveWorkoutScreen> {
  late final LiveWorkoutNotifier _workoutNotifier;

  @override
  void initState() {
    super.initState();
    _workoutNotifier = ref.read(liveWorkoutProvider.notifier);
    if (widget.autoStartTimer) {
      Future.microtask(() => _workoutNotifier.startWorkoutSession());
    }
  }

  @override
  void dispose() {
    _workoutNotifier.cancelAllTimers();
    super.dispose();
  }

  String _formatElapsed(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _confirmEndWorkout() {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.border),
          ),
          title: Text('End Workout Session?', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700)),
          content: Text(
            'Your completed sets and total volume tonnage will be saved to your progress profile.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Resume', style: TextStyle(color: colors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                await ref.read(liveWorkoutProvider.notifier).completeWorkout();
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: colors.emerald,
                    content: const Text('Workout completed! Total volume tonnage recorded.'),
                  ),
                );
                navigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.destructive,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Finish Workout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveWorkoutProvider);
    final notifier = ref.read(liveWorkoutProvider.notifier);
    final currentExercise = state.currentExercise;
    final isLast = state.currentExerciseIndex == state.exercises.length - 1;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              state.sessionTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              _formatElapsed(state.elapsedSeconds),
              style: TextStyle(
                color: colors.emerald,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            key: const Key('appbar_video_demo_button'),
            icon: Icon(Icons.ondemand_video_rounded, color: colors.primary, size: 22),
            tooltip: 'Video Demonstration',
            onPressed: () {
              ExerciseVideoDemoSheet.show(context, currentExercise.exercise);
            },
          ),
          if (state.isStarted)
            IconButton(
              key: const Key('pause_resume_workout_button'),
              icon: Icon(
                state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: colors.primary,
                size: 22,
              ),
              tooltip: state.isPaused ? 'Resume Session' : 'Pause Session',
              onPressed: () => notifier.togglePlayPause(),
            ),
          TextButton(
            onPressed: _confirmEndWorkout,
            child: Text(
              'End',
              style: TextStyle(
                color: colors.destructive,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Scrollable Content
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session Ready Banner if not started yet
                  if (!state.isStarted) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.emerald.withAlpha(120), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: colors.emerald.withAlpha(25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors.emerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'WORKOUT ACTIVITY READY',
                                style: TextStyle(
                                  color: colors.emerald,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Begin Live Telemetry & Tracking',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start the session timer to track set completions, rest intervals, and volume tonnage.',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              key: const Key('start_workout_activity_button'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.emerald,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.heavyImpact();
                                notifier.startWorkoutSession();
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 22, color: Colors.white),
                              label: const Text(
                                'START ACTIVITY',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // PR Alert Banner if detected
                  if (state.recentPrBadge != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.amber, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amber.withAlpha(40),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: AppColors.amber, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.recentPrBadge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Exercise Horizontal Selector Bar
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.exercises.length,
                      itemBuilder: (context, index) {
                        final ex = state.exercises[index];
                        final isSelected = index == state.currentExerciseIndex;
                        final isAllSetsDone = ex.sets.every((s) => s.isCompleted);

                        return GestureDetector(
                          onTap: () => notifier.selectExercise(index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? colors.primary : colors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? colors.primary
                                    : (isAllSetsDone ? colors.emerald : colors.border),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (isAllSetsDone) ...[
                                  Icon(Icons.check, size: 13, color: colors.emerald),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  ex.exercise.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : colors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Current Exercise Hero Card
                  ExerciseHeroCard(
                    exerciseItem: currentExercise,
                    onWatchFormCue: () {
                      ExerciseVideoDemoSheet.show(context, currentExercise.exercise);
                    },
                  ),
                  const SizedBox(height: 18),

                  // Set Logging Table
                  SetLoggingTable(
                    sets: currentExercise.sets,
                    onLogSet: (setIndex, weight, reps) {
                      notifier.logSet(
                        exerciseIndex: state.currentExerciseIndex,
                        setIndex: setIndex,
                        weight: weight,
                        reps: reps,
                        syncToBackend: widget.syncBackend,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Floating Rest Timer HUD Overlay
            if (state.isRestTimerActive)
              Positioned(
                left: 0,
                right: 0,
                bottom: 96,
                child: RestTimerHud(
                  secondsRemaining: state.restSecondsRemaining,
                  totalSeconds: state.restSecondsTotal,
                  onAdd30s: () => notifier.addRestTime(30),
                  onSkip: () => notifier.skipRestTimer(),
                ),
              ),

            // Fixed Volume Tonnage Footer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VolumeTonnageFooter(
                totalVolumeKg: state.totalVolumeTonnage,
                completedSets: state.completedSetsAcrossAllExercises,
                totalSets: state.totalSetsAcrossAllExercises,
                isLastExercise: isLast,
                onNextOrFinish: () {
                  if (isLast) {
                    _confirmEndWorkout();
                  } else {
                    notifier.nextExercise();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
