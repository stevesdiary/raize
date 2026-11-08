class GpsPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double heading;
  final DateTime timestamp;

  const GpsPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'speed': speed,
    'heading': heading,
    'timestamp': timestamp.toIso8601String(),
  };

  factory GpsPoint.fromJson(Map<String, dynamic> json) => GpsPoint(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    altitude: (json['altitude'] as num).toDouble(),
    speed: (json['speed'] as num).toDouble(),
    heading: (json['heading'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class GpsRunSession {
  final String id;
  final String activityType; // 'outdoor_run', 'trail_run', 'cycling'
  final double distanceKm;
  final double targetDistanceKm;
  final int elapsedSeconds;
  final int movingSeconds;
  final int currentPaceSeconds; // seconds per km
  final int avgPaceSeconds;
  final int heartRateBpm;
  final int heartRateZone; // 1 to 5
  final int activeKcal;
  final double effortScore;
  final int cadenceSpm;
  final int elevationGainMeters;
  final double gradePercent;
  final int headingDegrees;
  final String headingCardinal;
  final bool isGpsLocked;
  final bool isKalmanFiltered;
  final bool isPrivacyMaskActive;
  final bool isStarted;
  final bool isPaused;
  final bool isScreenLocked;
  final String currentSplitPace;
  final int fastestSplitKm;
  final String projected10kTime;
  final String segmentNotice;

  const GpsRunSession({
    this.id = 'gps_live_01',
    this.activityType = 'outdoor_run',
    this.distanceKm = 5.42,
    this.targetDistanceKm = 10.0,
    this.elapsedSeconds = 1724, // 28:44
    this.movingSeconds = 1692,  // 28:12
    this.currentPaceSeconds = 318, // 5:18 /km
    this.avgPaceSeconds = 322,     // 5:22 /km
    this.heartRateBpm = 154,
    this.heartRateZone = 4,
    this.activeKcal = 382,
    this.effortScore = 8.4,
    this.cadenceSpm = 168,
    this.elevationGainMeters = 42,
    this.gradePercent = 2.1,
    this.headingDegrees = 312,
    this.headingCardinal = 'NW',
    this.isGpsLocked = true,
    this.isKalmanFiltered = true,
    this.isPrivacyMaskActive = true,
    this.isStarted = false,
    this.isPaused = false,
    this.isScreenLocked = false,
    this.currentSplitPace = '5:12 /km',
    this.fastestSplitKm = 5,
    this.projected10kTime = '53:20',
    this.segmentNotice = 'EMERALD LOOP • 1.2 KM REMAINING',
  });

  String get formattedDuration {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get formattedMovingDuration {
    final m = movingSeconds ~/ 60;
    final s = movingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get formattedPace {
    final m = currentPaceSeconds ~/ 60;
    final s = currentPaceSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  double get progressRatio =>
      (distanceKm / (targetDistanceKm <= 0 ? 1 : targetDistanceKm)).clamp(0.0, 1.0);

  double get progressPercentage => (progressRatio * 100);

  GpsRunSession copyWith({
    String? id,
    String? activityType,
    double? distanceKm,
    double? targetDistanceKm,
    int? elapsedSeconds,
    int? movingSeconds,
    int? currentPaceSeconds,
    int? avgPaceSeconds,
    int? heartRateBpm,
    int? heartRateZone,
    int? activeKcal,
    double? effortScore,
    int? cadenceSpm,
    int? elevationGainMeters,
    double? gradePercent,
    int? headingDegrees,
    String? headingCardinal,
    bool? isGpsLocked,
    bool? isKalmanFiltered,
    bool? isPrivacyMaskActive,
    bool? isStarted,
    bool? isPaused,
    bool? isScreenLocked,
    String? currentSplitPace,
    int? fastestSplitKm,
    String? projected10kTime,
    String? segmentNotice,
  }) {
    return GpsRunSession(
      id: id ?? this.id,
      activityType: activityType ?? this.activityType,
      distanceKm: distanceKm ?? this.distanceKm,
      targetDistanceKm: targetDistanceKm ?? this.targetDistanceKm,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      movingSeconds: movingSeconds ?? this.movingSeconds,
      currentPaceSeconds: currentPaceSeconds ?? this.currentPaceSeconds,
      avgPaceSeconds: avgPaceSeconds ?? this.avgPaceSeconds,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      heartRateZone: heartRateZone ?? this.heartRateZone,
      activeKcal: activeKcal ?? this.activeKcal,
      effortScore: effortScore ?? this.effortScore,
      cadenceSpm: cadenceSpm ?? this.cadenceSpm,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      gradePercent: gradePercent ?? this.gradePercent,
      headingDegrees: headingDegrees ?? this.headingDegrees,
      headingCardinal: headingCardinal ?? this.headingCardinal,
      isGpsLocked: isGpsLocked ?? this.isGpsLocked,
      isKalmanFiltered: isKalmanFiltered ?? this.isKalmanFiltered,
      isPrivacyMaskActive: isPrivacyMaskActive ?? this.isPrivacyMaskActive,
      isStarted: isStarted ?? this.isStarted,
      isPaused: isPaused ?? this.isPaused,
      isScreenLocked: isScreenLocked ?? this.isScreenLocked,
      currentSplitPace: currentSplitPace ?? this.currentSplitPace,
      fastestSplitKm: fastestSplitKm ?? this.fastestSplitKm,
      projected10kTime: projected10kTime ?? this.projected10kTime,
      segmentNotice: segmentNotice ?? this.segmentNotice,
    );
  }
}

