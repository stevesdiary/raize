import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/screens/home_dashboard_screen.dart';
import '../models/nutrition_models.dart';
import '../providers/nutrition_provider.dart';

class NutritionDiaryScreen extends ConsumerStatefulWidget {
  final bool syncBackend;

  const NutritionDiaryScreen({
    super.key,
    this.syncBackend = false,
  });

  @override
  ConsumerState<NutritionDiaryScreen> createState() => _NutritionDiaryScreenState();
}

class _NutritionDiaryScreenState extends ConsumerState<NutritionDiaryScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(nutritionProvider).searchQuery;
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nutritionProvider);
    final notifier = ref.read(nutritionProvider.notifier);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Ambient Cyber Glows
          Positioned(
            top: -20,
            left: MediaQuery.of(context).size.width / 4,
            child: Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.kineticIndigo.withValues(alpha: colors.isDark ? 0.12 : 0.05),
              ),
            ),
          ),
          Positioned(
            top: 250,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.neonEmerald.withValues(alpha: colors.isDark ? 0.08 : 0.03),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Sticky Header
                _buildHeader(state),

                // Main Scrollable Canvas
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Daily Energy Budget Card (Bento Telemetry)
                        _buildEnergyBudgetCard(state, notifier),
                        const SizedBox(height: 16),

                        // 2. Meal Schedule Section
                        _buildMealScheduleSection(state, notifier),
                        const SizedBox(height: 20),

                        // 3. Rapid Food Logger Section
                        _buildRapidFoodLoggerSection(state, notifier),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(DailyNutritionState state) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: colors.border,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Return / Back Navigation Button
                  Tooltip(
                    message: 'Back to Dashboard',
                    child: InkWell(
                      key: const Key('nutrition_back_button'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const HomeDashboardScreen(),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.cardElevated,
                          border: Border.all(
                            color: colors.border,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.neonEmerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RAIZE NUTRITION OS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.neonEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.mode.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: colors.neonEmerald,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Date Switcher Pill & Tools
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.cardElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chevron_left, size: 20, color: colors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      state.dateLabel,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        _Dot(colors.neonEmerald),
                        _Dot(colors.neonEmerald),
                        _Dot(colors.neonEmerald),
                        _Dot(colors.kineticIndigo),
                        _Dot(colors.outlineVariant),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, size: 20, color: colors.textSecondary),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildHeaderToolButton(Icons.calendar_today_outlined),
                  const SizedBox(width: 6),
                  _buildHeaderToolButton(Icons.tune),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderToolButton(IconData icon) {
    final colors = context.colors;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.cardElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Icon(icon, size: 18, color: colors.textSecondary),
    );
  }

  Widget _buildEnergyBudgetCard(DailyNutritionState state, NutritionNotifier notifier) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ENERGY EXPENDITURE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: colors.border,
                          ),
                        ),
                        child: Text(
                          'Mifflin-St Jeor',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${state.consumedCalories}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ ${state.targetCalories} kcal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Adherence Radial Mini Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          value: state.calorieProgressRatio,
                          strokeWidth: 4,
                          backgroundColor: colors.surfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.neonEmerald),
                        ),
                      ),
                      Text(
                        '${state.caloriePercentage}%',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.neonEmerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.remainingCalories} kcal left',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colors.neonEmerald,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Telemetry Progress Segment Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(flex: 41, child: Container(height: 6, color: colors.neonEmerald)),
                Expanded(flex: 38, child: Container(height: 6, color: colors.kineticIndigo)),
                Expanded(flex: 21, child: Container(height: 6, color: colors.amberFlame)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Macro Breakdown Triple Metric Cluster
          Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  title: 'PROTEIN',
                  current: state.proteinConsumed.toInt(),
                  target: state.proteinTarget.toInt(),
                  color: colors.neonEmerald,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroCard(
                  title: 'CARBS',
                  current: state.carbsConsumed.toInt(),
                  target: state.carbsTarget.toInt(),
                  color: colors.kineticIndigo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroCard(
                  title: 'FAT',
                  current: state.fatConsumed.toInt(),
                  target: state.fatTarget.toInt(),
                  color: colors.amberFlame,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Micro Hydration Quick-Log Row
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colors.border,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.water_drop, size: 18, color: colors.kineticIndigo),
                    const SizedBox(width: 6),
                    Text(
                      'Hydration',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${state.hydrationLiters.toStringAsFixed(1)}L / ${state.hydrationTargetLiters.toStringAsFixed(1)}L',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => notifier.addHydration(0.25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '+ 250ml',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colors.kineticIndigo,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.add, size: 12, color: colors.kineticIndigo),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard({
    required String title,
    required int current,
    required int target,
    required Color color,
  }) {
    final colors = context.colors;
    final ratio = (current / (target <= 0 ? 1 : target)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.cardElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$current',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '/${target}g',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              backgroundColor: colors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealScheduleSection(DailyNutritionState state, NutritionNotifier notifier) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Meal Schedule',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              '${state.loggedMealsCount} OF ${state.meals.length} LOGGED',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Meal Cards
        ...state.meals.map((meal) => _buildMealSlotCard(meal, notifier)),
      ],
    );
  }

  Widget _buildMealSlotCard(MealSlot meal, NutritionNotifier notifier) {
    final colors = context.colors;

    if (meal.id == 'dinner' && !meal.isLogged) {
      // Focus state for Dinner
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.kineticIndigo.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.kineticIndigo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        meal.targetTime,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colors.kineticIndigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      meal.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '~${meal.calories} kcal budget',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.kineticIndigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              meal.description ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.kineticIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final catalogFood = ref.read(nutritionProvider).catalogFoods.first;
                      final portionIdx = ref.read(nutritionProvider).selectedPortions[catalogFood.id] ?? 0;
                      notifier.logFoodToMeal(
                        mealId: 'dinner',
                        food: catalogFood,
                        portionIndex: portionIdx,
                        syncBackend: widget.syncBackend,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '+ Log Food to Dinner',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.border,
                    ),
                  ),
                  child: Icon(Icons.qr_code_scanner, size: 18, color: colors.textPrimary),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      meal.targetTime,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    meal.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${meal.calories}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: meal.isLogged ? colors.neonEmerald : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'kcal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (meal.description != null) ...[
            const SizedBox(height: 6),
            Text(
              meal.description!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
          if (meal.portionNote != null) ...[
            const SizedBox(height: 2),
            Text(
              meal.portionNote!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: colors.textSecondary,
              ),
            ),
          ],
          if (meal.isLogged) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMealMacroPill('P', meal.proteinGrams.toInt(), colors.neonEmerald),
                const SizedBox(width: 6),
                _buildMealMacroPill('C', meal.carbsGrams.toInt(), colors.kineticIndigo),
                const SizedBox(width: 6),
                _buildMealMacroPill('F', meal.fatGrams.toInt(), colors.amberFlame),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealMacroPill(String label, int grams, Color color) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ${grams}g',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRapidFoodLoggerSection(DailyNutritionState state, NutritionNotifier notifier) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, size: 18, color: colors.neonEmerald),
                const SizedBox(width: 6),
                Text(
                  'RAPID FOOD LOGGER',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.neonEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.neonEmerald.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Nigerian Staples v2.4',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: colors.neonEmerald,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Search bar
        TextField(
          controller: _searchController,
          onChanged: notifier.setSearchQuery,
          style: GoogleFonts.plusJakartaSans(color: colors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search food or scan barcode...',
            hintStyle: GoogleFonts.plusJakartaSans(color: colors.textMuted, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: colors.textMuted, size: 20),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner, color: colors.textMuted, size: 18),
                const SizedBox(width: 8),
                Icon(Icons.mic_none, color: colors.textMuted, size: 18),
                const SizedBox(width: 8),
              ],
            ),
            filled: true,
            fillColor: colors.card,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.kineticIndigo.withValues(alpha: 0.4),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.kineticIndigo),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Category Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryPill('Recent', state.activeCategory == 'Recent', notifier),
              const SizedBox(width: 6),
              _buildCategoryPill(
                'Nigerian Staples 🇳🇬',
                state.activeCategory == 'Nigerian Staples 🇳🇬',
                notifier,
              ),
              const SizedBox(width: 6),
              _buildCategoryPill(
                'Custom Recipes',
                state.activeCategory == 'Custom Recipes',
                notifier,
              ),
              const SizedBox(width: 6),
              _buildCategoryPill('Favorites', state.activeCategory == 'Favorites', notifier),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Nigerian Portion Conversion Food Items
        ...state.catalogFoods.map((food) => _buildFoodItemCard(food, state, notifier)),
        const SizedBox(height: 14),

        // Sticky Quick Log CTA
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.kineticIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final firstFood = state.catalogFoods.first;
              final selectedPortion = state.selectedPortions[firstFood.id] ?? 0;
              notifier.logFoodToMeal(
                mealId: 'dinner',
                food: firstFood,
                portionIndex: selectedPortion,
                syncBackend: widget.syncBackend,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to Dinner!')),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_task, size: 18),
                const SizedBox(width: 8),
                Text(
                  '+ Add to Dinner (590 kcal)',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPill(String title, bool isSelected, NutritionNotifier notifier) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => notifier.setCategory(title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.kineticIndigo.withValues(alpha: 0.15)
              : colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.kineticIndigo
                : colors.border,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? colors.kineticIndigo : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItemCard(
    FoodItem food,
    DailyNutritionState state,
    NutritionNotifier notifier,
  ) {
    final colors = context.colors;
    final selectedIdx = state.selectedPortions[food.id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedIdx == 0 && food.id == 'food_pounded_yam'
              ? colors.kineticIndigo.withValues(alpha: 0.6)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        food.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (food.verificationBadge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: colors.neonEmerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            food.verificationBadge!,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: colors.neonEmerald,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (food.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      food.subtitle!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    '${food.baseCalories}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'kcal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Portion pills grid
          Row(
            children: List.generate(food.portionOptions.length, (idx) {
              final option = food.portionOptions[idx];
              final isChosen = selectedIdx == idx;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: idx < food.portionOptions.length - 1 ? 6 : 0),
                  child: GestureDetector(
                    onTap: () => notifier.selectPortion(food.id, idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isChosen
                            ? colors.kineticIndigo
                            : colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isChosen
                              ? colors.kineticIndigo
                              : colors.borderSubtle,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          option.label,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isChosen ? Colors.white : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

