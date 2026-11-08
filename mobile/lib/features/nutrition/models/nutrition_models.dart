class PortionUnitOption {
  final String label;
  final double multiplier;
  final int? grams;

  const PortionUnitOption({
    required this.label,
    required this.multiplier,
    this.grams,
  });
}

class FoodItem {
  final String id;
  final String name;
  final String category;
  final String? subtitle;
  final String? verificationBadge;
  final int baseCalories;
  final double baseProtein;
  final double baseCarbs;
  final double baseFat;
  final List<PortionUnitOption> portionOptions;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    this.subtitle,
    this.verificationBadge,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    required this.portionOptions,
  });
}

class MealSlot {
  final String id; // 'breakfast', 'lunch', 'dinner', 'snack'
  final String title;
  final String targetTime;
  final int calories;
  final String? description;
  final String? portionNote;
  final bool isLogged;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  const MealSlot({
    required this.id,
    required this.title,
    required this.targetTime,
    required this.calories,
    this.description,
    this.portionNote,
    this.isLogged = false,
    this.proteinGrams = 0,
    this.carbsGrams = 0,
    this.fatGrams = 0,
  });

  MealSlot copyWith({
    String? id,
    String? title,
    String? targetTime,
    int? calories,
    String? description,
    String? portionNote,
    bool? isLogged,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
  }) {
    return MealSlot(
      id: id ?? this.id,
      title: title ?? this.title,
      targetTime: targetTime ?? this.targetTime,
      calories: calories ?? this.calories,
      description: description ?? this.description,
      portionNote: portionNote ?? this.portionNote,
      isLogged: isLogged ?? this.isLogged,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
    );
  }
}

class DailyNutritionState {
  final String dateLabel;
  final String mode;
  final int consumedCalories;
  final int targetCalories;
  final double proteinConsumed;
  final double proteinTarget;
  final double carbsConsumed;
  final double carbsTarget;
  final double fatConsumed;
  final double fatTarget;
  final double hydrationLiters;
  final double hydrationTargetLiters;
  final List<MealSlot> meals;
  final String activeCategory;
  final String searchQuery;
  final List<FoodItem> catalogFoods;
  final Map<String, int> selectedPortions; // foodId -> optionIndex

  const DailyNutritionState({
    this.dateLabel = 'Today, Nov 7',
    this.mode = 'Caloric Deficit Mode',
    this.consumedCalories = 1420,
    this.targetCalories = 2045,
    this.proteinConsumed = 85.0,
    this.proteinTarget = 110.0,
    this.carbsConsumed = 160.0,
    this.carbsTarget = 230.0,
    this.fatConsumed = 45.0,
    this.fatTarget = 55.0,
    this.hydrationLiters = 2.2,
    this.hydrationTargetLiters = 3.0,
    this.meals = const [
      MealSlot(
        id: 'breakfast',
        title: 'Breakfast',
        targetTime: '08:15 AM',
        calories: 420,
        description: 'Rolled Oats with Greek Yogurt & Honey',
        isLogged: true,
        proteinGrams: 22,
        carbsGrams: 65,
        fatGrams: 8,
      ),
      MealSlot(
        id: 'lunch',
        title: 'Lunch',
        targetTime: '01:30 PM',
        calories: 640,
        description: 'Jollof Rice with Grilled Chicken Breast',
        portionNote: '1.5 plates • Nigerian Standard Portion Calibration',
        isLogged: true,
        proteinGrams: 48,
        carbsGrams: 72,
        fatGrams: 18,
      ),
      MealSlot(
        id: 'dinner',
        title: 'Dinner',
        targetTime: 'TARGET 07:30 PM',
        calories: 585,
        description: 'Remaining evening macros: P: 25g • C: 70g • F: 10g.',
        isLogged: false,
        proteinGrams: 0,
        carbsGrams: 0,
        fatGrams: 0,
      ),
      MealSlot(
        id: 'snack',
        title: 'Evening Fuel / Snack',
        targetTime: 'Standby',
        calories: 120,
        description: 'Optional 120 kcal buffer',
        isLogged: false,
        proteinGrams: 0,
        carbsGrams: 0,
        fatGrams: 0,
      ),
    ],
    this.activeCategory = 'Nigerian Staples 🇳🇬',
    this.searchQuery = 'Pounded Yam',
    this.catalogFoods = const [
      FoodItem(
        id: 'food_pounded_yam',
        name: 'Pounded Yam',
        category: 'Nigerian Staples 🇳🇬',
        subtitle: 'Calibrated to standard Lagos tuber density',
        verificationBadge: 'Verified Carbs',
        baseCalories: 280,
        baseProtein: 4.0,
        baseCarbs: 65.0,
        baseFat: 0.5,
        portionOptions: [
          PortionUnitOption(label: '1 Wrap (200g)', multiplier: 1.0, grams: 200),
          PortionUnitOption(label: '1.5 Wraps', multiplier: 1.5, grams: 300),
          PortionUnitOption(label: '1 Derica Raw', multiplier: 2.8, grams: 550),
        ],
      ),
      FoodItem(
        id: 'food_egusi_soup',
        name: 'Egusi Soup with Fish',
        category: 'Nigerian Staples 🇳🇬',
        subtitle: 'Traditional melon seed broth • P: 18g | F: 22g',
        baseCalories: 310,
        baseProtein: 18.0,
        baseCarbs: 8.0,
        baseFat: 22.0,
        portionOptions: [
          PortionUnitOption(label: '1 Scoop', multiplier: 0.7),
          PortionUnitOption(label: '1 Bowl (Std)', multiplier: 1.0),
          PortionUnitOption(label: '+2 Pcs Protein', multiplier: 1.4),
        ],
      ),
      FoodItem(
        id: 'food_beef_suya',
        name: 'Beef Suya',
        category: 'Nigerian Staples 🇳🇬',
        subtitle: 'Yaji spiced lean sirloin skewers',
        baseCalories: 260,
        baseProtein: 32.0,
        baseCarbs: 3.0,
        baseFat: 12.0,
        portionOptions: [
          PortionUnitOption(label: '1 Stick (75g)', multiplier: 0.5, grams: 75),
          PortionUnitOption(label: 'Half Paper (150g)', multiplier: 1.0, grams: 150),
          PortionUnitOption(label: '1 Full Parcel', multiplier: 2.0, grams: 300),
        ],
      ),
    ],
    this.selectedPortions = const {
      'food_pounded_yam': 0,
      'food_egusi_soup': 1,
      'food_beef_suya': 0,
    },
  });

  int get remainingCalories => (targetCalories - consumedCalories).clamp(0, 99999);
  double get calorieProgressRatio =>
      (consumedCalories / (targetCalories <= 0 ? 1 : targetCalories)).clamp(0.0, 1.0);
  int get caloriePercentage => (calorieProgressRatio * 100).round();

  int get loggedMealsCount => meals.where((m) => m.isLogged).length;

  DailyNutritionState copyWith({
    String? dateLabel,
    String? mode,
    int? consumedCalories,
    int? targetCalories,
    double? proteinConsumed,
    double? proteinTarget,
    double? carbsConsumed,
    double? carbsTarget,
    double? fatConsumed,
    double? fatTarget,
    double? hydrationLiters,
    double? hydrationTargetLiters,
    List<MealSlot>? meals,
    String? activeCategory,
    String? searchQuery,
    List<FoodItem>? catalogFoods,
    Map<String, int>? selectedPortions,
  }) {
    return DailyNutritionState(
      dateLabel: dateLabel ?? this.dateLabel,
      mode: mode ?? this.mode,
      consumedCalories: consumedCalories ?? this.consumedCalories,
      targetCalories: targetCalories ?? this.targetCalories,
      proteinConsumed: proteinConsumed ?? this.proteinConsumed,
      proteinTarget: proteinTarget ?? this.proteinTarget,
      carbsConsumed: carbsConsumed ?? this.carbsConsumed,
      carbsTarget: carbsTarget ?? this.carbsTarget,
      fatConsumed: fatConsumed ?? this.fatConsumed,
      fatTarget: fatTarget ?? this.fatTarget,
      hydrationLiters: hydrationLiters ?? this.hydrationLiters,
      hydrationTargetLiters: hydrationTargetLiters ?? this.hydrationTargetLiters,
      meals: meals ?? this.meals,
      activeCategory: activeCategory ?? this.activeCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      catalogFoods: catalogFoods ?? this.catalogFoods,
      selectedPortions: selectedPortions ?? this.selectedPortions,
    );
  }
}

