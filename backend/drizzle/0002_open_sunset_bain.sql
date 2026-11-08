CREATE TABLE IF NOT EXISTS "coach_profiles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"full_name" varchar(150) NOT NULL,
	"bio" text NOT NULL,
	"specialties" jsonb NOT NULL,
	"experience_years" integer DEFAULT 1 NOT NULL,
	"accreditation_body" varchar(100) NOT NULL,
	"license_number" varchar(100) NOT NULL,
	"certificate_url" varchar(500),
	"government_id_url" varchar(500),
	"id_type" varchar(50) DEFAULT 'NIN' NOT NULL,
	"id_number" varchar(100) NOT NULL,
	"verification_status" varchar(32) DEFAULT 'pending' NOT NULL,
	"verified_at" timestamp with time zone,
	"rejection_reason" text,
	"verified_by" uuid,
	"bank_code" varchar(10) NOT NULL,
	"bank_name" varchar(100) NOT NULL,
	"account_number" varchar(10) NOT NULL,
	"account_name" varchar(150) NOT NULL,
	"paystack_recipient_code" varchar(100),
	"monthly_retainer_ngn" integer DEFAULT 25000 NOT NULL,
	"ndpa_dpa_accepted" boolean DEFAULT false NOT NULL,
	"ndpa_dpa_accepted_at" timestamp with time zone,
	"is_active" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "coach_profiles_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
DO $$ BEGIN
  ALTER TABLE "coach_profiles" ADD CONSTRAINT "coach_profiles_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
  WHEN duplicate_table THEN NULL;
  WHEN duplicate_object THEN NULL;
END $$;
--> statement-breakpoint
DO $$ BEGIN
  ALTER TABLE "coach_profiles" ADD CONSTRAINT "coach_profiles_verified_by_users_id_fk" FOREIGN KEY ("verified_by") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
  WHEN duplicate_table THEN NULL;
  WHEN duplicate_object THEN NULL;
END $$;
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_coach_profiles_verification" ON "coach_profiles" USING btree ("verification_status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_coach_profiles_active" ON "coach_profiles" USING btree ("is_active");
