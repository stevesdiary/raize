import {
  pgTable,
  uuid,
  varchar,
  text,
  numeric,
  integer,
  boolean,
  timestamp,
  date,
  jsonb,
  bigint,
  index,
  unique,
} from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

// ============================================================================
// PART 1: IDENTITY, PROFILE & HEALTH SAFEGUARDS (PRD Section 7.3, Entities 1-3, 7)
// ============================================================================

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  username: varchar('username', { length: 50 }).unique(),
  passwordHash: varchar('password_hash', { length: 255 }),
  role: varchar('role', { length: 32 }).notNull().default('user'), // 'user', 'coach', 'admin', 'compliance_officer'
  status: varchar('status', { length: 32 }).notNull().default('active'), // 'active', 'suspended', 'pending_deletion'
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export const userProfiles = pgTable('user_profiles', {
  userId: uuid('user_id').primaryKey().references(() => users.id, { onDelete: 'cascade' }),
  firstName: varchar('first_name', { length: 100 }),
  lastName: varchar('last_name', { length: 100 }),
  dateOfBirth: date('date_of_birth').notNull(),
  biologicalSex: varchar('biological_sex', { length: 20 }), // 'male', 'female', 'prefer_not_to_say'
  heightCm: numeric('height_cm', { precision: 5, scale: 2 }),
  weightKg: numeric('weight_kg', { precision: 5, scale: 2 }),
  countryCode: varchar('country_code', { length: 2 }).default('NG').notNull(),
  unitSystem: varchar('unit_system', { length: 20 }).default('metric').notNull(), // 'metric', 'imperial'
  timezone: varchar('timezone', { length: 50 }).default('Africa/Lagos').notNull(),
  avatarUrl: text('avatar_url'),
  fcmToken: text('fcm_token'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export const healthRestrictions = pgTable('health_restrictions', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  restrictionType: varchar('restriction_type', { length: 50 }).notNull(), // 'cardiovascular', 'joint_injury', 'hypertension', 'post_surgical', 'chest_pain_e05'
  affectedBodyParts: text('affected_body_parts').array(),
  medicalClearanceObtained: boolean('medical_clearance_obtained').default(false).notNull(),
  encryptedNotes: text('encrypted_notes'), // AES-256-GCM envelope encrypted
  isCriticalStop: boolean('is_critical_stop').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_health_restrictions_user').on(table.userId),
]);

// ============================================================================
// PART 2: ASSESSMENT ENGINE (PRD Section 7.3, Entities 4-6, 3)
// ============================================================================

export const assessmentQuestions = pgTable('assessment_questions', {
  id: varchar('id', { length: 32 }).primaryKey(), // e.g. 'A01', 'B01', 'E05'
  stage: varchar('stage', { length: 20 }).notNull(), // 'STAGE_A', 'STAGE_B', ..., 'STAGE_F'
  section: varchar('section', { length: 100 }).notNull(),
  questionText: text('question_text').notNull(),
  description: text('description'),
  inputType: varchar('input_type', { length: 32 }).notNull(), // 'single_choice', 'multi_choice', 'numeric', 'date', 'boolean', 'text'
  configuration: jsonb('configuration').default({}).notNull(),
  isRequired: boolean('is_required').default(true).notNull(),
  displayOrder: integer('display_order').notNull(),
  version: integer('version').default(1).notNull(),
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_assessment_questions_stage_order').on(table.stage, table.displayOrder),
  index('idx_assessment_questions_active').on(table.isActive),
]);

export const assessmentOptions = pgTable('assessment_options', {
  id: uuid('id').defaultRandom().primaryKey(),
  questionId: varchar('question_id', { length: 32 })
    .notNull()
    .references(() => assessmentQuestions.id, { onDelete: 'cascade' }),
  value: varchar('value', { length: 100 }).notNull(),
  displayText: varchar('display_text', { length: 255 }).notNull(),
  displayOrder: integer('display_order').notNull(),
  metadata: jsonb('metadata').default({}).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  unique('uidx_assessment_options_question_val').on(table.questionId, table.value),
  index('idx_assessment_options_question_order').on(table.questionId, table.displayOrder),
]);

export const fitnessAssessments = pgTable('fitness_assessments', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  version: integer('version').notNull().default(1),
  status: varchar('status', { length: 32 }).notNull().default('in_progress'), // 'in_progress', 'completed', 'superseded'
  lastActiveStage: varchar('last_active_stage', { length: 20 }).default('STAGE_A'),
  responses: jsonb('responses').default({}).notNull(),
  startedAt: timestamp('started_at', { withTimezone: true }).defaultNow().notNull(),
  completedAt: timestamp('completed_at', { withTimezone: true }),
}, (table) => [
  index('idx_fitness_assessments_user_version').on(table.userId, table.version),
]);

export const assessmentResponses = pgTable('assessment_responses', {
  id: uuid('id').defaultRandom().primaryKey(),
  assessmentId: uuid('assessment_id')
    .notNull()
    .references(() => fitnessAssessments.id, { onDelete: 'cascade' }),
  questionId: varchar('question_id', { length: 32 })
    .notNull()
    .references(() => assessmentQuestions.id, { onDelete: 'restrict' }),
  responseValue: jsonb('response_value').notNull(),
  answeredAt: timestamp('answered_at', { withTimezone: true }).defaultNow().notNull(),
  isSuperseded: boolean('is_superseded').default(false).notNull(),
}, (table) => [
  unique('uidx_assessment_responses_unique_active').on(table.assessmentId, table.questionId),
  index('idx_assessment_responses_assessment').on(table.assessmentId),
  index('idx_assessment_responses_question').on(table.questionId),
]);

// ============================================================================
// PART 3: GOALS, PATHWAYS & PROFILES (PRD Section 7.3, Entities 8-10)
// ============================================================================

export const fitnessGoals = pgTable('fitness_goals', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  goalType: varchar('goal_type', { length: 50 }).notNull(), // 'weight_management', 'build_muscle', 'build_strength', 'improve_endurance', 'improve_flexibility', 'healthy_lifestyle'
  priority: varchar('priority', { length: 20 }).default('primary').notNull(), // 'primary', 'secondary'
  targetValue: numeric('target_value', { precision: 8, scale: 2 }),
  currentValue: numeric('current_value', { precision: 8, scale: 2 }),
  unit: varchar('unit', { length: 32 }),
  targetDate: date('target_date'),
  status: varchar('status', { length: 32 }).default('active').notNull(), // 'active', 'achieved', 'abandoned', 'recalibrated'
  strategyNotes: text('strategy_notes'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_fitness_goals_user_status').on(table.userId, table.status),
  index('idx_fitness_goals_user_priority').on(table.userId, table.priority),
]);

export const fitnessProfiles = pgTable('fitness_profiles', {
  userId: uuid('user_id').primaryKey().references(() => users.id, { onDelete: 'cascade' }),
  primaryGoal: varchar('primary_goal', { length: 50 }).notNull(),
  experience: varchar('experience', { length: 20 }).notNull(), // 'beginner', 'intermediate', 'advanced'
  activityBaseline: varchar('activity_baseline', { length: 30 }).notNull(), // 'sedentary', 'low_active', 'moderately_active', 'highly_active'
  trainingEnvironment: varchar('training_environment', { length: 20 }).notNull(), // 'home', 'gym', 'outdoor', 'mixed'
  availabilityLevel: varchar('availability_level', { length: 20 }).notNull(), // 'low', 'moderate', 'high'
  safetyStatus: varchar('safety_status', { length: 50 }).notNull(), // 'standard', 'needs_modification', 'professional_guidance_required', 'exercise_paused_pending_assessment'
  classificationBadge: varchar('classification_badge', { length: 50 }),
  bmrCalories: integer('bmr_calories'),
  tdeeCalories: integer('tdee_calories'),
  targetDailyCalories: integer('target_daily_calories'),
  targetDailySteps: integer('target_daily_steps').default(10000).notNull(),
  lastCalculatedAt: timestamp('last_calculated_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export const fitnessPathways = pgTable('fitness_pathways', {
  id: varchar('id', { length: 50 }).primaryKey(), // 'weight_management', 'muscle_development', etc.
  name: varchar('name', { length: 100 }).notNull(),
  description: text('description').notNull(),
  primaryFocus: text('primary_focus').notNull(),
  nutritionFocus: text('nutrition_focus').notNull(),
  progressionRules: jsonb('progression_rules').default({}).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

// ============================================================================
// PART 4: ACTIVITIES & RECOMMENDATION ENGINE (PRD Section 7.3, Entities 11-13)
// ============================================================================

export const activityCatalog = pgTable('activity_catalog', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 100 }).notNull(),
  code: varchar('code', { length: 50 }).notNull().unique(), // e.g. 'walking', 'bodyweight_strength'
  category: varchar('category', { length: 50 }).notNull(), // 'cardio', 'strength', 'flexibility', 'recovery'
  primaryGoal: varchar('primary_goal', { length: 50 }).notNull(),
  metScore: numeric('met_score', { precision: 4, scale: 1 }).notNull().default('3.5'),
  defaultDurationMinutes: integer('default_duration_minutes').notNull().default(30),
  equipmentRequired: text('equipment_required').array().notNull(), // ['none'], ['dumbbells'], etc.
  environment: varchar('environment', { length: 30 }).notNull(), // 'home', 'gym', 'outdoor', 'any'
  difficultyLevel: varchar('difficulty_level', { length: 20 }).notNull(), // 'beginner', 'intermediate', 'advanced'
  contraindications: text('contraindications').array().default([]).notNull(),
  description: text('description').notNull(),
  isPublic: boolean('is_public').default(true).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_activity_catalog_goal').on(table.primaryGoal),
  index('idx_activity_catalog_code').on(table.code),
]);

export const recommendationRuns = pgTable('recommendation_runs', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  assessmentId: uuid('assessment_id').references(() => fitnessAssessments.id, { onDelete: 'set null' }),
  algorithmVersion: varchar('algorithm_version', { length: 20 }).notNull().default('1.0.0'),
  inputSnapshot: jsonb('input_snapshot').notNull(),
  generatedPlan: jsonb('generated_plan').notNull(), // 7-day weekly schedule + nutrition direction
  requiresProfessionalGuidance: boolean('requires_professional_guidance').default(false).notNull(),
  safetyStatus: varchar('safety_status', { length: 50 }).notNull(),
  userCanCustomize: boolean('user_can_customize').default(true).notNull(),
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_recommendation_runs_user').on(table.userId, table.isActive),
]);

export const fitnessRecommendations = pgTable('fitness_recommendations', {
  id: uuid('id').defaultRandom().primaryKey(),
  runId: uuid('run_id')
    .notNull()
    .references(() => recommendationRuns.id, { onDelete: 'cascade' }),
  activityId: uuid('activity_id')
    .notNull()
    .references(() => activityCatalog.id, { onDelete: 'restrict' }),
  activityType: varchar('activity_type', { length: 50 }).notNull(),
  priority: varchar('priority', { length: 20 }).notNull(), // 'primary', 'supporting', 'recovery'
  score: numeric('score', { precision: 5, scale: 2 }).notNull(), // 0 to 100
  scoreBreakdown: jsonb('score_breakdown').notNull(),
  explanation: text('explanation').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_fitness_recommendations_run').on(table.runId),
]);

// ============================================================================
// PART 5: WORKOUT PROGRAMS & EXECUTION (PRD Section 7.3, Entities 14-17)
// ============================================================================

export const workoutPrograms = pgTable('workout_programs', {
  id: uuid('id').defaultRandom().primaryKey(),
  title: varchar('title', { length: 150 }).notNull(),
  description: text('description').notNull(),
  pathwayId: varchar('pathway_id', { length: 50 }).references(() => fitnessPathways.id, { onDelete: 'set null' }),
  goal: varchar('goal', { length: 50 }).notNull(),
  difficultyLevel: varchar('difficulty_level', { length: 20 }).notNull(),
  durationWeeks: integer('duration_weeks').notNull().default(4),
  daysPerWeek: integer('days_per_week').notNull().default(3),
  isPremium: boolean('is_premium').default(false).notNull(),
  authorId: uuid('author_id').references(() => users.id, { onDelete: 'set null' }),
  coverImageUrl: text('cover_image_url'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export const exercises = pgTable('exercises', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 150 }).notNull(),
  category: varchar('category', { length: 50 }).notNull(), // 'chest', 'back', 'legs', 'shoulders', 'arms', 'core', 'cardio'
  primaryMuscle: varchar('primary_muscle', { length: 50 }).notNull(),
  secondaryMuscles: text('secondary_muscles').array().default([]).notNull(),
  equipment: varchar('equipment', { length: 50 }).notNull(), // 'bodyweight', 'dumbbells', 'barbell', 'machine', 'cables', 'bands'
  instructions: text('instructions').notNull(),
  videoUrl: text('video_url'),
  thumbnailUrl: text('thumbnail_url'),
  contraindications: text('contraindications').array().default([]).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_exercises_category').on(table.category),
  index('idx_exercises_equipment').on(table.equipment),
]);

export const workoutSessions = pgTable('workout_sessions', {
  id: uuid('id').defaultRandom().primaryKey(),
  programId: uuid('program_id').references(() => workoutPrograms.id, { onDelete: 'set null' }),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  title: varchar('title', { length: 150 }).notNull(),
  scheduledDate: date('scheduled_date').notNull(),
  status: varchar('status', { length: 32 }).notNull().default('scheduled'), // 'scheduled', 'in_progress', 'completed', 'skipped'
  startedAt: timestamp('started_at', { withTimezone: true }),
  completedAt: timestamp('completed_at', { withTimezone: true }),
  totalDurationSeconds: integer('total_duration_seconds').notNull().default(0),
  totalVolumeKg: numeric('total_volume_kg', { precision: 10, scale: 2 }).notNull().default('0'),
  rpe: integer('rpe'),
  notes: text('notes'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_workout_sessions_user_date').on(table.userId, table.scheduledDate),
  index('idx_workout_sessions_status').on(table.status),
]);

export const workoutSets = pgTable('workout_sets', {
  id: uuid('id').defaultRandom().primaryKey(),
  sessionId: uuid('session_id')
    .notNull()
    .references(() => workoutSessions.id, { onDelete: 'cascade' }),
  exerciseId: uuid('exercise_id')
    .notNull()
    .references(() => exercises.id, { onDelete: 'restrict' }),
  setOrder: integer('set_order').notNull(),
  setType: varchar('set_type', { length: 20 }).notNull().default('normal'), // 'warmup', 'normal', 'drop_set', 'failure', 'superset'
  reps: integer('reps').notNull(),
  weightKg: numeric('weight_kg', { precision: 6, scale: 2 }).notNull().default('0'),
  rpe: numeric('rpe', { precision: 3, scale: 1 }),
  isCompleted: boolean('is_completed').notNull().default(true),
  isPersonalRecord: boolean('is_personal_record').notNull().default(false),
  restSecondsAfter: integer('rest_seconds_after').default(60),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_workout_sets_session').on(table.sessionId),
  index('idx_workout_sets_exercise').on(table.exerciseId),
]);

// ============================================================================
// PART 6: NUTRITION & FOOD CATALOG (PRD Section 7.3, Entities 18-19, Sup)
// ============================================================================

export const foodCatalog = pgTable('food_catalog', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 200 }).notNull(),
  brand: varchar('brand', { length: 100 }),
  servingSizeGrams: numeric('serving_size_grams', { precision: 8, scale: 2 }).notNull(),
  servingUnit: varchar('serving_unit', { length: 50 }).notNull().default('g'),
  calories: numeric('calories', { precision: 8, scale: 2 }).notNull(),
  proteinGrams: numeric('protein_grams', { precision: 8, scale: 2 }).notNull().default('0'),
  carbsGrams: numeric('carbs_grams', { precision: 8, scale: 2 }).notNull().default('0'),
  fatGrams: numeric('fat_grams', { precision: 8, scale: 2 }).notNull().default('0'),
  fiberGrams: numeric('fiber_grams', { precision: 8, scale: 2 }).default('0'),
  source: varchar('source', { length: 50 }).notNull().default('verified_nigerian'), // 'verified_nigerian', 'usda', 'user_custom', 'openfoodfacts'
  confidenceScore: numeric('confidence_score', { precision: 3, scale: 2 }).notNull().default('0.95'),
  barcode: varchar('barcode', { length: 64 }),
  isVerifiedNigerian: boolean('is_verified_nigerian').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_food_catalog_name').on(table.name),
  index('idx_food_catalog_barcode').on(table.barcode),
]);

export const foodPortionUnits = pgTable('food_portion_units', {
  id: uuid('id').defaultRandom().primaryKey(),
  foodId: uuid('foodId')
    .notNull()
    .references(() => foodCatalog.id, { onDelete: 'cascade' }),
  unitName: varchar('unit_name', { length: 50 }).notNull(), // 'mudu', 'derica', 'medium_tuber', 'wrap', 'cup', 'spoon'
  gramWeightRatio: numeric('gram_weight_ratio', { precision: 8, scale: 2 }).notNull(), // equivalent grams per unit
  isLocalMeasure: boolean('is_local_measure').default(true).notNull(),
  notes: text('notes'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_food_portion_units_food').on(table.foodId),
]);

export const nutritionEntries = pgTable('nutrition_entries', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  foodId: uuid('food_id').notNull().references(() => foodCatalog.id, { onDelete: 'restrict' }),
  loggedDate: date('logged_date').notNull(),
  mealSlot: varchar('meal_slot', { length: 20 }).notNull(), // 'breakfast', 'lunch', 'dinner', 'snack'
  quantity: numeric('quantity', { precision: 6, scale: 2 }).notNull(),
  portionUnitId: uuid('portion_unit_id').references(() => foodPortionUnits.id, { onDelete: 'set null' }),
  totalCalories: numeric('total_calories', { precision: 8, scale: 2 }).notNull(),
  totalProteinG: numeric('total_protein_g', { precision: 8, scale: 2 }).notNull(),
  totalCarbsG: numeric('total_carbs_g', { precision: 8, scale: 2 }).notNull(),
  totalFatG: numeric('total_fat_g', { precision: 8, scale: 2 }).notNull(),
  notes: text('notes'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_nutrition_entries_user_date').on(table.userId, table.loggedDate),
]);

// ============================================================================
// PART 7: OUTDOOR GPS ACTIVITY TRACKING (PRD Section 7.3, Entities 20-21)
// ============================================================================

export const activitySessions = pgTable('activity_sessions', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  activityType: varchar('activity_type', { length: 32 }).notNull(), // 'running', 'walking', 'cycling', 'swimming', 'sports'
  startedAt: timestamp('started_at', { withTimezone: true }).notNull(),
  completedAt: timestamp('completed_at', { withTimezone: true }),
  durationSeconds: integer('duration_seconds').notNull().default(0),
  distanceMeters: numeric('distance_meters', { precision: 10, scale: 2 }).notNull().default('0'),
  averagePaceSecPerKm: integer('average_pace_sec_per_km'),
  totalElevationGainMeters: numeric('total_elevation_gain_meters', { precision: 6, scale: 1 }).default('0'),
  caloriesBurned: integer('calories_burned').default(0),
  perceivedExertion: integer('perceived_exertion'),
  isManual: boolean('is_manual').default(false).notNull(),
  notes: text('notes'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_activity_sessions_user_time').on(table.userId, table.startedAt),
]);

export const activityRoutes = pgTable('activity_routes', {
  id: uuid('id').defaultRandom().primaryKey(),
  activityId: uuid('activity_id')
    .notNull()
    .references(() => activitySessions.id, { onDelete: 'cascade' }),
  polylineEncoded: text('polyline_encoded'),
  rawGpsPoints: jsonb('raw_gps_points'), // Array of {lat, lng, alt, time, speed}
  privacyMaskApplied: boolean('privacy_mask_applied').default(false).notNull(),
  privacyRadiusMeters: integer('privacy_radius_meters').default(250),
  elevationProfile: jsonb('elevation_profile'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  unique('uidx_activity_routes_activity').on(table.activityId),
]);

export const userPrivacyZones = pgTable('user_privacy_zones', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  label: varchar('label', { length: 50 }).notNull(), // 'Home', 'Office'
  centerLatitude: numeric('center_latitude', { precision: 10, scale: 7 }).notNull(),
  centerLongitude: numeric('center_longitude', { precision: 10, scale: 7 }).notNull(),
  radiusMeters: integer('radius_meters').notNull().default(250),
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_user_privacy_zones_user').on(table.userId),
]);

// ============================================================================
// PART 8: PROGRESS, FEEDBACK & COMMUNITY (PRD Section 7.3, Entities 22-23)
// ============================================================================

export const progressRecords = pgTable('progress_records', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  metricType: varchar('metric_type', { length: 50 }).notNull(), // 'weight_kg', 'workout_volume_kg', 'running_5k_sec', 'resting_hr_bpm'
  metricValue: numeric('metric_value', { precision: 10, scale: 2 }).notNull(),
  unit: varchar('unit', { length: 32 }).notNull(),
  notes: text('notes'),
  recordedAt: timestamp('recorded_at', { withTimezone: true }).defaultNow().notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_progress_records_user_metric').on(table.userId, table.metricType, table.recordedAt),
]);

export const userFeedback = pgTable('user_feedback', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  recommendationId: uuid('recommendation_id').references(() => recommendationRuns.id, { onDelete: 'set null' }),
  sessionId: uuid('session_id').references(() => workoutSessions.id, { onDelete: 'set null' }),
  feedbackType: varchar('feedback_type', { length: 50 }).notNull(), // 'difficulty_too_hard', 'difficulty_too_easy', 'schedule_conflict', 'enjoyed'
  rating: integer('rating'), // 1 to 5
  comment: text('comment'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_user_feedback_user').on(table.userId),
]);

// Community & Social Posts
export const communityPosts = pgTable('community_posts', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  activitySessionId: uuid('activity_session_id').references(() => activitySessions.id, { onDelete: 'set null' }),
  workoutSessionId: uuid('workout_session_id').references(() => workoutSessions.id, { onDelete: 'set null' }),
  caption: text('caption'),
  mediaUrl: text('media_url'),
  visibility: varchar('visibility', { length: 20 }).default('public').notNull(), // 'public', 'friends', 'private'
  kudosCount: integer('kudos_count').default(0).notNull(),
  commentsCount: integer('comments_count').default(0).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_community_posts_user_time').on(table.userId, table.createdAt),
]);

export const communityKudos = pgTable('community_kudos', {
  id: uuid('id').defaultRandom().primaryKey(),
  postId: uuid('post_id').notNull().references(() => communityPosts.id, { onDelete: 'cascade' }),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  unique('uidx_community_kudos_post_user').on(table.postId, table.userId),
]);

export const communityComments = pgTable('community_comments', {
  id: uuid('id').defaultRandom().primaryKey(),
  postId: uuid('post_id').notNull().references(() => communityPosts.id, { onDelete: 'cascade' }),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  commentText: text('comment_text').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_community_comments_post').on(table.postId),
]);

export const fitnessChallenges = pgTable('fitness_challenges', {
  id: uuid('id').defaultRandom().primaryKey(),
  title: varchar('title', { length: 150 }).notNull(),
  description: text('description').notNull(),
  challengeType: varchar('challenge_type', { length: 50 }).notNull(), // 'distance_run', 'workout_count', 'active_days'
  targetValue: numeric('target_value', { precision: 10, scale: 2 }).notNull(),
  unit: varchar('unit', { length: 32 }).notNull(),
  startDate: date('start_date').notNull(),
  endDate: date('end_date').notNull(),
  badgeIconUrl: text('badge_icon_url'),
  isPublic: boolean('is_public').default(true).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const challengeParticipants = pgTable('challenge_participants', {
  id: uuid('id').defaultRandom().primaryKey(),
  challengeId: uuid('challenge_id').notNull().references(() => fitnessChallenges.id, { onDelete: 'cascade' }),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  currentProgress: numeric('current_progress', { precision: 10, scale: 2 }).default('0').notNull(),
  isCompleted: boolean('is_completed').default(false).notNull(),
  joinedAt: timestamp('joined_at', { withTimezone: true }).defaultNow().notNull(),
  completedAt: timestamp('completed_at', { withTimezone: true }),
}, (table) => [
  unique('uidx_challenge_participant').on(table.challengeId, table.userId),
]);

// ============================================================================
// PART 9: SUBSCRIPTIONS & MONETIZATION (PRD Section 7.3, Entities 24-25, Operational)
// ============================================================================

export const subscriptions = pgTable('subscriptions', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'set null' }),
  planId: varchar('plan_id', { length: 50 }).notNull(), // 'free', 'premium_monthly', 'premium_annual', 'coaching_monthly'
  status: varchar('status', { length: 32 }).notNull().default('active'), // 'active', 'past_due', 'canceled', 'trialing'
  provider: varchar('provider', { length: 32 }).notNull().default('paystack'), // 'paystack', 'revenuecat_apple', 'revenuecat_google', 'free'
  providerSubscriptionId: varchar('provider_subscription_id', { length: 150 }),
  providerCustomerCode: varchar('provider_customer_code', { length: 150 }),
  currentPeriodStart: timestamp('current_period_start', { withTimezone: true }),
  currentPeriodEnd: timestamp('current_period_end', { withTimezone: true }),
  cancelAtPeriodEnd: boolean('cancel_at_period_end').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_subscriptions_user_status').on(table.userId, table.status),
]);

export const billingTransactions = pgTable('billing_transactions', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
  subscriptionId: uuid('subscription_id').references(() => subscriptions.id, { onDelete: 'set null' }),
  amountNgn: numeric('amount_ngn', { precision: 10, scale: 2 }).default('0'),
  amountUsd: numeric('amount_usd', { precision: 8, scale: 2 }).default('0'),
  currency: varchar('currency', { length: 10 }).notNull().default('NGN'),
  status: varchar('status', { length: 32 }).notNull(), // 'success', 'failed', 'pending', 'refunded'
  paymentMethod: varchar('payment_method', { length: 50 }).notNull(), // 'card', 'bank_transfer', 'ussd', 'in_app_purchase'
  providerReference: varchar('provider_reference', { length: 255 }).notNull().unique(),
  legalHoldRetainedUntil: timestamp('legal_hold_retained_until', { withTimezone: true }).notNull(), // CAMA 2020: created_at + 6 years
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_billing_transactions_user').on(table.userId),
  index('idx_billing_transactions_reference').on(table.providerReference),
]);

export const notificationPreferences = pgTable('notification_preferences', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().unique().references(() => users.id, { onDelete: 'cascade' }),
  workoutReminders: boolean('workout_reminders').default(true).notNull(),
  workoutReminderTime: varchar('workout_reminder_time', { length: 10 }).default('07:00').notNull(),
  nutritionNudges: boolean('nutrition_nudges').default(true).notNull(),
  weeklyReviewPrompt: boolean('weekly_review_prompt').default(true).notNull(),
  socialCheers: boolean('social_cheers').default(true).notNull(),
  quietHoursStart: varchar('quiet_hours_start', { length: 10 }).default('22:00'),
  quietHoursEnd: varchar('quiet_hours_end', { length: 10 }).default('06:00'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

// ============================================================================
// PART 10: COMPLIANCE, SECURITY & OFFLINE SYNC (NDPA 2023, CAMA 2020, Sync Engine)
// ============================================================================

export const userConsents = pgTable('user_consents', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  consentType: varchar('consent_type', { length: 50 }).notNull(), // 'terms_of_service', 'health_data_processing', 'location_tracking', 'marketing'
  granted: boolean('granted').notNull().default(true),
  ipAddressHash: varchar('ip_address_hash', { length: 64 }).notNull(),
  policyVersion: varchar('policy_version', { length: 20 }).notNull(),
  grantedAt: timestamp('granted_at', { withTimezone: true }).defaultNow().notNull(),
  revokedAt: timestamp('revoked_at', { withTimezone: true }),
}, (table) => [
  index('idx_user_consents_user_type').on(table.userId, table.consentType),
]);

export const auditLogs = pgTable('audit_logs', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
  action: varchar('action', { length: 100 }).notNull(),
  targetEntity: varchar('target_entity', { length: 50 }).notNull(),
  entityId: varchar('entity_id', { length: 100 }),
  changes: jsonb('changes'),
  ipAddress: varchar('ip_address', { length: 45 }),
  userAgent: text('user_agent'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_audit_logs_user_time').on(table.userId, table.createdAt),
]);

export const syncQuarantine = pgTable('sync_quarantine', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  mutationType: varchar('mutation_type', { length: 50 }).notNull(),
  payload: jsonb('payload').notNull(),
  errorMessage: text('error_message').notNull(),
  resolved: boolean('resolved').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const syncIdempotencyRecords = pgTable('sync_idempotency_records', {
  idempotencyKey: varchar('idempotency_key', { length: 128 }).primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  endpoint: varchar('endpoint', { length: 150 }).notNull(),
  responseStatus: integer('response_status').notNull(),
  responseBody: jsonb('response_body').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
}, (table) => [
  index('idx_sync_idempotency_expiry').on(table.expiresAt),
]);


// ============================================================================
// PART 11: COACH ONBOARDING & VERIFICATION (PRD 4-Pillar Pipeline & Paystack NUBAN)
// ============================================================================

export const coachProfiles = pgTable('coach_profiles', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().unique().references(() => users.id, { onDelete: 'cascade' }),
  fullName: varchar('full_name', { length: 150 }).notNull(),
  bio: text('bio').notNull(),
  specialties: jsonb('specialties').$type<string[]>().notNull(),
  experienceYears: integer('experience_years').notNull().default(1),
  accreditationBody: varchar('accreditation_body', { length: 100 }).notNull(),
  licenseNumber: varchar('license_number', { length: 100 }).notNull(),
  certificateUrl: varchar('certificate_url', { length: 500 }),
  governmentIdUrl: varchar('government_id_url', { length: 500 }),
  idType: varchar('id_type', { length: 50 }).notNull().default('NIN'),
  idNumber: varchar('id_number', { length: 100 }).notNull(),
  verificationStatus: varchar('verification_status', { length: 32 }).notNull().default('pending'),
  verifiedAt: timestamp('verified_at', { withTimezone: true }),
  rejectionReason: text('rejection_reason'),
  verifiedBy: uuid('verified_by').references(() => users.id, { onDelete: 'set null' }),
  bankCode: varchar('bank_code', { length: 10 }).notNull(),
  bankName: varchar('bank_name', { length: 100 }).notNull(),
  accountNumber: varchar('account_number', { length: 10 }).notNull(),
  accountName: varchar('account_name', { length: 150 }).notNull(),
  paystackRecipientCode: varchar('paystack_recipient_code', { length: 100 }),
  monthlyRetainerNgn: integer('monthly_retainer_ngn').notNull().default(25000),
  ndpaDpaAccepted: boolean('ndpa_dpa_accepted').notNull().default(false),
  ndpaDpaAcceptedAt: timestamp('ndpa_dpa_accepted_at', { withTimezone: true }),
  isActive: boolean('is_active').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_coach_profiles_verification').on(table.verificationStatus),
  index('idx_coach_profiles_active').on(table.isActive),
]);
