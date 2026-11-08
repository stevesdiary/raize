class Exercise {
  final String id;
  final String name;
  final String category;
  final String primaryMuscle;
  final String equipment;
  final String? videoUrl;
  final String? animation3dUrl;
  final String? animation3dUsdzUrl;
  final String? storageBucket;
  final int meshPolycount;
  final int rigBonesCount;
  final List<String> formCues;
  final List<String> secondaryMuscles;
  final List<String> commonMistakes;
  final String tempo;
  final String breathingCue;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.primaryMuscle,
    required this.equipment,
    this.videoUrl,
    this.animation3dUrl,
    this.animation3dUsdzUrl,
    this.storageBucket = 'raize-media',
    this.meshPolycount = 42500,
    this.rigBonesCount = 68,
    this.formCues = const [],
    this.secondaryMuscles = const [],
    this.commonMistakes = const [],
    this.tempo = '3-0-1-0',
    this.breathingCue = 'Inhale on descent, exhale on concentric drive',
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'strength',
      primaryMuscle: json['primaryMuscle'] as String? ?? 'chest',
      equipment: json['equipment'] as String? ?? 'barbell',
      videoUrl: json['videoUrl'] as String?,
      animation3dUrl: json['animation3dUrl'] as String? ?? json['animation3dGlbUrl'] as String?,
      animation3dUsdzUrl: json['animation3dUsdzUrl'] as String?,
      storageBucket: json['storageBucket'] as String? ?? 'raize-media',
      meshPolycount: json['meshPolycount'] as int? ?? 42500,
      rigBonesCount: json['rigBonesCount'] as int? ?? 68,
      formCues: (json['formCues'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      secondaryMuscles: (json['secondaryMuscles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      commonMistakes: (json['commonMistakes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tempo: json['tempo'] as String? ?? '3-0-1-0',
      breathingCue: json['breathingCue'] as String? ?? 'Inhale on descent, exhale on concentric drive',
    );
  }
}

class WorkoutSetItem {
  final int setOrder;
  final String setType; // warmup, normal, drop_set, failure
  final String previousBest;
  double weightKg;
  int reps;
  bool isCompleted;
  bool isPersonalRecord;
  int restSecondsAfter;

  WorkoutSetItem({
    required this.setOrder,
    this.setType = 'normal',
    this.previousBest = '80 kg x 10',
    required this.weightKg,
    required this.reps,
    this.isCompleted = false,
    this.isPersonalRecord = false,
    this.restSecondsAfter = 90,
  });

  double get volume => weightKg * reps;

  // Brzycki 1RM Estimation Formula: weight * (36 / (37 - reps))
  double get estimatedOneRepMax {
    if (reps <= 0 || weightKg <= 0) return 0;
    if (reps == 1) return weightKg;
    return weightKg * (36 / (37 - reps.clamp(1, 36)));
  }
}

class ExerciseSessionItem {
  final Exercise exercise;
  final String target;
  final List<WorkoutSetItem> sets;

  ExerciseSessionItem({
    required this.exercise,
    required this.target,
    required this.sets,
  });

  double get totalExerciseVolume {
    return sets
        .where((s) => s.isCompleted)
        .fold(0.0, (acc, s) => acc + s.volume);
  }

  int get completedSetsCount {
    return sets.where((s) => s.isCompleted).length;
  }
}

