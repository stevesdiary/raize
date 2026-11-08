import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Automatically choose localhost, Android emulator host (10.0.2.2), or web
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    return 'http://127.0.0.1:3000/api/v1';
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String deleteAccount = '/auth/account';

  // Assessment
  static const String assessmentQuestions = '/assessments/questions';
  static const String assessments = '/assessments';
  static const String assessmentResponses = '/assessments/responses';
  static const String assessmentComplete = '/assessments/complete';

  // Recommendations
  static const String recommendationsGenerate = '/recommendations/generate';
  static const String recommendationsActive = '/recommendations/active';
  static const String recommendationsActivate = '/recommendations/activate';

  // Dashboard & Schedule
  static const String dashboard = '/dashboard/daily-summary';
  static const String weeklySchedule = '/recommendations/active';

  // Activities & GPS
  static const String manualActivity = '/activities/manual';
  static const String gpsStart = '/activities/gps/start';
  static const String gpsComplete = '/activities/gps/complete';
  static const String privacyZones = '/activities/privacy-zones';

  // Nutrition
  static const String foodSearch = '/nutrition/foods/search';
  static const String nutritionEntries = '/nutrition/entries';
  static const String nutritionSummary = '/nutrition/summary';

  // Workouts
  static const String workoutToday = '/workouts/today';
  static const String workoutExercises = '/workouts/exercises';
  static const String workoutSessions = '/workouts/sessions';

  // Billing
  static const String billingPlans = '/billing/plans';
  static const String billingSubscription = '/billing/subscription';
  static const String billingSubscriptionCancel = '/billing/subscription/cancel';
  static const String paystackInitialize = '/billing/paystack/initialize';
}

