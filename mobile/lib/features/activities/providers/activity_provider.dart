import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/activity_models.dart';

class ActivityNotifier extends Notifier<GpsRunSession> {
  Timer? _liveTimer;

  @override
  GpsRunSession build() {
    return const GpsRunSession();
  }

  void startRun() {
    state = state.copyWith(isStarted: true, isPaused: false);
    startLiveTick();
  }

  void startLiveTick() {
    state = state.copyWith(isStarted: true);
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPaused) return;
      state = state.copyWith(
        elapsedSeconds: state.elapsedSeconds + 1,
        movingSeconds: state.movingSeconds + 1,
        distanceKm: double.parse((state.distanceKm + 0.003).toStringAsFixed(2)),
        activeKcal: state.activeKcal + (timer.tick % 5 == 0 ? 1 : 0),
      );
    });
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void toggleScreenLock() {
    state = state.copyWith(isScreenLocked: !state.isScreenLocked);
  }

  void cancelTimers() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  Future<bool> completeSession({bool syncBackend = false}) async {
    cancelTimers();
    if (!syncBackend) return true;

    try {
      final dio = ref.read(apiClientProvider).client;
      final distanceMeters = (state.distanceKm * 1000).toInt();
      final payload = {
        'id': state.id,
        'activityId': state.id,
        'activityType': state.activityType,
        'distanceMeters': distanceMeters,
        'totalDistanceMeters': distanceMeters,
        'durationSeconds': state.movingSeconds,
        'movingDurationSeconds': state.movingSeconds,
        'totalElevationGainMeters': state.elevationGainMeters,
        'elevationGainMeters': state.elevationGainMeters,
        'averageHeartRate': state.heartRateBpm,
        'caloriesBurned': state.activeKcal,
        'averageCadence': state.cadenceSpm,
      };

      final response = await dio.post(ApiEndpoints.gpsComplete, data: payload);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

final activityProvider = NotifierProvider<ActivityNotifier, GpsRunSession>(ActivityNotifier.new);
