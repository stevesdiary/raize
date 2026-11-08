CREATE TABLE "activity_catalog" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(100) NOT NULL,
	"code" varchar(50) NOT NULL,
	"category" varchar(50) NOT NULL,
	"primary_goal" varchar(50) NOT NULL,
	"met_score" numeric(4, 1) DEFAULT '3.5' NOT NULL,
	"default_duration_minutes" integer DEFAULT 30 NOT NULL,
	"equipment_required" text[] NOT NULL,
	"environment" varchar(30) NOT NULL,
	"difficulty_level" varchar(20) NOT NULL,
	"contraindications" text[] DEFAULT '{}' NOT NULL,
	"description" text NOT NULL,
	"is_public" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "activity_catalog_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "activity_routes" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"activity_id" uuid NOT NULL,
	"polyline_encoded" text,
	"raw_gps_points" jsonb,
	"privacy_mask_applied" boolean DEFAULT false NOT NULL,
	"privacy_radius_meters" integer DEFAULT 250,
	"elevation_profile" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "uidx_activity_routes_activity" UNIQUE("activity_id")
);
--> statement-breakpoint
CREATE TABLE "activity_sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"activity_type" varchar(32) NOT NULL,
	"started_at" timestamp with time zone NOT NULL,
	"completed_at" timestamp with time zone,
	"duration_seconds" integer DEFAULT 0 NOT NULL,
	"distance_meters" numeric(10, 2) DEFAULT '0' NOT NULL,
	"average_pace_sec_per_km" integer,
	"total_elevation_gain_meters" numeric(6, 1) DEFAULT '0',
	"calories_burned" integer DEFAULT 0,
	"perceived_exertion" integer,
	"is_manual" boolean DEFAULT false NOT NULL,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "assessment_options" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"question_id" varchar(32) NOT NULL,
	"value" varchar(100) NOT NULL,
	"display_text" varchar(255) NOT NULL,
	"display_order" integer NOT NULL,
	"metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "uidx_assessment_options_question_val" UNIQUE("question_id","value")
);
--> statement-breakpoint
CREATE TABLE "assessment_questions" (
	"id" varchar(32) PRIMARY KEY NOT NULL,
	"stage" varchar(20) NOT NULL,
	"section" varchar(100) NOT NULL,
	"question_text" text NOT NULL,
	"description" text,
	"input_type" varchar(32) NOT NULL,
	"configuration" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"is_required" boolean DEFAULT true NOT NULL,
	"display_order" integer NOT NULL,
	"version" integer DEFAULT 1 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "assessment_responses" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"assessment_id" uuid NOT NULL,
	"question_id" varchar(32) NOT NULL,
	"response_value" jsonb NOT NULL,
	"answered_at" timestamp with time zone DEFAULT now() NOT NULL,
	"is_superseded" boolean DEFAULT false NOT NULL,
	CONSTRAINT "uidx_assessment_responses_unique_active" UNIQUE("assessment_id","question_id")
);
--> statement-breakpoint
CREATE TABLE "audit_logs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid,
	"action" varchar(100) NOT NULL,
	"target_entity" varchar(50) NOT NULL,
	"entity_id" varchar(100),
	"changes" jsonb,
	"ip_address" varchar(45),
	"user_agent" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "billing_transactions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid,
	"subscription_id" uuid,
	"amount_ngn" numeric(10, 2) DEFAULT '0',
	"amount_usd" numeric(8, 2) DEFAULT '0',
	"currency" varchar(10) DEFAULT 'NGN' NOT NULL,
	"status" varchar(32) NOT NULL,
	"payment_method" varchar(50) NOT NULL,
	"provider_reference" varchar(255) NOT NULL,
	"legal_hold_retained_until" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "billing_transactions_provider_reference_unique" UNIQUE("provider_reference")
);
--> statement-breakpoint
CREATE TABLE "challenge_participants" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"challenge_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"current_progress" numeric(10, 2) DEFAULT '0' NOT NULL,
	"is_completed" boolean DEFAULT false NOT NULL,
	"joined_at" timestamp with time zone DEFAULT now() NOT NULL,
	"completed_at" timestamp with time zone,
	CONSTRAINT "uidx_challenge_participant" UNIQUE("challenge_id","user_id")
);
--> statement-breakpoint
CREATE TABLE "community_comments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"post_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"comment_text" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "community_kudos" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"post_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "uidx_community_kudos_post_user" UNIQUE("post_id","user_id")
);
--> statement-breakpoint
CREATE TABLE "community_posts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"activity_session_id" uuid,
	"workout_session_id" uuid,
	"caption" text,
	"media_url" text,
	"visibility" varchar(20) DEFAULT 'public' NOT NULL,
	"kudos_count" integer DEFAULT 0 NOT NULL,
	"comments_count" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "exercises" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(150) NOT NULL,
	"category" varchar(50) NOT NULL,
	"primary_muscle" varchar(50) NOT NULL,
	"secondary_muscles" text[] DEFAULT '{}' NOT NULL,
	"equipment" varchar(50) NOT NULL,
	"instructions" text NOT NULL,
	"video_url" text,
	"thumbnail_url" text,
	"contraindications" text[] DEFAULT '{}' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "fitness_assessments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"version" integer DEFAULT 1 NOT NULL,
	"status" varchar(32) DEFAULT 'in_progress' NOT NULL,
	"last_active_stage" varchar(20) DEFAULT 'STAGE_A',
	"responses" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"started_at" timestamp with time zone DEFAULT now() NOT NULL,
	"completed_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "fitness_challenges" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"title" varchar(150) NOT NULL,
	"description" text NOT NULL,
	"challenge_type" varchar(50) NOT NULL,
	"target_value" numeric(10, 2) NOT NULL,
	"unit" varchar(32) NOT NULL,
	"start_date" date NOT NULL,
	"end_date" date NOT NULL,
	"badge_icon_url" text,
	"is_public" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "fitness_goals" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"goal_type" varchar(50) NOT NULL,
	"priority" varchar(20) DEFAULT 'primary' NOT NULL,
	"target_value" numeric(8, 2),
	"current_value" numeric(8, 2),
	"unit" varchar(32),
	"target_date" date,
	"status" varchar(32) DEFAULT 'active' NOT NULL,
	"strategy_notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "fitness_pathways" (
	"id" varchar(50) PRIMARY KEY NOT NULL,
	"name" varchar(100) NOT NULL,
	"description" text NOT NULL,
	"primary_focus" text NOT NULL,
	"nutrition_focus" text NOT NULL,
	"progression_rules" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "fitness_profiles" (
	"user_id" uuid PRIMARY KEY NOT NULL,
	"primary_goal" varchar(50) NOT NULL,
	"experience" varchar(20) NOT NULL,
	"activity_baseline" varchar(30) NOT NULL,
	"training_environment" varchar(20) NOT NULL,
	"availability_level" varchar(20) NOT NULL,
	"safety_status" varchar(50) NOT NULL,
	"classification_badge" varchar(50),
	"bmr_calories" integer,
	"tdee_calories" integer,
	"target_daily_calories" integer,
	"last_calculated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "fitness_recommendations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"run_id" uuid NOT NULL,
	"activity_id" uuid NOT NULL,
	"activity_type" varchar(50) NOT NULL,
	"priority" varchar(20) NOT NULL,
	"score" numeric(5, 2) NOT NULL,
	"score_breakdown" jsonb NOT NULL,
	"explanation" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "food_catalog" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(200) NOT NULL,
	"brand" varchar(100),
	"serving_size_grams" numeric(8, 2) NOT NULL,
	"serving_unit" varchar(50) DEFAULT 'g' NOT NULL,
	"calories" numeric(8, 2) NOT NULL,
	"protein_grams" numeric(8, 2) DEFAULT '0' NOT NULL,
	"carbs_grams" numeric(8, 2) DEFAULT '0' NOT NULL,
	"fat_grams" numeric(8, 2) DEFAULT '0' NOT NULL,
	"fiber_grams" numeric(8, 2) DEFAULT '0',
	"source" varchar(50) DEFAULT 'verified_nigerian' NOT NULL,
	"confidence_score" numeric(3, 2) DEFAULT '0.95' NOT NULL,
	"barcode" varchar(64),
	"is_verified_nigerian" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "food_portion_units" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"foodId" uuid NOT NULL,
	"unit_name" varchar(50) NOT NULL,
	"gram_weight_ratio" numeric(8, 2) NOT NULL,
	"is_local_measure" boolean DEFAULT true NOT NULL,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "health_restrictions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"restriction_type" varchar(50) NOT NULL,
	"affected_body_parts" text[],
	"medical_clearance_obtained" boolean DEFAULT false NOT NULL,
	"encrypted_notes" text,
	"is_critical_stop" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "notification_preferences" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"workout_reminders" boolean DEFAULT true NOT NULL,
	"workout_reminder_time" varchar(10) DEFAULT '07:00' NOT NULL,
	"nutrition_nudges" boolean DEFAULT true NOT NULL,
	"weekly_review_prompt" boolean DEFAULT true NOT NULL,
	"social_cheers" boolean DEFAULT true NOT NULL,
	"quiet_hours_start" varchar(10) DEFAULT '22:00',
	"quiet_hours_end" varchar(10) DEFAULT '06:00',
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "notification_preferences_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
CREATE TABLE "nutrition_entries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"food_id" uuid NOT NULL,
	"logged_date" date NOT NULL,
	"meal_slot" varchar(20) NOT NULL,
	"quantity" numeric(6, 2) NOT NULL,
	"portion_unit_id" uuid,
	"total_calories" numeric(8, 2) NOT NULL,
	"total_protein_g" numeric(8, 2) NOT NULL,
	"total_carbs_g" numeric(8, 2) NOT NULL,
	"total_fat_g" numeric(8, 2) NOT NULL,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "progress_records" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"metric_type" varchar(50) NOT NULL,
	"metric_value" numeric(10, 2) NOT NULL,
	"unit" varchar(32) NOT NULL,
	"notes" text,
	"recorded_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "recommendation_runs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"assessment_id" uuid,
	"algorithm_version" varchar(20) DEFAULT '1.0.0' NOT NULL,
	"input_snapshot" jsonb NOT NULL,
	"generated_plan" jsonb NOT NULL,
	"requires_professional_guidance" boolean DEFAULT false NOT NULL,
	"safety_status" varchar(50) NOT NULL,
	"user_can_customize" boolean DEFAULT true NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "subscriptions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"plan_id" varchar(50) NOT NULL,
	"status" varchar(32) DEFAULT 'active' NOT NULL,
	"provider" varchar(32) DEFAULT 'paystack' NOT NULL,
	"provider_subscription_id" varchar(150),
	"provider_customer_code" varchar(150),
	"current_period_start" timestamp with time zone,
	"current_period_end" timestamp with time zone,
	"cancel_at_period_end" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "sync_idempotency_records" (
	"idempotency_key" varchar(128) PRIMARY KEY NOT NULL,
	"user_id" uuid NOT NULL,
	"endpoint" varchar(150) NOT NULL,
	"response_status" integer NOT NULL,
	"response_body" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE TABLE "sync_quarantine" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"mutation_type" varchar(50) NOT NULL,
	"payload" jsonb NOT NULL,
	"error_message" text NOT NULL,
	"resolved" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_consents" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"consent_type" varchar(50) NOT NULL,
	"granted" boolean DEFAULT true NOT NULL,
	"ip_address_hash" varchar(64) NOT NULL,
	"policy_version" varchar(20) NOT NULL,
	"granted_at" timestamp with time zone DEFAULT now() NOT NULL,
	"revoked_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "user_feedback" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"recommendation_id" uuid,
	"session_id" uuid,
	"feedback_type" varchar(50) NOT NULL,
	"rating" integer,
	"comment" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_privacy_zones" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"label" varchar(50) NOT NULL,
	"center_latitude" numeric(10, 7) NOT NULL,
	"center_longitude" numeric(10, 7) NOT NULL,
	"radius_meters" integer DEFAULT 250 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_profiles" (
	"user_id" uuid PRIMARY KEY NOT NULL,
	"first_name" varchar(100),
	"last_name" varchar(100),
	"date_of_birth" date NOT NULL,
	"biological_sex" varchar(20),
	"height_cm" numeric(5, 2),
	"weight_kg" numeric(5, 2),
	"country_code" varchar(2) DEFAULT 'NG' NOT NULL,
	"unit_system" varchar(20) DEFAULT 'metric' NOT NULL,
	"timezone" varchar(50) DEFAULT 'Africa/Lagos' NOT NULL,
	"avatar_url" text,
	"fcm_token" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" varchar(255) NOT NULL,
	"password_hash" varchar(255),
	"role" varchar(32) DEFAULT 'user' NOT NULL,
	"status" varchar(32) DEFAULT 'active' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
CREATE TABLE "workout_programs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"title" varchar(150) NOT NULL,
	"description" text NOT NULL,
	"pathway_id" varchar(50),
	"goal" varchar(50) NOT NULL,
	"difficulty_level" varchar(20) NOT NULL,
	"duration_weeks" integer DEFAULT 4 NOT NULL,
	"days_per_week" integer DEFAULT 3 NOT NULL,
	"is_premium" boolean DEFAULT false NOT NULL,
	"author_id" uuid,
	"cover_image_url" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "workout_sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"program_id" uuid,
	"user_id" uuid NOT NULL,
	"title" varchar(150) NOT NULL,
	"scheduled_date" date NOT NULL,
	"status" varchar(32) DEFAULT 'scheduled' NOT NULL,
	"started_at" timestamp with time zone,
	"completed_at" timestamp with time zone,
	"total_duration_seconds" integer DEFAULT 0 NOT NULL,
	"total_volume_kg" numeric(10, 2) DEFAULT '0' NOT NULL,
	"rpe" integer,
	"notes" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "workout_sets" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"session_id" uuid NOT NULL,
	"exercise_id" uuid NOT NULL,
	"set_order" integer NOT NULL,
	"set_type" varchar(20) DEFAULT 'normal' NOT NULL,
	"reps" integer NOT NULL,
	"weight_kg" numeric(6, 2) DEFAULT '0' NOT NULL,
	"rpe" numeric(3, 1),
	"is_completed" boolean DEFAULT true NOT NULL,
	"is_personal_record" boolean DEFAULT false NOT NULL,
	"rest_seconds_after" integer DEFAULT 60,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "activity_routes" ADD CONSTRAINT "activity_routes_activity_id_activity_sessions_id_fk" FOREIGN KEY ("activity_id") REFERENCES "public"."activity_sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "activity_sessions" ADD CONSTRAINT "activity_sessions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "assessment_options" ADD CONSTRAINT "assessment_options_question_id_assessment_questions_id_fk" FOREIGN KEY ("question_id") REFERENCES "public"."assessment_questions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "assessment_responses" ADD CONSTRAINT "assessment_responses_assessment_id_fitness_assessments_id_fk" FOREIGN KEY ("assessment_id") REFERENCES "public"."fitness_assessments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "assessment_responses" ADD CONSTRAINT "assessment_responses_question_id_assessment_questions_id_fk" FOREIGN KEY ("question_id") REFERENCES "public"."assessment_questions"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "billing_transactions" ADD CONSTRAINT "billing_transactions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "billing_transactions" ADD CONSTRAINT "billing_transactions_subscription_id_subscriptions_id_fk" FOREIGN KEY ("subscription_id") REFERENCES "public"."subscriptions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "challenge_participants" ADD CONSTRAINT "challenge_participants_challenge_id_fitness_challenges_id_fk" FOREIGN KEY ("challenge_id") REFERENCES "public"."fitness_challenges"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "challenge_participants" ADD CONSTRAINT "challenge_participants_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "community_comments" ADD CONSTRAINT "community_comments_post_id_community_posts_id_fk" FOREIGN KEY ("post_id") REFERENCES "public"."community_posts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "community_comments" ADD CONSTRAINT "community_comments_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "community_kudos" ADD CONSTRAINT "community_kudos_post_id_community_posts_id_fk" FOREIGN KEY ("post_id") REFERENCES "public"."community_posts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "community_kudos" ADD CONSTRAINT "community_kudos_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "community_posts" ADD CONSTRAINT "community_posts_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "community_posts" ADD CONSTRAINT "community_posts_activity_session_id_activity_sessions_id_fk" FOREIGN KEY ("activity_session_id") REFERENCES "public"."activity_sessions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "community_posts" ADD CONSTRAINT "community_posts_workout_session_id_workout_sessions_id_fk" FOREIGN KEY ("workout_session_id") REFERENCES "public"."workout_sessions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fitness_assessments" ADD CONSTRAINT "fitness_assessments_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fitness_goals" ADD CONSTRAINT "fitness_goals_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fitness_profiles" ADD CONSTRAINT "fitness_profiles_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fitness_recommendations" ADD CONSTRAINT "fitness_recommendations_run_id_recommendation_runs_id_fk" FOREIGN KEY ("run_id") REFERENCES "public"."recommendation_runs"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fitness_recommendations" ADD CONSTRAINT "fitness_recommendations_activity_id_activity_catalog_id_fk" FOREIGN KEY ("activity_id") REFERENCES "public"."activity_catalog"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "food_portion_units" ADD CONSTRAINT "food_portion_units_foodId_food_catalog_id_fk" FOREIGN KEY ("foodId") REFERENCES "public"."food_catalog"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "health_restrictions" ADD CONSTRAINT "health_restrictions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notification_preferences" ADD CONSTRAINT "notification_preferences_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "nutrition_entries" ADD CONSTRAINT "nutrition_entries_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "nutrition_entries" ADD CONSTRAINT "nutrition_entries_food_id_food_catalog_id_fk" FOREIGN KEY ("food_id") REFERENCES "public"."food_catalog"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "nutrition_entries" ADD CONSTRAINT "nutrition_entries_portion_unit_id_food_portion_units_id_fk" FOREIGN KEY ("portion_unit_id") REFERENCES "public"."food_portion_units"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "progress_records" ADD CONSTRAINT "progress_records_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recommendation_runs" ADD CONSTRAINT "recommendation_runs_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recommendation_runs" ADD CONSTRAINT "recommendation_runs_assessment_id_fitness_assessments_id_fk" FOREIGN KEY ("assessment_id") REFERENCES "public"."fitness_assessments"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sync_idempotency_records" ADD CONSTRAINT "sync_idempotency_records_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sync_quarantine" ADD CONSTRAINT "sync_quarantine_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_consents" ADD CONSTRAINT "user_consents_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_feedback" ADD CONSTRAINT "user_feedback_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_feedback" ADD CONSTRAINT "user_feedback_recommendation_id_recommendation_runs_id_fk" FOREIGN KEY ("recommendation_id") REFERENCES "public"."recommendation_runs"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_feedback" ADD CONSTRAINT "user_feedback_session_id_workout_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."workout_sessions"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_privacy_zones" ADD CONSTRAINT "user_privacy_zones_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_profiles" ADD CONSTRAINT "user_profiles_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "workout_programs" ADD CONSTRAINT "workout_programs_pathway_id_fitness_pathways_id_fk" FOREIGN KEY ("pathway_id") REFERENCES "public"."fitness_pathways"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "workout_programs" ADD CONSTRAINT "workout_programs_author_id_users_id_fk" FOREIGN KEY ("author_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "workout_sessions" ADD CONSTRAINT "workout_sessions_program_id_workout_programs_id_fk" FOREIGN KEY ("program_id") REFERENCES "public"."workout_programs"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "workout_sessions" ADD CONSTRAINT "workout_sessions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "workout_sets" ADD CONSTRAINT "workout_sets_session_id_workout_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."workout_sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "workout_sets" ADD CONSTRAINT "workout_sets_exercise_id_exercises_id_fk" FOREIGN KEY ("exercise_id") REFERENCES "public"."exercises"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "idx_activity_catalog_goal" ON "activity_catalog" USING btree ("primary_goal");--> statement-breakpoint
CREATE INDEX "idx_activity_catalog_code" ON "activity_catalog" USING btree ("code");--> statement-breakpoint
CREATE INDEX "idx_activity_sessions_user_time" ON "activity_sessions" USING btree ("user_id","started_at");--> statement-breakpoint
CREATE INDEX "idx_assessment_options_question_order" ON "assessment_options" USING btree ("question_id","display_order");--> statement-breakpoint
CREATE INDEX "idx_assessment_questions_stage_order" ON "assessment_questions" USING btree ("stage","display_order");--> statement-breakpoint
CREATE INDEX "idx_assessment_questions_active" ON "assessment_questions" USING btree ("is_active");--> statement-breakpoint
CREATE INDEX "idx_assessment_responses_assessment" ON "assessment_responses" USING btree ("assessment_id");--> statement-breakpoint
CREATE INDEX "idx_assessment_responses_question" ON "assessment_responses" USING btree ("question_id");--> statement-breakpoint
CREATE INDEX "idx_audit_logs_user_time" ON "audit_logs" USING btree ("user_id","created_at");--> statement-breakpoint
CREATE INDEX "idx_billing_transactions_user" ON "billing_transactions" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idx_billing_transactions_reference" ON "billing_transactions" USING btree ("provider_reference");--> statement-breakpoint
CREATE INDEX "idx_community_comments_post" ON "community_comments" USING btree ("post_id");--> statement-breakpoint
CREATE INDEX "idx_community_posts_user_time" ON "community_posts" USING btree ("user_id","created_at");--> statement-breakpoint
CREATE INDEX "idx_exercises_category" ON "exercises" USING btree ("category");--> statement-breakpoint
CREATE INDEX "idx_exercises_equipment" ON "exercises" USING btree ("equipment");--> statement-breakpoint
CREATE INDEX "idx_fitness_assessments_user_version" ON "fitness_assessments" USING btree ("user_id","version");--> statement-breakpoint
CREATE INDEX "idx_fitness_goals_user_status" ON "fitness_goals" USING btree ("user_id","status");--> statement-breakpoint
CREATE INDEX "idx_fitness_goals_user_priority" ON "fitness_goals" USING btree ("user_id","priority");--> statement-breakpoint
CREATE INDEX "idx_fitness_recommendations_run" ON "fitness_recommendations" USING btree ("run_id");--> statement-breakpoint
CREATE INDEX "idx_food_catalog_name" ON "food_catalog" USING btree ("name");--> statement-breakpoint
CREATE INDEX "idx_food_catalog_barcode" ON "food_catalog" USING btree ("barcode");--> statement-breakpoint
CREATE INDEX "idx_food_portion_units_food" ON "food_portion_units" USING btree ("foodId");--> statement-breakpoint
CREATE INDEX "idx_health_restrictions_user" ON "health_restrictions" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idx_nutrition_entries_user_date" ON "nutrition_entries" USING btree ("user_id","logged_date");--> statement-breakpoint
CREATE INDEX "idx_progress_records_user_metric" ON "progress_records" USING btree ("user_id","metric_type","recorded_at");--> statement-breakpoint
CREATE INDEX "idx_recommendation_runs_user" ON "recommendation_runs" USING btree ("user_id","is_active");--> statement-breakpoint
CREATE INDEX "idx_subscriptions_user_status" ON "subscriptions" USING btree ("user_id","status");--> statement-breakpoint
CREATE INDEX "idx_sync_idempotency_expiry" ON "sync_idempotency_records" USING btree ("expires_at");--> statement-breakpoint
CREATE INDEX "idx_user_consents_user_type" ON "user_consents" USING btree ("user_id","consent_type");--> statement-breakpoint
CREATE INDEX "idx_user_feedback_user" ON "user_feedback" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idx_user_privacy_zones_user" ON "user_privacy_zones" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idx_workout_sessions_user_date" ON "workout_sessions" USING btree ("user_id","scheduled_date");--> statement-breakpoint
CREATE INDEX "idx_workout_sessions_status" ON "workout_sessions" USING btree ("status");--> statement-breakpoint
CREATE INDEX "idx_workout_sets_session" ON "workout_sets" USING btree ("session_id");--> statement-breakpoint
CREATE INDEX "idx_workout_sets_exercise" ON "workout_sets" USING btree ("exercise_id");