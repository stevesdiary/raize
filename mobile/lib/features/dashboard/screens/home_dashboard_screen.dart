import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/today_workout_card.dart';
import '../widgets/step_streak_card.dart';
import '../widgets/calorie_ring_card.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/frosted_bottom_nav.dart';
import '../../workouts/screens/live_workout_screen.dart';
import '../../activities/screens/live_gps_run_screen.dart';
import '../../nutrition/screens/nutrition_diary_screen.dart';
import '../../profile/screens/account_settings_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/onboarding_screen.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  final bool autoFetch;
  const HomeDashboardScreen({super.key, this.autoFetch = true});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.autoFetch) {
      Future.microtask(() => ref.read(dashboardProvider.notifier).fetchDashboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final summary = state.summary;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Scrollable Content Area
            RefreshIndicator(
              color: colors.primary,
              backgroundColor: colors.card,
              onRefresh: () async {
                await ref.read(dashboardProvider.notifier).fetchDashboard();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Telemetry Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.primary.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  summary.classificationBadge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  summary.greeting,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Streak Pill, Theme Switcher & Profile Avatar
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.amber.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: colors.amber.withAlpha(60)),
                              ),
                              child: Row(
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${summary.streakDays}d',
                                    style: TextStyle(
                                      color: colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const ThemeToggleButton(size: 36),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final authState = ref.read(authProvider);
                                final user = authState.user;
                                final handle = user?.displayHandle ?? '@athlete';
                                final userEmail = user?.email ?? 'athlete@raize.fit';
                                final shouldLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: colors.cardElevated,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: colors.border),
                                    ),
                                    title: Text(
                                      'Athlete Profile',
                                      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Signed in as $handle\nEmail: $userEmail\nLeaderboard handle: $handle',
                                          style: TextStyle(color: colors.textSecondary, height: 1.4),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'App Appearance Theme',
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const ThemeModeSegmentedSelector(),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            key: const Key('dialog_account_settings_button'),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              side: BorderSide(color: colors.primary.withAlpha(80)),
                                            ),
                                            onPressed: () {
                                              Navigator.of(ctx).pop(false);
                                              Navigator.of(context).push(
                                                MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                                              );
                                            },
                                            icon: Icon(Icons.manage_accounts_rounded, size: 18, color: colors.primary),
                                            label: Text(
                                              'Account Settings',
                                              style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'Would you like to sign out?',
                                          style: TextStyle(color: colors.textMuted, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: Text('Sign Out', style: TextStyle(color: colors.destructive, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldLogout == true && context.mounted) {
                                  await ref.read(authProvider.notifier).logout();
                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                                      (route) => false,
                                    );
                                  }
                                }
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.cardElevated,
                                  border: Border.all(color: colors.border),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: colors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Today's Scheduled Workout (Hero Card)
                    TodayWorkoutCard(
                      workout: summary.todayWorkout,
                      onStart: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LiveWorkoutScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Daily Step Count & Streak Telemetry Card
                    StepStreakCard(
                      steps: summary.steps,
                      streakDays: summary.streakDays,
                    ),
                    const SizedBox(height: 20),

                    // Nutrition & Energy Equation Card
                    CalorieRingCard(nutrition: summary.nutrition),
                    const SizedBox(height: 20),

                    // Quick Actions Bar
                    QuickActionsBar(
                      onStartGpsRun: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LiveGpsRunScreen(autoStartTimer: false),
                          ),
                        );
                      },
                      onLogMeal: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NutritionDiaryScreen(),
                          ),
                        );
                      },
                      onLogWorkout: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LiveWorkoutScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Weekly Consistency Heatmap
                    Text(
                      'Weekly Consistency Heatmap',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDayDot('M', true, colors.primary),
                          _buildDayDot('T', true, colors.emerald),
                          _buildDayDot('W', true, colors.primary),
                          _buildDayDot('T', false, colors.border),
                          _buildDayDot('F', true, colors.primary),
                          _buildDayDot('S', true, colors.emerald),
                          _buildDayDot('S', false, colors.border),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recent Activity History Feed
                    Text(
                      'Recent Completed Telemetry',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 10),
                    _buildActivityTile(
                      title: 'Morning Tempo Run',
                      subtitle: '5.42 km • 28:14 (5:12 /km) • 250m Masked',
                      icon: Icons.navigation_rounded,
                      color: colors.emerald,
                      timeAgo: 'Today 7:15 AM',
                    ),
                    _buildActivityTile(
                      title: 'Push Hypertrophy A',
                      subtitle: '4 exercises • 3,840 kg volume • 1 PR Set',
                      icon: Icons.fitness_center_rounded,
                      color: colors.primary,
                      timeAgo: 'Yesterday 6:00 PM',
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Frosted Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FrostedBottomNav(
                currentIndex: state.selectedNavIndex,
                onTabSelected: (index) async {
                  if (index == 0) {
                    ref.read(dashboardProvider.notifier).setNavIndex(0);
                    return;
                  }
                  ref.read(dashboardProvider.notifier).setNavIndex(index);
                  if (index == 1) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LiveWorkoutScreen()),
                    );
                  } else if (index == 2) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LiveGpsRunScreen(autoStartTimer: false),
                      ),
                    );
                  } else if (index == 3) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NutritionDiaryScreen()),
                    );
                  } else if (index == 4) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  }
                  if (context.mounted) {
                    ref.read(dashboardProvider.notifier).setNavIndex(0);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDot(String day, bool isDone, Color color) {
    final colors = context.colors;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? color : colors.cardElevated,
            border: Border.all(color: isDone ? color : colors.borderSubtle),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            color: isDone ? colors.textPrimary : colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String timeAgo,
  }) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(25),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
