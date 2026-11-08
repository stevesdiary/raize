import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dashboard_model.dart';

class DashboardState {
  final bool isLoading;
  final DashboardSummary summary;
  final String? errorMessage;
  final int selectedNavIndex;

  const DashboardState({
    this.isLoading = false,
    required this.summary,
    this.errorMessage,
    this.selectedNavIndex = 0,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardSummary? summary,
    String? errorMessage,
    int? selectedNavIndex,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedNavIndex: selectedNavIndex ?? this.selectedNavIndex,
    );
  }
}

final dashboardProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    final fallback = DashboardSummary(
      greeting: 'Good morning, Athlete!',
      primaryGoal: 'weight_management',
      classificationBadge: 'INTERMEDIATE • WEIGHT MANAGEMENT',
      todayWorkout: const DashboardWorkout(
        id: 'w_today_1',
        title: 'Push Hypertrophy A',
        status: 'scheduled',
        isCompleted: false,
        durationMinutes: 45,
        exerciseCount: 5,
      ),
      nutrition: const DashboardNutrition(
        consumedCalories: 1240,
        targetCalories: 1920,
        remainingCalories: 680,
        proteinGrams: 110,
        targetProteinGrams: 140,
        carbsGrams: 145,
        targetCarbsGrams: 185,
        fatGrams: 38,
        targetFatGrams: 50,
      ),
      streakDays: 14,
    );

    return DashboardState(summary: fallback);
  }

  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true);
    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.client.get('/dashboard/daily-summary');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final summary = DashboardSummary.fromJson(response.data['data']);
        state = state.copyWith(summary: summary, isLoading: false);
        return;
      }
    } catch (_) {
      // Offline fallback: retains fallback summary smoothly
    }

    state = state.copyWith(isLoading: false);
  }

  void setNavIndex(int index) {
    state = state.copyWith(selectedNavIndex: index);
  }
}

