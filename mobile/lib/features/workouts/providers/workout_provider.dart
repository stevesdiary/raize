import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/workout_models.dart';

class LiveWorkoutState {
  final String sessionId;
  final String sessionTitle;
  final int elapsedSeconds;
  final int currentExerciseIndex;
  final List<ExerciseSessionItem> exercises;
  final bool isRestTimerActive;
  final int restSecondsRemaining;
  final int restSecondsTotal;
  final bool isCompleted;
  final double totalVolumeTonnage;
  final String? recentPrBadge;
  final bool isStarted;
  final bool isPaused;

  const LiveWorkoutState({
    required this.sessionId,
    required this.sessionTitle,
    this.elapsedSeconds = 0,
    this.currentExerciseIndex = 0,
    this.exercises = const [],
    this.isRestTimerActive = false,
    this.restSecondsRemaining = 0,
    this.restSecondsTotal = 90,
    this.isCompleted = false,
    this.totalVolumeTonnage = 0.0,
    this.recentPrBadge,
    this.isStarted = false,
    this.isPaused = false,
  });

  ExerciseSessionItem get currentExercise => exercises[currentExerciseIndex];

  int get totalSetsAcrossAllExercises {
    return exercises.fold(0, (acc, ex) => acc + ex.sets.length);
  }

  int get completedSetsAcrossAllExercises {
    return exercises.fold(0, (acc, ex) => acc + ex.completedSetsCount);
  }

  double calculateTotalVolume() {
    return exercises.fold(0.0, (acc, ex) => acc + ex.totalExerciseVolume);
  }

  LiveWorkoutState copyWith({
    String? sessionId,
    String? sessionTitle,
    int? elapsedSeconds,
    int? currentExerciseIndex,
    List<ExerciseSessionItem>? exercises,
    bool? isRestTimerActive,
    int? restSecondsRemaining,
    int? restSecondsTotal,
    bool? isCompleted,
    double? totalVolumeTonnage,
    String? recentPrBadge,
    bool? isStarted,
    bool? isPaused,
  }) {
    return LiveWorkoutState(
      sessionId: sessionId ?? this.sessionId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      exercises: exercises ?? this.exercises,
      isRestTimerActive: isRestTimerActive ?? this.isRestTimerActive,
      restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
      restSecondsTotal: restSecondsTotal ?? this.restSecondsTotal,
      isCompleted: isCompleted ?? this.isCompleted,
      totalVolumeTonnage: totalVolumeTonnage ?? this.totalVolumeTonnage,
      recentPrBadge: recentPrBadge ?? this.recentPrBadge,
      isStarted: isStarted ?? this.isStarted,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

final liveWorkoutProvider =
    NotifierProvider<LiveWorkoutNotifier, LiveWorkoutState>(LiveWorkoutNotifier.new);

class LiveWorkoutNotifier extends Notifier<LiveWorkoutState> {
  Timer? _sessionTimer;
  Timer? _restCountdownTimer;

  @override
  LiveWorkoutState build() {
    final defaultExercises = _buildDefaultSessionExercises();
    return LiveWorkoutState(
      sessionId: 'session_live_01',
      sessionTitle: 'Push Hypertrophy A',
      exercises: defaultExercises,
      totalVolumeTonnage: 0.0,
      isStarted: false,
      isPaused: false,
    );
  }

  void startWorkoutSession() {
    _sessionTimer?.cancel();
    state = state.copyWith(isStarted: true, isPaused: false);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void pauseWorkoutSession() {
    _sessionTimer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resumeWorkoutSession() {
    startWorkoutSession();
  }

  void togglePlayPause() {
    if (state.isPaused) {
      resumeWorkoutSession();
    } else {
      pauseWorkoutSession();
    }
  }

  void cancelAllTimers() {
    _sessionTimer?.cancel();
    _restCountdownTimer?.cancel();
  }

  void pauseSessionTimer() {
    pauseWorkoutSession();
  }

  void logSet({
    required int exerciseIndex,
    required int setIndex,
    required double weight,
    required int reps,
    bool syncToBackend = false,
  }) {
    final updatedExercises = List<ExerciseSessionItem>.from(state.exercises);
    final exerciseItem = updatedExercises[exerciseIndex];
    final updatedSets = List<WorkoutSetItem>.from(exerciseItem.sets);

    final currentSet = updatedSets[setIndex];
    currentSet.weightKg = weight;
    currentSet.reps = reps;
    currentSet.isCompleted = true;

    // Detect PR (e.g. if weight > 80kg on Bench)
    String? prNotice;
    if (weight > 80.0) {
      currentSet.isPersonalRecord = true;
      prNotice = '🏆 New 1RM: ${(weight * (36 / (37 - reps.clamp(1, 36)))).toStringAsFixed(1)} kg!';
    }

    updatedExercises[exerciseIndex] = ExerciseSessionItem(
      exercise: exerciseItem.exercise,
      target: exerciseItem.target,
      sets: updatedSets,
    );

    // Compute updated total volume tonnage
    final totalVolume = updatedExercises.fold(0.0, (acc, ex) => acc + ex.totalExerciseVolume);

    state = state.copyWith(
      exercises: updatedExercises,
      totalVolumeTonnage: totalVolume,
      recentPrBadge: prNotice,
    );

    // Auto-trigger Rest Timer
    startRestTimer(currentSet.restSecondsAfter);

    // Sync set with backend if enabled
    if (syncToBackend) {
      final apiClient = ref.read(apiClientProvider);
      try {
        apiClient.client.post(
          '/workouts/sessions/${state.sessionId}/sets',
          data: {
            'exerciseId': exerciseItem.exercise.id,
            'setOrder': currentSet.setOrder,
            'setType': currentSet.setType,
            'reps': reps,
            'weightKg': weight,
            'restSecondsAfter': currentSet.restSecondsAfter,
          },
        ).then((res) {
          if (res.data is Map && res.data['data']?['sessionId'] != null) {
            state = state.copyWith(sessionId: res.data['data']['sessionId'] as String);
          }
        });
      } catch (_) {}
    }
  }

  void startRestTimer(int seconds) {
    _restCountdownTimer?.cancel();
    state = state.copyWith(
      isRestTimerActive: true,
      restSecondsTotal: seconds,
      restSecondsRemaining: seconds,
    );

    _restCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.restSecondsRemaining > 1) {
        state = state.copyWith(restSecondsRemaining: state.restSecondsRemaining - 1);
      } else {
        skipRestTimer();
      }
    });
  }

  void addRestTime(int seconds) {
    state = state.copyWith(
      restSecondsRemaining: state.restSecondsRemaining + seconds,
      restSecondsTotal: state.restSecondsTotal + seconds,
    );
  }

  void skipRestTimer() {
    _restCountdownTimer?.cancel();
    state = state.copyWith(
      isRestTimerActive: false,
      restSecondsRemaining: 0,
    );
  }

  void selectExercise(int index) {
    if (index >= 0 && index < state.exercises.length) {
      state = state.copyWith(currentExerciseIndex: index);
    }
  }

  void nextExercise() {
    if (state.currentExerciseIndex < state.exercises.length - 1) {
      state = state.copyWith(currentExerciseIndex: state.currentExerciseIndex + 1);
    }
  }

  Future<void> completeWorkout() async {
    _sessionTimer?.cancel();
    _restCountdownTimer?.cancel();

    state = state.copyWith(isCompleted: true);

    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.client.post(
        '/workouts/sessions/${state.sessionId}/complete',
        data: {
          'durationSeconds': state.elapsedSeconds,
        },
      );
    } catch (_) {}
  }

  static List<ExerciseSessionItem> _buildDefaultSessionExercises() {
    return [
      ExerciseSessionItem(
        exercise: const Exercise(
          id: 'ex_bench_press',
          name: 'Barbell Bench Press',
          category: 'strength',
          primaryMuscle: 'Chest',
          equipment: 'Barbell',
          videoUrl: 'https://media.raize.fit/exercises/video/barbell-bench-press-4k.mp4',
          animation3dUrl: 'https://media.raize.fit/exercises/3d/barbell-bench-press-human-3d.glb',
          animation3dUsdzUrl: 'https://media.raize.fit/exercises/3d/barbell-bench-press-human-3d.usdz',
          storageBucket: 'raize-media',
          meshPolycount: 42500,
          rigBonesCount: 68,
          secondaryMuscles: ['Triceps Brachii', 'Anterior Deltoids'],
          formCues: [
            'Retract scapulae and arch upper back slightly',
            'Plant feet flat and drive through the floor',
            'Lower bar under control to mid-chest sternum',
            'Press upward along a slight J-curve bar path',
          ],
          commonMistakes: [
            'Flaring elbows past 75° (causes subacromial impingement)',
            'Bouncing the barbell off the ribcage or sternum',
            'Lifting glutes or hips off the bench surface',
          ],
          tempo: '3-1-1-0 (3s Descent • 1s Pause • 1s Drive)',
          breathingCue: 'Deep diaphragmatic inhale & brace core on descent; exhale forcefully past the sticking point.',
        ),
        target: '4 Sets • 8-10 Reps • RPE 8',
        sets: [
          WorkoutSetItem(setOrder: 1, setType: 'warmup', previousBest: '60 kg x 12', weightKg: 60.0, reps: 12),
          WorkoutSetItem(setOrder: 2, setType: 'normal', previousBest: '80 kg x 10', weightKg: 82.5, reps: 10),
          WorkoutSetItem(setOrder: 3, setType: 'normal', previousBest: '80 kg x 8', weightKg: 82.5, reps: 8),
          WorkoutSetItem(setOrder: 4, setType: 'normal', previousBest: '82.5 kg x 6', weightKg: 85.0, reps: 6),
        ],
      ),
      ExerciseSessionItem(
        exercise: const Exercise(
          id: 'ex_incline_db',
          name: 'Incline Dumbbell Press',
          category: 'strength',
          primaryMuscle: 'Clavicular Upper Chest',
          equipment: 'Dumbbells',
          videoUrl: 'https://media.raize.fit/exercises/video/incline-dumbbell-press-4k.mp4',
          animation3dUrl: 'https://media.raize.fit/exercises/3d/incline-dumbbell-press-human-3d.glb',
          animation3dUsdzUrl: 'https://media.raize.fit/exercises/3d/incline-dumbbell-press-human-3d.usdz',
          storageBucket: 'raize-media',
          meshPolycount: 38200,
          rigBonesCount: 68,
          secondaryMuscles: ['Anterior Deltoids', 'Triceps'],
          formCues: [
            'Set bench angle to 30 degrees for clavicular fiber orientation',
            'Tuck elbows at 45 degrees relative to torso',
            'Drive bells upward until arms reach 95% extension',
          ],
          commonMistakes: [
            'Excessive bench incline (>45°) shifting load to front deltoids',
            'Clanging dumbbells together at the top (loses tension)',
          ],
          tempo: '3-0-1-0 (3s Controlled Eccentric)',
          breathingCue: 'Inhale on the wide stretch; exhale on vertical press.',
        ),
        target: '3 Sets • 10-12 Reps • RPE 8',
        sets: [
          WorkoutSetItem(setOrder: 1, setType: 'normal', previousBest: '26 kg x 12', weightKg: 28.0, reps: 12),
          WorkoutSetItem(setOrder: 2, setType: 'normal', previousBest: '28 kg x 10', weightKg: 28.0, reps: 10),
          WorkoutSetItem(setOrder: 3, setType: 'normal', previousBest: '28 kg x 8', weightKg: 30.0, reps: 8),
        ],
      ),
      ExerciseSessionItem(
        exercise: const Exercise(
          id: 'ex_dips',
          name: 'Chest Dips',
          category: 'strength',
          primaryMuscle: 'Lower Chest & Triceps',
          equipment: 'Dip Station',
          videoUrl: 'https://media.raize.fit/exercises/video/chest-dips-4k.mp4',
          animation3dUrl: 'https://media.raize.fit/exercises/3d/chest-dips-human-3d.glb',
          animation3dUsdzUrl: 'https://media.raize.fit/exercises/3d/chest-dips-human-3d.usdz',
          storageBucket: 'raize-media',
          meshPolycount: 36400,
          rigBonesCount: 68,
          secondaryMuscles: ['Anterior Deltoids', 'Core Stabilizers'],
          formCues: [
            'Lean torso forward 15-20 degrees for lower sternal pectoralis focus',
            'Lower body until elbows achieve 90 degree flexion',
            'Press up smoothly through palms without shrugging shoulders',
          ],
          commonMistakes: [
            'Remaining upright (shifts entire load to triceps instead of chest)',
            'Going excessively deep beyond shoulder joint mobility',
          ],
          tempo: '2-1-1-0 Tempo',
          breathingCue: 'Inhale during descent; exhale as you press to lockout.',
        ),
        target: '3 Sets • Bodyweight to Failure',
        sets: [
          WorkoutSetItem(setOrder: 1, setType: 'normal', previousBest: 'BW x 15', weightKg: 0.0, reps: 15),
          WorkoutSetItem(setOrder: 2, setType: 'normal', previousBest: 'BW x 12', weightKg: 0.0, reps: 12),
          WorkoutSetItem(setOrder: 3, setType: 'failure', previousBest: 'BW x 10', weightKg: 0.0, reps: 10),
        ],
      ),
      ExerciseSessionItem(
        exercise: const Exercise(
          id: 'ex_cable_lateral_raise',
          name: 'Cable Lateral Raise',
          category: 'hypertrophy',
          primaryMuscle: 'Lateral Deltoid',
          equipment: 'Cable Machine',
          videoUrl: 'https://media.raize.fit/exercises/video/cable-lateral-raise-4k.mp4',
          animation3dUrl: 'https://media.raize.fit/exercises/3d/cable-lateral-raise-human-3d.glb',
          animation3dUsdzUrl: 'https://media.raize.fit/exercises/3d/cable-lateral-raise-human-3d.usdz',
          storageBucket: 'raize-media',
          meshPolycount: 39800,
          rigBonesCount: 68,
          secondaryMuscles: ['Supraspinatus', 'Trapezius'],
          formCues: [
            'Set cable pulley at wrist or mid-shin height',
            'Lead with the elbow, keeping wrist neutral',
            'Raise to parallel with floor; pause for peak contraction',
          ],
          commonMistakes: [
            'Using torso momentum or swinging',
            'Shrugging upper traps to raise the handle',
          ],
          tempo: '2-1-1-1 (1s Pause at Contraction Peak)',
          breathingCue: 'Exhale smoothly on lateral raise; inhale on descent.',
        ),
        target: '4 Sets • 12-15 Reps',
        sets: [
          WorkoutSetItem(setOrder: 1, setType: 'normal', previousBest: '10 kg x 15', weightKg: 10.0, reps: 15),
          WorkoutSetItem(setOrder: 2, setType: 'normal', previousBest: '12.5 kg x 12', weightKg: 12.5, reps: 12),
          WorkoutSetItem(setOrder: 3, setType: 'normal', previousBest: '12.5 kg x 12', weightKg: 12.5, reps: 12),
          WorkoutSetItem(setOrder: 4, setType: 'drop_set', previousBest: '12.5 kg x 10', weightKg: 12.5, reps: 10),
        ],
      ),
    ];
  }
}
