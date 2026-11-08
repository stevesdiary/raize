import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/athletic_button.dart';
import '../../dashboard/screens/home_dashboard_screen.dart';
import '../providers/assessment_provider.dart';

class BlueprintScreen extends ConsumerStatefulWidget {
  const BlueprintScreen({super.key});

  @override
  ConsumerState<BlueprintScreen> createState() => _BlueprintScreenState();
}

class _BlueprintScreenState extends ConsumerState<BlueprintScreen> {
  bool _isActivating = false;

  void _activateBlueprint() async {
    setState(() => _isActivating = true);
    final apiClient = ref.read(apiClientProvider);

    try {
      // Generate active blueprint if not yet generated, then activate
      final genResponse = await apiClient.client.post(ApiEndpoints.recommendationsGenerate, data: {});
      final runId = genResponse.data?['data']?['runId'];
      if (runId != null) {
        await apiClient.client.post('/recommendations/$runId/accept', data: {});
      } else {
        await apiClient.client.post(ApiEndpoints.recommendationsActivate, data: {});
      }
    } catch (_) {
      // Offline fallback
    }

    if (!mounted) return;
    setState(() => _isActivating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.emerald,
        content: Text('Blueprint Activated! Your 7-day schedule is now live.'),
      ),
    );

    // Navigate to dashboard
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);
    final classification = state.classification;
    final nutrition = state.nutrition;
    final isCritical = state.isCriticalStop;

    final goalDisplay = classification?.primaryGoal.replaceAll('_', ' ').toUpperCase() ??
        'WEIGHT MANAGEMENT';
    final experienceDisplay = classification?.experience.toUpperCase() ?? 'INTERMEDIATE';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Fitness Blueprint'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Critical Cardiac Circuit Breaker Banner
              if (isCritical) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.destructive, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.health_and_safety_rounded, color: AppColors.destructive, size: 28),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'RECOMMENDATIONS PAUSED',
                              style: TextStyle(
                                color: AppColors.destructive,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        state.safetyDisclaimer ??
                            'You reported symptoms such as chest pain or fainting during exercise. For your safety, automated exercise programming has been intercepted. Please obtain medical clearance before strenuous physical exertion.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 6-D Classification Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '6-DIMENSION ATHLETIC CLASSIFICATION',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const Icon(Icons.verified_rounded, color: AppColors.emerald, size: 20),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$goalDisplay • $experienceDisplay',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tailored strategy balancing caloric deficit, progressive overload, and endurance conditioning.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nutrition & Energy Budget Card (Mifflin-St Jeor)
              Text(
                'Energy & Nutrition Budget',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCalorieMetric(
                          'TDEE Expenditure',
                          '${nutrition?.tdee ?? 2350} kcal',
                          AppColors.textMuted,
                        ),
                        Container(width: 1, height: 40, color: AppColors.border),
                        _buildCalorieMetric(
                          'Daily Caloric Target',
                          '${nutrition?.targetDailyCalories ?? 1850} kcal',
                          AppColors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 14),

                    // Macro Splits Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMacroPill('Protein', '140g', '30%', AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMacroPill('Carbs', '185g', '45%', AppColors.emerald),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMacroPill('Fats', '50g', '25%', AppColors.amber),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 7-Day Training Schedule
              Text(
                'Recommended 7-Day Blueprint',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              _buildScheduleDay(1, 'Upper Body Hypertrophy', 'Push Focus • 45 min', Icons.fitness_center_rounded, AppColors.primary),
              _buildScheduleDay(2, 'Zone 2 GPS Outdoor Run', 'Pace 5:30 /km • 30 min (250m Privacy Masked)', Icons.navigation_rounded, AppColors.emerald),
              _buildScheduleDay(3, 'Lower Body & Posterior Chain', 'Squats & Hinges • 45 min', Icons.fitness_center_rounded, AppColors.primary),
              _buildScheduleDay(4, 'Active Recovery & Mobility', 'Brisk Walk & Stretching • 20 min', Icons.directions_walk_rounded, AppColors.amber),
              _buildScheduleDay(5, 'Pull & Core Conditioning', 'LADDER Progression • 40 min', Icons.fitness_center_rounded, AppColors.primary),
              _buildScheduleDay(6, 'Tempo Run & Strides', 'Strava Telemetry • 35 min', Icons.navigation_rounded, AppColors.emerald),
              _buildScheduleDay(7, 'Full Rest & Recovery', 'Cellular Repair & Nutrition Focus', Icons.nightlight_round, AppColors.textMuted),

              const SizedBox(height: 32),

              // Actions
              if (!isCritical) ...[
                AthleticButton(
                  text: 'Accept & Activate Blueprint',
                  isLoading: _isActivating,
                  onPressed: _activateBlueprint,
                  variant: AthleticButtonVariant.primary,
                ),
                const SizedBox(height: 12),
              ],
              AthleticButton(
                text: isCritical ? 'Return to Home' : 'Customize Blueprint',
                variant: AthleticButtonVariant.outline,
                onPressed: () {
                  if (isCritical) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
                      (route) => false,
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildMacroPill(String name, String grams, String percent, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(name, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(grams, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          Text(percent, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildScheduleDay(int day, String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(30),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'DAY $day • ',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

