import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/nutrition_models.dart';

class NutritionNotifier extends Notifier<DailyNutritionState> {
  @override
  DailyNutritionState build() {
    return const DailyNutritionState();
  }

  void addHydration(double liters) {
    final next = double.parse((state.hydrationLiters + liters).toStringAsFixed(1));
    state = state.copyWith(hydrationLiters: next);
  }

  void selectPortion(String foodId, int optionIndex) {
    final updated = Map<String, int>.from(state.selectedPortions);
    updated[foodId] = optionIndex;
    state = state.copyWith(selectedPortions: updated);
  }

  void setCategory(String category) {
    state = state.copyWith(activeCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> logFoodToMeal({
    required String mealId,
    required FoodItem food,
    required int portionIndex,
    bool syncBackend = false,
  }) async {
    final portion = food.portionOptions[portionIndex];
    final addedKcal = (food.baseCalories * portion.multiplier).round();
    final addedProtein = food.baseProtein * portion.multiplier;
    final addedCarbs = food.baseCarbs * portion.multiplier;
    final addedFat = food.baseFat * portion.multiplier;

    final updatedMeals = state.meals.map((meal) {
      if (meal.id == mealId) {
        return meal.copyWith(
          isLogged: true,
          calories: meal.calories + addedKcal,
          description: '${food.name} (${portion.label})',
          proteinGrams: meal.proteinGrams + addedProtein,
          carbsGrams: meal.carbsGrams + addedCarbs,
          fatGrams: meal.fatGrams + addedFat,
        );
      }
      return meal;
    }).toList();

    state = state.copyWith(
      consumedCalories: state.consumedCalories + addedKcal,
      proteinConsumed: state.proteinConsumed + addedProtein,
      carbsConsumed: state.carbsConsumed + addedCarbs,
      fatConsumed: state.fatConsumed + addedFat,
      meals: updatedMeals,
    );

    if (!syncBackend) return true;

    try {
      final dio = ref.read(apiClientProvider).client;
      final payload = {
        'mealSlot': mealId,
        'mealType': mealId,
        'foodId': food.id,
        'quantity': portion.multiplier,
        'unit': portion.label,
        'calories': addedKcal,
        'protein': addedProtein,
        'carbs': addedCarbs,
        'fat': addedFat,
      };
      final response = await dio.post(ApiEndpoints.nutritionEntries, data: payload);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

final nutritionProvider =
    NotifierProvider<NutritionNotifier, DailyNutritionState>(NutritionNotifier.new);

