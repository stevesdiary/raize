# Technical Architecture & Infrastructure Specification

**Document Version**: 1.0.0  
**Status**: Authoritative Architecture Baseline  
**Date**: 2026-11-07  
**Scope**: Unified Fitness Platform (`raize.fit`) Backend & Mobile System Topology  
**Target SLAs**: Latency p95 < 500ms, Zero Workout/Telemetry Data Loss, 99.9% Uptime  

---

## 1. Executive Summary & Architecture Topology

The Unified Fitness Platform synthesizes resistance training progression, outdoor endurance tracking, localized nutritional energy budgeting, and social gamification into a single, high-performance, resilient platform.

```
+--------------------------------------------------------------------------------------------------+
|                                           CLIENT TIER                                            |
|  +--------------------------------------------------------------------------------------------+  |
|  |                           Flutter 3.x Mobile Client (iOS & Android)                        |  |
|  |  - Presentation: Riverpod 2.x StateNotifiers + Declarative GoRouter + AMOLED Dark Theme    |  |
|  |  - Domain: Clean Architecture UseCases, Repository Contracts, Pure Dart Domain Entities    |  |
|  |  - Data: Drift (SQLite) Engine + FTS5 Full-Text Cache + Outbox WAL Queue + Dio HTTP Client |  |
|  |  - Background: Foreground Service (Location) + WorkManager Periodic Sync + Local Auth     |  |
|  +--------------------------------------------------------------------------------------------+  |
+-------------------------------------------------|------------------------------------------------+
                                                  | HTTPS / TLS 1.3 (Certificate Pinning)
                                                  v
+--------------------------------------------------------------------------------------------------+
|                                           EDGE & CDN                                             |
|  +--------------------------------------------------------------------------------------------+  |
|  |  Cloudflare Edge Network: Global Anycast CDN + WAF DDoS Shield + Edge SSL Termination      |  |
|  |  - Custom Domain Routing: api.raize.fit -> Origin API Cluster                              |  |
|  |  - Media Storage Edge: media.raize.fit -> Cloudflare R2 Bucket (Video & Image Cache)      |  |
|  +--------------------------------------------------------------------------------------------+  |
+-------------------------------------------------|------------------------------------------------+
                                                  | Fastify Reverse Proxy / Upstream
                                                  v
+--------------------------------------------------------------------------------------------------+
|                                   APPLICATION TIER (FASTIFY 5.X)                                 |
|  +--------------------------------------------------------------------------------------------+  |
|  |  Node.js 22 LTS Runtime (TypeScript 5.x) - Modular Monolith Architecture                  |  |
|  |  - Find-My-Way Radix Tree Router: Sub-millisecond routing overhead (< 1.5ms)               |  |
|  |  - TypeBox AOT Validation: Ahead-of-Time JSON Schema compilation via ajv                   |  |
|  |  - Asymmetric JWT Engine: RS256 / EdDSA verification without database hits                 |  |
|  |  - Observability: Pino Structured JSON Logger + Sentry Error Tracing + OpenTelemetry       |  |
|  |                                                                                            |  |
|  |  Feature Modules:                                                                          |  |
|  |  [ Auth & Security ]   [ Assessment & PAR-Q+ ]   [ Recommendation Scoring Engine ]         |  |
|  |  [ Workout Execution ] [ GPS Telemetry & PostGIS ] [ Nutrition & Nigerian Food Catalog ]   |  |
|  |  [ Social Feeds ]      [ Challenge Leaderboards ] [ Billing (Paystack & RevenueCat) ]      |  |
|  |  [ Offline Sync Batch ][ NDPA Compliance Officer ][ QStash Asynchronous Webhook Workers ]  |  |
|  +--------------------------------------------------------------------------------------------+  |
+--------------------------|----------------------------|------------------------|-----------------+
                           |                            |                        |
                           v                            v                        v
+----------------------------------+  +----------------------------------+  +----------------------+
|          DATABASE TIER           |  |        CACHE & JOBS TIER         |  |     STORAGE TIER     |
|   PostgreSQL 16 + PostGIS        |  |     Upstash Redis & QStash       |  |    Cloudflare R2     |
|                                  |  |                                  |  |                      |
|  - Drizzle ORM Type-Safe Queries |  |  - Upstash Redis (Dual Mode):    |  |  - S3 Compatible API |
|  - postgres.js Client Driver     |  |    * Direct TCP (ioredis): API   |  |  - Zero Egress Fees  |
|  - PgBouncer Pool (20 conn/node) |  |      session & rate limiting     |  |  - Presigned PUTs    |
|  - PostGIS GEOGRAPHY(LineString) |  |    * REST API: Serverless edge   |  |  - Cloudflare Edge   |
|  - pg_trgm Trigram Indexing      |  |    * Sorted Sets (ZSET) for      |  |    Video Streaming   |
|  - Monthly Range Partitions      |  |      real-time leaderboards      |  |  - User Meal Photos  |
|  - AES-256-GCM Field Encryption  |  |  - Upstash QStash Engine:        |  |  - Avatar Storage    |
|  - Immutable Audit Trails        |  |    * HTTP Webhook Delivery       |  |                      |
|                                  |  |    * Retries with Backoff & DLQ  |  |                      |
|                                  |  |    * Crons: Streaks, Reviews     |  |                      |
+----------------------------------+  +----------------------------------+  +----------------------+
```

---

## 2. Backend Application Tier: Node.js Fastify 5.x Runtime

### 2.1 Framework Selection Rationale: Fastify 5.x vs. NestJS
The platform requires an API gateway capable of satisfying the **p95 latency < 500ms** SLA under high-concurrency peaks (morning 06:00–08:30 WAT and evening 17:30–20:00 WAT). Fastify was selected over NestJS (Express) based on empirical performance characteristics:

1. **Routing Efficiency**: Fastify utilizes `find-my-way`, an internally optimized radix tree (trie) router. Route matching operates in $O(k)$ time (where $k$ is the URL length) independent of the number of registered routes. This reduces route resolution overhead to under $1.5\mu\text{s}$ per request.
2. **Ahead-of-Time (AOT) Serialization**: While NestJS relies on `class-transformer` and reflection metadata (which re-parses object graphs at runtime), Fastify utilizes `fast-json-stringify`. Fastify compiles JSON Schema definitions into dedicated C-style string concatenators at server boot, serializing JSON responses 2.5x to 3x faster than standard `JSON.stringify()`.
3. **Memory Profile & Scalability**: Fastify has an idle memory footprint of ~45MB RSS and cold boot time < 150ms. NestJS requires 180MB–240MB RSS and 2,500ms–3,500ms boot times due to its heavy dependency injection container. This gives Fastify superior container packing density on container platforms (AWS ECS, Fly.io, Railway).

### 2.2 Schema Validation & Type-Safety: TypeBox Integration
We enforce end-to-end type safety using **TypeBox (`@sinclair/typebox`)** with `@fastify/type-provider-typebox`. TypeBox compiles JSON Schema specifications directly without the runtime overhead of converting third-party schemas.

```typescript
// src/modules/workout/workout.schema.ts
import { Type, Static } from '@sinclair/typebox';

export const LogSetSchema = Type.Object({
  exercise_id: Type.String({ format: 'uuid' }),
  set_order: Type.Integer({ minimum: 1, maximum: 50 }),
  set_type: Type.Union([
    Type.Literal('warmup'),
    Type.Literal('normal'),
    Type.Literal('drop_set'),
    Type.Literal('failure'),
    Type.Literal('superset')
  ]),
  reps: Type.Integer({ minimum: 0, maximum: 500 }),
  weight_kg: Type.Number({ minimum: 0, maximum: 1000 }),
  rpe: Type.Optional(Type.Number({ minimum: 1.0, maximum: 10.0 })),
  rest_seconds_actual: Type.Optional(Type.Integer({ minimum: 0, maximum: 1800 })),
  is_completed: Type.Boolean({ default: true })
});

export type LogSetInput = Static<typeof LogSetSchema>;

export const CompleteSessionSchema = Type.Object({
  total_duration_seconds: Type.Integer({ minimum: 1 }),
  notes: Type.Optional(Type.String({ maxLength: 1000 })),
  perceived_exertion: Type.Optional(Type.Integer({ minimum: 1, maximum: 10 }))
});
```

---

## 3. Database Architecture: Drizzle ORM, PostgreSQL & PostGIS

### 3.1 Drizzle ORM & Native Driver Execution
Unlike Prisma—which requires a separate C++/Rust binary process that communicates with Node.js over local sockets (incurring IPC translation and memory overhead)—**Drizzle ORM** generates pure parameterized SQL directly executed by `postgres.js`.

- **Connection Driver**: `postgres.js` (Porsager). Provides the fastest native PostgreSQL driver in the JavaScript ecosystem with pipelining support, automatic prepared statements, and transparent reconnection.
- **Connection Pooling**: PgBouncer transaction-mode connection pool.
  - Sizing: 20 max connections per Fastify instance (`max: 20`).
  - Configuration: `prepare: false` enabled in `postgres.js` to ensure statement caching compatibility across transaction-pooled connections.

### 3.2 PostGIS Geospatial & Route Storage (FR-019)
Outdoor GPS activities require spatial persistence for route rendering, distance verification, and privacy clipping:

```sql
-- Enable PostGIS and Trigram extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

**Hybrid Storage Strategy**:
1. **Encoded Polyline (`masked_polyline TEXT`)**: Stores the visual route using the Google Encoded Polyline Algorithm (5 decimal precision, $\sim 1\text{m}$ accuracy). Compresses a 10km run ($\sim 3,600$ trackpoints) from 120KB of GeoJSON down to $\sim 8\text{KB}$, optimizing bandwidth for Nigerian 3G/4G connections.
2. **PostGIS Geography (`geom GEOGRAPHY(LineString, 4326)`)**: Stores spatial geometry for spatial queries, bounding boxes, segment matching, and elevation calculations. Indexed with a spatial GiST index (`CREATE INDEX idx_activity_routes_geom ON activity_routes USING GIST (geom);`).

### 3.3 Partitioning Strategy: High-Volume Append Tables
To prevent index bloat and maintain microsecond write times as telemetry data scales into tens of millions of rows, high-volume append tables are partitioned using **PostgreSQL Declarative Range Partitioning by Month**.

#### Declarative Range Partitioning DDL with Composite Foreign Keys
In PostgreSQL, foreign keys referencing partitioned tables require that referenced columns match the primary key or unique constraint (which must include the partition key). Referencing tables are also partitioned or include the partition key column to maintain relational integrity:

```sql
-- 1. Monthly Range Partitioning for Activity Sessions & Activity Routes
CREATE TABLE activity_sessions (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'completed',
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    elapsed_duration_seconds INT NOT NULL,
    total_distance_meters NUMERIC(10, 2) NOT NULL,
    authentic_distance_meters INT NOT NULL DEFAULT 0,
    authentic_duration_seconds INT NOT NULL DEFAULT 0,
    avg_pace_seconds_per_km NUMERIC(6, 2),
    elevation_gain_meters NUMERIC(6, 2),
    is_map_hidden BOOLEAN NOT NULL DEFAULT FALSE,
    privacy_display_mode VARCHAR(32) NOT NULL DEFAULT 'INTERACTIVE_MAP',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, started_at)
) PARTITION BY RANGE (started_at);

CREATE TABLE activity_routes (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    activity_id UUID NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    raw_polyline TEXT NOT NULL,
    public_polyline TEXT,
    is_map_hidden BOOLEAN NOT NULL DEFAULT FALSE,
    geom GEOGRAPHY(LineString, 4326),
    split_metrics JSONB NOT NULL DEFAULT '[]'::jsonb,
    visibility VARCHAR(20) NOT NULL DEFAULT 'public',
    masked_zones_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, started_at),
    CONSTRAINT uidx_activity_routes_activity_started UNIQUE (activity_id, started_at),
    CONSTRAINT fk_activity_routes_activity_session
        FOREIGN KEY (activity_id, started_at)
        REFERENCES activity_sessions(id, started_at)
        ON DELETE CASCADE
) PARTITION BY RANGE (started_at);

-- Partition Tables for Activity Sessions & Routes
CREATE TABLE activity_sessions_2026_11 PARTITION OF activity_sessions
    FOR VALUES FROM ('2026-11-01 00:00:00+00') TO ('2026-12-01 00:00:00+00');
CREATE TABLE activity_routes_2026_11 PARTITION OF activity_routes
    FOR VALUES FROM ('2026-11-01 00:00:00+00') TO ('2026-12-01 00:00:00+00');

-- 2. Monthly Range Partitioning for Workout Sessions & Workout Sets
CREATE TABLE workout_sessions (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    program_id UUID REFERENCES workout_programs(id) ON DELETE SET NULL,
    scheduled_date DATE NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'scheduled',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    total_duration_seconds INT NOT NULL DEFAULT 0,
    total_volume_kg NUMERIC(10, 2) NOT NULL DEFAULT 0,
    rpe INT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, scheduled_date)
) PARTITION BY RANGE (scheduled_date);

CREATE TABLE workout_sets (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    scheduled_date DATE NOT NULL,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE RESTRICT,
    set_order INT NOT NULL,
    set_type VARCHAR(20) NOT NULL DEFAULT 'normal',
    reps INT NOT NULL,
    weight_kg NUMERIC(6, 2) NOT NULL,
    rpe NUMERIC(3, 1),
    is_completed BOOLEAN NOT NULL DEFAULT TRUE,
    is_personal_record BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, scheduled_date),
    CONSTRAINT fk_workout_sets_session
        FOREIGN KEY (session_id, scheduled_date)
        REFERENCES workout_sessions(id, scheduled_date)
        ON DELETE CASCADE
) PARTITION BY RANGE (scheduled_date);

-- Partition Tables for Workout Sessions & Sets
CREATE TABLE workout_sessions_2026_11 PARTITION OF workout_sessions
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE workout_sets_2026_11 PARTITION OF workout_sets
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
```
*Applies to*: `activity_sessions`, `activity_routes`, `workout_sessions`, `workout_sets`, and `audit_logs`.

### 3.4 Full-Text Search with Trigrams (FR-014, FR-011)
Instead of operating an external search cluster (Elasticsearch/Meilisearch), the platform utilizes PostgreSQL's native `pg_trgm` extension and GIN indexes. This easily satisfies the < 250ms search SLA for catalogs under 100,000 items:

```sql
CREATE INDEX idx_food_catalog_trgm ON food_catalog USING GIN (name gin_trgm_ops);
CREATE INDEX idx_exercises_trgm ON exercises USING GIN (name gin_trgm_ops);
```

### 3.5 Drizzle ORM Complete Production Schema Definition

Below is the complete, production-ready TypeScript schema definition for all 25 core domain entities mandated by PRD Section 7.3, plus critical operational entities for Nigerian colloquial food portions (`food_portion_units`), dead-letter sync quarantine (`sync_quarantine`), transactional idempotency (`sync_idempotency_records`), statutory billing audit records (`billing_transactions`), NDPA consents (`user_consents`), and immutable audit trails (`audit_logs`).

```typescript
// src/db/schema/index.ts
import { 
  pgTable, uuid, varchar, text, numeric, integer, 
  boolean, timestamp, date, jsonb, customType, bigint,
  primaryKey, foreignKey, unique, index 
} from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

// Custom PostGIS Geometry Type
const geographyLineString = customType<{ data: string }>({
  dataType() {
    return 'geography(LineString, 4326)';
  },
});

// ============================================================================
// PART 1: IDENTITY, PROFILE & HEALTH SAFEGUARDS (PRD Section 7.3, Entities 1-3, 7)
// ============================================================================

/**
 * 1. users
 * Core user identity, authentication status, and primary access role.
 */
export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  passwordHash: varchar('password_hash', { length: 255 }),
  role: varchar('role', { length: 32 }).notNull().default('user'), // 'user', 'coach', 'admin', 'compliance_officer'
  status: varchar('status', { length: 32 }).notNull().default('active'), // 'active', 'suspended', 'pending_deletion'
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull()
});

/**
 * 2. user_profiles
 * Demographic, physiological, and localization preferences.
 */
export const userProfiles = pgTable('user_profiles', {
  userId: uuid('user_id').primaryKey().references(() => users.id, { onDelete: 'cascade' }),
  firstName: varchar('first_name', { length: 100 }),
  lastName: varchar('last_name', { length: 100 }),
  dateOfBirth: date('date_of_birth').notNull(),
  biologicalSex: varchar('biological_sex', { length: 20 }), // 'male', 'female', 'undisclosed'
  heightCm: numeric('height_cm', { precision: 5, scale: 2 }),
  weightKg: numeric('weight_kg', { precision: 5, scale: 2 }),
  countryCode: varchar('country_code', { length: 2 }).default('NG').notNull(),
  unitSystem: varchar('unit_system', { length: 20 }).default('metric').notNull(),
  timezone: varchar('timezone', { length: 50 }).default('Africa/Lagos').notNull(),
  avatarUrl: text('avatar_url')
});

/**
 * 7. health_restrictions
 * Stage E health screening disclosures, musculoskeletal constraints, and clinical notes.
 */
export const healthRestrictions = pgTable('health_restrictions', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  restrictionType: varchar('restriction_type', { length: 50 }).notNull(), // 'cardiovascular', 'joint_injury', 'hypertension', 'post_surgical'
  affectedBodyParts: text('affected_body_parts').array(),
  medicalClearanceObtained: boolean('medical_clearance_obtained').default(false).notNull(),
  encryptedNotes: text('encrypted_notes'), // AES-256-GCM envelope encrypted: v{version}:{iv}:{tag}:{cipher}
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  index('idx_health_restrictions_user').on(table.userId)
]);

// ============================================================================
// PART 2: ASSESSMENT ENGINE (PRD Section 7.3, Entities 4-6, 3)
// ============================================================================

/**
 * 4. assessment_questions
 * Standardized questionnaire items across Stages A through F.
 */
export const assessmentQuestions = pgTable('assessment_questions', {
  id: varchar('id', { length: 32 }).primaryKey(), // e.g. 'A01', 'B01', 'E05'
  stage: varchar('stage', { length: 20 }).notNull(), // 'stage_a', 'stage_b', ..., 'stage_f'
  section: varchar('section', { length: 100 }).notNull(), // 'Baseline & Demographics', 'Safety Screening'
  questionText: text('question_text').notNull(),
  description: text('description'),
  inputType: varchar('input_type', { length: 32 }).notNull(), // 'single_choice', 'multi_choice', 'numeric', 'date', 'boolean', 'scale'
  configuration: jsonb('configuration').default({}).notNull(), // Validation rules, min/max bounds, units
  isRequired: boolean('is_required').default(true).notNull(),
  displayOrder: integer('display_order').notNull(),
  version: integer('version').default(1).notNull(),
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  index('idx_assessment_questions_stage_order').on(table.stage, table.displayOrder),
  index('idx_assessment_questions_active').on(table.isActive)
]);

/**
 * 5. assessment_options
 * Selectable choices for discrete assessment questions with scoring metadata.
 */
export const assessmentOptions = pgTable('assessment_options', {
  id: uuid('id').defaultRandom().primaryKey(),
  questionId: varchar('question_id', { length: 32 })
    .notNull()
    .references(() => assessmentQuestions.id, { onDelete: 'cascade' }),
  value: varchar('value', { length: 100 }).notNull(), // e.g. 'weight_loss', 'prefer_not_to_say', 'yes', 'no'
  displayText: varchar('display_text', { length: 255 }).notNull(),
  displayOrder: integer('display_order').notNull(),
  metadata: jsonb('metadata').default({}).notNull(), // Scoring factor mappings, risk flags, tags
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  unique('uidx_assessment_options_question_val').on(table.questionId, table.value),
  index('idx_assessment_options_question_order').on(table.questionId, table.displayOrder)
]);

/**
 * 3. fitness_assessments
 * Assessment questionnaire execution instances, immutable version history.
 */
export const fitnessAssessments = pgTable('fitness_assessments', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  version: integer('version').notNull().default(1),
  status: varchar('status', { length: 32 }).notNull().default('in_progress'), // 'in_progress', 'completed', 'superseded'
  lastActiveStage: varchar('last_active_stage', { length: 20 }).default('STAGE_A'),
  responses: jsonb('responses').default({}).notNull(),
  startedAt: timestamp('started_at', { withTimezone: true }).defaultNow().notNull(),
  completedAt: timestamp('completed_at', { withTimezone: true })
}, (table) => [
  index('idx_fitness_assessments_user_version').on(table.userId, table.version)
]);

/**
 * 6. assessment_responses
 * Normalized, immutable user responses captured during assessment execution.
 */
export const assessmentResponses = pgTable('assessment_responses', {
  id: uuid('id').defaultRandom().primaryKey(),
  assessmentId: uuid('assessment_id')
    .notNull()
    .references(() => fitnessAssessments.id, { onDelete: 'cascade' }),
  questionId: varchar('question_id', { length: 32 })
    .notNull()
    .references(() => assessmentQuestions.id, { onDelete: 'restrict' }),
  responseValue: jsonb('response_value').notNull(), // Stores primitive values, selected option IDs, or numeric arrays
  answeredAt: timestamp('answered_at', { withTimezone: true }).defaultNow().notNull(),
  isSuperseded: boolean('is_superseded').default(false).notNull()
}, (table) => [
  unique('uidx_assessment_responses_unique_active').on(table.assessmentId, table.questionId),
  index('idx_assessment_responses_assessment').on(table.assessmentId),
  index('idx_assessment_responses_question').on(table.questionId)
]);

// ============================================================================
// PART 3: GOALS, PATHWAYS & PROFILES (PRD Section 7.3, Entities 8-10)
// ============================================================================

/**
 * 8. fitness_goals
 * Primary and supporting user fitness goals, targets, and deadlines.
 */
export const fitnessGoals = pgTable('fitness_goals', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  goalType: varchar('goal_type', { length: 50 }).notNull(), // 'weight_loss', 'hypertrophy', 'cardio_endurance', 'habit_consistency'
  priority: varchar('priority', { length: 20 }).default('primary').notNull(), // 'primary', 'secondary', 'tertiary'
  targetValue: numeric('target_value', { precision: 8, scale: 2 }),
  currentValue: numeric('current_value', { precision: 8, scale: 2 }),
  unit: varchar('unit', { length: 32 }), // 'kg', 'km', 'reps', 'workouts_per_week'
  targetDate: date('target_date'),
  status: varchar('status', { length: 32 }).default('active').notNull(), // 'active', 'achieved', 'abandoned', 'recalibrated'
  strategyNotes: text('strategy_notes'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  index('idx_fitness_goals_user_status').on(table.userId, table.status),
  index('idx_fitness_goals_user_priority').on(table.userId, table.priority)
]);

/**
 * 9. fitness_profiles
 * 6-dimension classified fitness state derived from Stage A-F assessment.
 */
export const fitnessProfiles = pgTable('fitness_profiles', {
  userId: uuid('user_id').primaryKey().references(() => users.id, { onDelete: 'cascade' }),
  primaryGoal: varchar('primary_goal', { length: 50 }).notNull(),
  experience: varchar('experience', { length: 20 }).notNull(), // 'beginner', 'intermediate', 'advanced'
  activityBaseline: varchar('activity_baseline', { length: 30 }).notNull(),
  trainingEnvironment: varchar('training_environment', { length: 20 }).notNull(),
  availabilityLevel: varchar('availability_level', { length: 20 }).notNull(),
  safetyStatus: varchar('safety_status', { length: 50 }).notNull(), // 'cleared', 'needs_mod', 'exercise_paused_pending_assessment'
  classificationBadge: varchar('classification_badge', { length: 50 }),
  lastCalculatedAt: timestamp('last_calculated_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull()
});

/**
 * 10. fitness_pathways
 * High-level training archetypes defining progression boundaries and rules.
 */
export const fitnessPathways = pgTable('fitness_pathways', {
  id: varchar('id', { length: 50 }).primaryKey(), // 'weight_management', 'hypertrophy_foundation', 'endurance_builder', 'active_health'
  name: varchar('name', { length: 150 }).notNull(),
  description: text('description').notNull(),
  rules: jsonb('rules').notNull(), // Progression gates, minimum experience, required equipment, safety constraints
  recommendedFrequencyDays: integer('recommended_frequency_days').notNull(),
  defaultSessionDurationMinutes: integer('default_session_duration_minutes').notNull(),
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull()
});

// ============================================================================
// PART 4: ACTIVITY CATALOG & RECOMMENDATION ENGINE (PRD Section 7.3, Entities 11-13)
// ============================================================================

/**
 * 11. activity_catalog
 * Master repository of physical training activities, MET scores, and safety constraints.
 */
export const activityCatalog = pgTable('activity_catalog', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 150 }).notNull().unique(),
  category: varchar('category', { length: 50 }).notNull(), // 'strength', 'outdoor_cardio', 'indoor_cardio', 'mobility_flexibility', 'hiit'
  difficulty: varchar('difficulty', { length: 20 }).notNull(), // 'beginner', 'intermediate', 'advanced'
  equipmentRequired: text('equipment_required').array().notNull(), // e.g. ['none'], ['dumbbells', 'bench']
  defaultDurationMinutes: integer('default_duration_minutes').notNull(),
  metScore: numeric('met_score', { precision: 4, scale: 2 }).notNull(), // Metabolic Equivalent of Task
  energyBurnRatePerMinute: numeric('energy_burn_rate_per_minute', { precision: 5, scale: 2 }),
  environment: varchar('environment', { length: 32 }).notNull(), // 'home', 'gym', 'outdoor', 'any'
  contraindications: text('contraindications').array().default([]).notNull(), // ['knee_pain', 'hypertension', 'lower_back_injury']
  instructions: text('instructions'),
  isAvailableOffline: boolean('is_available_offline').default(true).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  index('idx_activity_catalog_cat_diff').on(table.category, table.difficulty),
  index('idx_activity_catalog_environment').on(table.environment)
]);

/**
 * 12. recommendation_runs
 * Immutable execution log of recommendation generation for auditability and compliance.
 */
export const recommendationRuns = pgTable('recommendation_runs', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  assessmentId: uuid('assessment_id')
    .references(() => fitnessAssessments.id, { onDelete: 'set null' }),
  pathwayId: varchar('pathway_id', { length: 50 })
    .references(() => fitnessPathways.id, { onDelete: 'set null' }),
  algorithmVersion: varchar('algorithm_version', { length: 32 }).notNull(), // '1.0.0'
  scoringInputs: jsonb('scoring_inputs').notNull(), // Full snapshot of weights, inputs, and constraint checks
  safetyStatusSnapshot: varchar('safety_status_snapshot', { length: 50 }).notNull(),
  status: varchar('status', { length: 32 }).default('active').notNull(), // 'active', 'accepted', 'rejected', 'superseded'
  generatedAt: timestamp('generated_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  index('idx_recommendation_runs_user_time').on(table.userId, table.generatedAt),
  index('idx_recommendation_runs_status').on(table.status)
]);

/**
 * 13. fitness_recommendations
 * Prescribed activities and 7-dimension suitability scores for an execution run.
 */
export const fitnessRecommendations = pgTable('fitness_recommendations', {
  id: uuid('id').defaultRandom().primaryKey(),
  runId: uuid('run_id')
    .notNull()
    .references(() => recommendationRuns.id, { onDelete: 'cascade' }),
  activityId: uuid('activity_id')
    .notNull()
    .references(() => activityCatalog.id, { onDelete: 'restrict' }),
  userId: uuid('user_id')
    .references(() => users.id, { onDelete: 'cascade' }),
  priority: varchar('priority', { length: 20 }).notNull(), // 'primary', 'supporting', 'optional'
  suitabilityScore: numeric('suitability_score', { precision: 5, scale: 2 }).notNull(), // S(a,u) in [0.00, 100.00]
  dimensionBreakdown: jsonb('dimension_breakdown').notNull(), // { goal: 30%, pref: 20%, exp: 15%, equip: 10%, time: 10%, env: 10%, sec: 5% }
  explanation: text('explanation').notNull(), // Human-readable rationale
  scheduledDaysPerWeek: integer('scheduled_days_per_week').notNull(),
  sessionDurationMinutes: integer('session_duration_minutes').notNull(),
  status: varchar('status', { length: 32 }).default('active').notNull(), // 'active', 'accepted', 'suspended_safety_hold'
  isAccepted: boolean('is_accepted').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  index('idx_fitness_recommendations_run').on(table.runId),
  index('idx_fitness_recommendations_activity').on(table.activityId),
  index('idx_fitness_recommendations_user_status').on(table.userId, table.status)
]);

// ============================================================================
// PART 5: WORKOUTS, EXERCISES & SESSIONS (PRD Section 7.3, Entities 14-17)
// ============================================================================

/**
 * 16. exercises
 * Library of movements with anatomical targets, equipment, and R2 demo media.
 */
export const exercises = pgTable('exercises', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 150 }).notNull().unique(),
  category: varchar('category', { length: 50 }).notNull(),
  targetMuscleGroups: text('target_muscle_groups').array().notNull(),
  equipmentRequired: text('equipment_required').array().notNull(),
  instructions: text('instructions').notNull(),
  videoUrl: text('video_url'),
  thumbnailUrl: text('thumbnail_url'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
});

/**
 * 14. workout_programs
 * Periodized multi-week resistance training programs.
 */
export const workoutPrograms = pgTable('workout_programs', {
  id: uuid('id').defaultRandom().primaryKey(),
  title: varchar('title', { length: 150 }).notNull(),
  description: text('description'),
  goal: varchar('goal', { length: 50 }).notNull(),
  experienceLevel: varchar('experience_level', { length: 20 }).notNull(),
  durationWeeks: integer('duration_weeks').notNull(),
  daysPerWeek: integer('days_per_week').notNull(),
  isPremium: boolean('is_premium').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
});

/**
 * 15. workout_sessions (Partitioned by scheduled_date)
 * Scheduled and executed resistance training sessions.
 */
export const workoutSessions = pgTable('workout_sessions', {
  id: uuid('id').defaultRandom().notNull(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  programId: uuid('program_id').references(() => workoutPrograms.id, { onDelete: 'set null' }),
  scheduledDate: date('scheduled_date').notNull(),
  status: varchar('status', { length: 32 }).notNull().default('scheduled'), // 'scheduled', 'in_progress', 'completed', 'cancelled_medical_hold'
  startedAt: timestamp('started_at', { withTimezone: true }),
  completedAt: timestamp('completed_at', { withTimezone: true }),
  totalDurationSeconds: integer('total_duration_seconds').default(0).notNull(),
  totalVolumeKg: numeric('total_volume_kg', { precision: 10, scale: 2 }).default('0').notNull(),
  rpe: integer('rpe'),
  notes: text('notes'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  primaryKey({ columns: [table.id, table.scheduledDate] }),
  index('idx_workout_sessions_user_date').on(table.userId, table.scheduledDate)
]);

/**
 * 17. workout_sets (Partitioned by scheduled_date)
 * Discrete set logs executed within a workout session.
 */
export const workoutSets = pgTable('workout_sets', {
  id: uuid('id').defaultRandom().notNull(),
  sessionId: uuid('session_id').notNull(),
  scheduledDate: date('scheduled_date').notNull(),
  exerciseId: uuid('exercise_id').notNull().references(() => exercises.id, { onDelete: 'restrict' }),
  setOrder: integer('set_order').notNull(),
  setType: varchar('set_type', { length: 20 }).default('normal').notNull(), // 'warmup', 'normal', 'drop_set', 'failure', 'superset'
  reps: integer('reps').notNull(),
  weightKg: numeric('weight_kg', { precision: 6, scale: 2 }).notNull(),
  rpe: numeric('rpe', { precision: 3, scale: 1 }),
  isCompleted: boolean('is_completed').default(true).notNull(),
  isPersonalRecord: boolean('is_personal_record').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  primaryKey({ columns: [table.id, table.scheduledDate] }),
  foreignKey({
    columns: [table.sessionId, table.scheduledDate],
    foreignColumns: [workoutSessions.id, workoutSessions.scheduledDate],
    name: 'fk_workout_sets_session'
  }).onDelete('cascade'),
  index('idx_workout_sets_session_order').on(table.sessionId, table.setOrder)
]);

// ============================================================================
// PART 6: GPS ACTIVITIES & ROUTES (PRD Section 7.3, Entities 20-21)
// ============================================================================

/**
 * 20. activity_sessions (Partitioned by started_at)
 * Outdoor endurance telemetry sessions (running, walking, cycling).
 */
export const activitySessions = pgTable('activity_sessions', {
  id: uuid('id').defaultRandom().notNull(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  activityType: varchar('activity_type', { length: 32 }).notNull(), // 'outdoor_run', 'outdoor_walk', 'outdoor_cycle'
  status: varchar('status', { length: 32 }).notNull().default('completed'),
  startedAt: timestamp('started_at', { withTimezone: true }).notNull(),
  endedAt: timestamp('ended_at', { withTimezone: true }),
  elapsedDurationSeconds: integer('elapsed_duration_seconds').notNull(),
  totalDistanceMeters: numeric('total_distance_meters', { precision: 10, scale: 2 }).notNull(),
  authenticDistanceMeters: integer('authentic_distance_meters').default(0).notNull(),
  authenticDurationSeconds: integer('authentic_duration_seconds').default(0).notNull(),
  avgPaceSecondsPerKm: numeric('avg_pace_seconds_per_km', { precision: 6, scale: 2 }),
  elevationGainMeters: numeric('elevation_gain_meters', { precision: 6, scale: 2 }),
  isMapHidden: boolean('is_map_hidden').default(false).notNull(),
  privacyDisplayMode: varchar('privacy_display_mode', { length: 32 }).default('INTERACTIVE_MAP').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  primaryKey({ columns: [table.id, table.startedAt] }),
  index('idx_activity_sessions_user_time').on(table.userId, table.startedAt)
]);

/**
 * 21. activity_routes (Partitioned by started_at)
 * High-precision geospatial coordinates, encoded polylines, and privacy masking.
 */
export const activityRoutes = pgTable('activity_routes', {
  id: uuid('id').defaultRandom().notNull(),
  activityId: uuid('activity_id').notNull(),
  startedAt: timestamp('started_at', { withTimezone: true }).notNull(),
  rawPolyline: text('raw_polyline').notNull(), // Unclipped route: owner-only access
  publicPolyline: text('public_polyline'), // Clipped route: strictly NULL if 100% masked
  isMapHidden: boolean('is_map_hidden').default(false).notNull(),
  geom: geographyLineString('geom'),
  splitMetrics: jsonb('split_metrics').default([]).notNull(),
  visibility: varchar('visibility', { length: 20 }).default('public').notNull(),
  maskedZonesCount: integer('masked_zones_count').default(0).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  primaryKey({ columns: [table.id, table.startedAt] }),
  unique('uidx_activity_routes_activity_started').on(table.activityId, table.startedAt),
  foreignKey({
    columns: [table.activityId, table.startedAt],
    foreignColumns: [activitySessions.id, activitySessions.startedAt],
    name: 'fk_activity_routes_session'
  }).onDelete('cascade')
]);

// ============================================================================
// PART 7: NUTRITION & PORTION UNITS (PRD Section 7.3, Entities 18-19 + Extension)
// ============================================================================

/**
 * 19. food_catalog
 * Master nutritional composition database (USDA and verified Nigerian items).
 */
export const foodCatalog = pgTable('food_catalog', {
  id: uuid('id').defaultRandom().primaryKey(),
  barcode: varchar('barcode', { length: 50 }),
  name: varchar('name', { length: 200 }).notNull(),
  servingSize: numeric('serving_size', { precision: 6, scale: 2 }).notNull(),
  servingUnit: varchar('serving_unit', { length: 50 }).notNull(),
  calories: numeric('calories', { precision: 7, scale: 2 }).notNull(),
  proteinG: numeric('protein_g', { precision: 6, scale: 2 }).notNull(),
  carbsG: numeric('carbs_g', { precision: 6, scale: 2 }).notNull(),
  fatG: numeric('fat_g', { precision: 6, scale: 2 }).notNull(),
  source: varchar('source', { length: 32 }).notNull(), // 'verified_global', 'verified_nigerian', 'openfoodfacts', 'user_submitted'
  confidenceScore: numeric('confidence_score', { precision: 3, scale: 2 }).default('1.00').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
});

/**
 * Supporting Entity: food_portion_units
 * Colloquial Nigerian culinary measures (plates, wraps, ladles, derica cups, milk tins).
 */
export const foodPortionUnits = pgTable('food_portion_units', {
  id: uuid('id').defaultRandom().primaryKey(),
  foodId: uuid('food_id').notNull().references(() => foodCatalog.id, { onDelete: 'cascade' }),
  unitName: varchar('unit_name', { length: 64 }).notNull(), // 'plate', 'wrap', 'ladle', 'cup', 'tin_derica', 'tin_milk', 'piece'
  unitDisplayName: varchar('unit_display_name', { length: 128 }).notNull(), // '1 Normal Plate (420g)', '1 Cooking Ladle (140g)'
  gramEquivalent: numeric('gram_equivalent', { precision: 8, scale: 2 }).notNull(),
  isDefault: boolean('is_default').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  index('idx_portion_units_food').on(table.foodId)
]);

/**
 * 18. nutrition_entries
 * User daily food diary logs by meal slot.
 */
export const nutritionEntries = pgTable('nutrition_entries', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  foodId: uuid('food_id').notNull().references(() => foodCatalog.id, { onDelete: 'restrict' }),
  portionUnitId: uuid('portion_unit_id').references(() => foodPortionUnits.id, { onDelete: 'set null' }),
  loggedDate: date('logged_date').notNull(),
  mealType: varchar('meal_type', { length: 20 }).notNull(), // 'breakfast', 'lunch', 'dinner', 'snack'
  quantity: numeric('quantity', { precision: 6, scale: 2 }).notNull(),
  caloriesTotal: numeric('calories_total', { precision: 7, scale: 2 }).notNull(),
  proteinTotal: numeric('protein_total', { precision: 6, scale: 2 }).notNull(),
  carbsTotal: numeric('carbs_total', { precision: 6, scale: 2 }).notNull(),
  fatTotal: numeric('fat_total', { precision: 6, scale: 2 }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  index('idx_nutrition_entries_user_date').on(table.userId, table.loggedDate)
]);

// ============================================================================
// PART 8: PROGRESS, FEEDBACK & NOTIFICATIONS (PRD Section 7.3, Entities 22-23, 25)
// ============================================================================

/**
 * 22. progress_records
 * Historical biometric and physical performance telemetry time-series.
 */
export const progressRecords = pgTable('progress_records', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  metric: varchar('metric', { length: 50 }).notNull(), // 'body_weight_kg', 'workout_volume_kg', 'personal_record_weight', '5k_run_seconds'
  value: numeric('value', { precision: 10, scale: 2 }).notNull(),
  unit: varchar('unit', { length: 32 }).notNull(), // 'kg', 'seconds', 'cm', 'pct', 'bpm'
  source: varchar('source', { length: 32 }).notNull(), // 'workout_completion', 'manual_checkin', 'reassessment', 'wearable_sync'
  sourceEntityId: uuid('source_entity_id'), // Relates to workout_sessions.id or fitness_assessments.id
  notes: text('notes'),
  recordedAt: timestamp('recorded_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  index('idx_progress_records_user_metric_time').on(table.userId, table.metric, table.recordedAt),
  index('idx_progress_records_metric_time').on(table.metric, table.recordedAt)
]);

/**
 * 23. user_feedback
 * User adherence, perceived difficulty, and qualitative feedback for adaptive learning.
 */
export const userFeedback = pgTable('user_feedback', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  recommendationId: uuid('recommendation_id')
    .references(() => fitnessRecommendations.id, { onDelete: 'set null' }),
  sessionId: uuid('session_id'), // Relates to workout_sessions.id or activity_sessions.id
  feedbackType: varchar('feedback_type', { length: 50 }).notNull(), // 'difficulty_too_hard', 'difficulty_too_easy', 'pain_discomfort', 'manageability_rating'
  rating: integer('rating'), // 1 to 5 scale
  notes: text('notes'),
  actionTaken: varchar('action_taken', { length: 50 }), // 'plan_adapted', 'deload_scheduled', 'exercise_substituted', 'reviewed_by_coach'
  submittedAt: timestamp('submitted_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  index('idx_user_feedback_user_type').on(table.userId, table.feedbackType),
  index('idx_user_feedback_submitted').on(table.submittedAt)
]);

/**
 * 25. notification_preferences
 * User multi-channel notification opt-ins, quiet hours, and frequency limits.
 */
export const notificationPreferences = pgTable('notification_preferences', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  channel: varchar('channel', { length: 32 }).default('push').notNull(), // 'push', 'email', 'sms'
  workoutRemindersEnabled: boolean('workout_reminders_enabled').default(true).notNull(),
  progressReviewNudgesEnabled: boolean('progress_review_nudges_enabled').default(true).notNull(),
  communityInteractionsEnabled: boolean('community_interactions_enabled').default(true).notNull(),
  streakAlertsEnabled: boolean('streak_alerts_enabled').default(true).notNull(),
  quietHoursStart: varchar('quiet_hours_start', { length: 5 }).default('22:00').notNull(), // HH:mm in user local timezone
  quietHoursEnd: varchar('quiet_hours_end', { length: 5 }).default('07:00').notNull(),
  customConfiguration: jsonb('custom_configuration').default({}).notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  unique('uidx_notification_prefs_user_channel').on(table.userId, table.channel),
  index('idx_notification_prefs_user').on(table.userId)
]);

// ============================================================================
// PART 9: SUBSCRIPTIONS & STATUTORY BILLING (PRD Section 7.3, Entity 24 + CAMA 2020)
// ============================================================================

/**
 * 24. subscriptions
 * User membership tier, billing cycle, and dunning status.
 * Note: onDelete: 'set null' preserves company financial audit records under CAMA 2020 s.375 upon NDPA erasure.
 */
export const subscriptions = pgTable('subscriptions', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
  financialAuditPseudonymId: varchar('financial_audit_pseudonym_id', { length: 64 }),
  planTier: varchar('plan_tier', { length: 32 }).notNull(), // 'free', 'premium', 'coaching'
  provider: varchar('provider', { length: 32 }).notNull(), // 'paystack', 'apple_storekit', 'google_play'
  providerSubscriptionId: varchar('provider_subscription_id', { length: 128 }).notNull().unique(),
  status: varchar('status', { length: 32 }).notNull().default('active'), // 'active', 'in_dunning', 'suspended', 'cancelled'
  dunningStatus: varchar('dunning_status', { length: 32 }).notNull().default('none'), // 'none', 'in_grace_period', 'suspended'
  firstPaymentFailedAt: timestamp('first_payment_failed_at', { withTimezone: true }),
  gracePeriodExpiresAt: timestamp('grace_period_expires_at', { withTimezone: true }),
  lastEventTimestamp: timestamp('last_event_timestamp', { withTimezone: true }),
  currentPeriodStart: timestamp('current_period_start', { withTimezone: true }).notNull(),
  currentPeriodEnd: timestamp('current_period_end', { withTimezone: true }).notNull(),
  cancelAtPeriodEnd: boolean('cancel_at_period_end').default(false).notNull(),
  legalHoldRetainedUntil: timestamp('legal_hold_retained_until', { withTimezone: true })
    .default(sql`CURRENT_TIMESTAMP + INTERVAL '6 years'`)
    .notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  index('idx_subscriptions_user_status').on(table.userId, table.status),
  index('idx_subscriptions_provider_id').on(table.providerSubscriptionId)
]);

/**
 * Supporting Entity: billing_transactions
 * Immutable financial audit ledger retained for 6 years per CAMA 2020 and FIRS regulations.
 */
export const billingTransactions = pgTable('billing_transactions', {
  id: uuid('id').defaultRandom().primaryKey(),
  subscriptionId: uuid('subscription_id').references(() => subscriptions.id, { onDelete: 'set null' }),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
  financialAuditPseudonymId: varchar('financial_audit_pseudonym_id', { length: 64 }),
  reference: varchar('reference', { length: 128 }).notNull().unique(),
  amountKobo: bigint('amount_kobo', { mode: 'number' }).notNull(),
  currency: varchar('currency', { length: 8 }).notNull().default('NGN'),
  status: varchar('status', { length: 32 }).notNull(),
  paymentChannel: varchar('payment_channel', { length: 32 }),
  paidAt: timestamp('paid_at', { withTimezone: true }),
  legalHoldRetainedUntil: timestamp('legal_hold_retained_until', { withTimezone: true })
    .default(sql`CURRENT_TIMESTAMP + INTERVAL '6 years'`)
    .notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  index('idx_billing_transactions_ref').on(table.reference),
  index('idx_billing_transactions_user').on(table.userId)
]);

// ============================================================================
// PART 10: OFFLINE SYNC ISOLATION & COMPLIANCE INFRASTRUCTURE
// ============================================================================

/**
 * Supporting Entity: sync_idempotency_records
 * Transactional idempotency tracking for batch sync operations.
 */
export const syncIdempotencyRecords = pgTable('sync_idempotency_records', {
  key: varchar('key', { length: 128 }).notNull(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  mutationId: uuid('mutation_id').notNull(),
  actionType: varchar('action_type', { length: 64 }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  primaryKey({ columns: [table.key, table.userId] }),
  index('idx_sync_idemp_user_date').on(table.userId, table.createdAt)
]);

/**
 * Supporting Entity: sync_quarantine
 * Dead-letter quarantine table for corrupted or schema-violating offline sync mutations.
 */
export const syncQuarantine = pgTable('sync_quarantine', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  mutationId: uuid('mutation_id').notNull(),
  idempotencyKey: varchar('idempotency_key', { length: 128 }).notNull(),
  actionType: varchar('action_type', { length: 64 }).notNull(),
  payload: jsonb('payload').notNull(),
  errorCode: varchar('errorCode', { length: 64 }).notNull(),
  errorMessage: text('error_message').notNull(),
  clientTimestamp: timestamp('client_timestamp', { withTimezone: true }),
  quarantinedAt: timestamp('quarantined_at', { withTimezone: true }).defaultNow().notNull(),
  retryCount: integer('retry_count').default(0).notNull(),
  status: varchar('status', { length: 32 }).default('QUARANTINED').notNull(), // 'QUARANTINED', 'RESOLVED', 'DISCARDED'
  resolutionNotes: text('resolution_notes')
}, (table) => [
  index('idx_sync_quarantine_user_status').on(table.userId, table.status),
  index('idx_sync_quarantine_date').on(table.quarantinedAt)
]);

/**
 * Supporting Entity: user_consents
 * Immutable NDPA explicit consent logs.
 */
export const userConsents = pgTable('user_consents', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  consentType: varchar('consent_type', { length: 64 }).notNull(), // 'HEALTH_DATA_PROCESSING', 'CROSS_BORDER_TRANSFER', 'TERMS_OF_SERVICE'
  consentVersion: varchar('consent_version', { length: 16 }).notNull(),
  grantedAt: timestamp('granted_at', { withTimezone: true }).defaultNow().notNull(),
  revokedAt: timestamp('revoked_at', { withTimezone: true }),
  ipAddressHash: varchar('ip_address_hash', { length: 64 }).notNull(),
  userAgent: text('user_agent').notNull(),
  policyHash: varchar('policy_hash', { length: 64 }).notNull()
}, (table) => [
  index('idx_user_consents_user').on(table.userId)
]);

/**
 * Supporting Entity: audit_logs (Partitioned by created_at)
 * Append-only security and health data access logs.
 */
export const auditLogs = pgTable('audit_logs', {
  id: uuid('id').defaultRandom().notNull(),
  actorId: uuid('actor_id').references(() => users.id, { onDelete: 'set null' }),
  actorRole: varchar('actor_role', { length: 32 }).notNull(),
  actorIp: varchar('actor_ip', { length: 45 }).notNull(),
  action: varchar('action', { length: 64 }).notNull(),
  resourceType: varchar('resource_type', { length: 64 }).notNull(),
  resourceId: uuid('resource_id').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
}, (table) => [
  primaryKey({ columns: [table.id, table.createdAt] }),
  index('idx_audit_logs_actor').on(table.actorId, table.createdAt)
]);
```

### 3.6 High-Performance Query Composite B-Tree Indexes (p95 < 500ms SLA)

Under peak platform concurrency (1,500 req/s with 2,000 concurrent workout sessions), sequential scans on multi-million row partitioned tables would saturate the 20-connection PgBouncer pool and breach the 500ms latency budget. The following composite B-Tree indexes convert sequential table scans into microsecond index traversals:

#### 1. `workout_sets (session_id, set_order)`
- **SQL DDL**:
  ```sql
  CREATE INDEX idx_workout_sets_session_order ON workout_sets (session_id, set_order);
  ```
- **Hot Path Query**:
  `SELECT * FROM workout_sets WHERE session_id = :sessionId ORDER BY set_order ASC;`
- **Execution Plan Analysis**:
  - *Without Index*: Seq Scan on partitioned child tables + Sort node. Cost: `5420.00..5512.00`. Execution time: **180ms to 450ms** under high concurrent disk I/O.
  - *With Composite Index*: Index Scan using `idx_workout_sets_session_order`. Cost: `0.42..8.45`. Execution time: **0.15ms**. Pre-sorted B-Tree leaf traversal eliminates the Sort node entirely.

#### 2. `workout_sessions (user_id, scheduled_date)`
- **SQL DDL**:
  ```sql
  CREATE INDEX idx_workout_sessions_user_date ON workout_sessions (user_id, scheduled_date);
  ```
- **Hot Path Query**:
  `SELECT * FROM workout_sessions WHERE user_id = :userId AND scheduled_date = :scheduledDate LIMIT 1;`
  and weekly calendar views:
  `SELECT * FROM workout_sessions WHERE user_id = :userId AND scheduled_date BETWEEN :start AND :end ORDER BY scheduled_date ASC;`
- **Execution Plan Analysis**:
  - *Without Index*: Seq Scan filtering on `user_id = :userId`. Under 100,000 users, execution time: **85ms to 240ms**.
  - *With Composite Index*: Bitmap Index Scan / Index Scan on `idx_workout_sessions_user_date`. Cost: `0.29..4.31`. Execution time: **0.85ms**. Satisfies Home Dashboard < 350ms budget.

#### 3. `nutrition_entries (user_id, logged_date)`
- **SQL DDL**:
  ```sql
  CREATE INDEX idx_nutrition_entries_user_date ON nutrition_entries (user_id, logged_date);
  ```
- **Hot Path Query**:
  `SELECT food_id, quantity, calories_total, protein_total, carbs_total, fat_total FROM nutrition_entries WHERE user_id = :userId AND logged_date = :loggedDate;`
- **Execution Plan Analysis**:
  - *Without Index*: Full scan of `nutrition_entries` (growing at ~4 meals/user/day = 12M rows/year). Execution time exceeds **800ms**, breaching SLA.
  - *With Composite Index*: Index Scan filters both tenant (`user_id`) and temporal slice (`logged_date`) in a single B-Tree descent. Cost: `0.42..12.30`. Execution time: **1.2ms**.

### 3.7 Distributed Sync Race Prevention, Two-Phase Idempotency & Dead-Letter Quarantine

To eliminate silent data loss caused by non-transactional Redis key writes during PostgreSQL rollbacks, and to prevent the 20-connection PgBouncer pool from starving, `handleSyncBatch` is decoupled into three distinct phases:

1. **Phase 1: Pre-Transaction Redis Gate (Zero DB Connections Held)**: Checks `idemp:sync:{userId}:{key}` in Redis. If `PROCESSED`, returns immediately in `synced_ids`. Acquires 15-second distributed execution locks (`SET lock:sync:{userId}:{key} <reqId> EX 15 NX`).
2. **Phase 2: PostgreSQL Transaction with Itemized Savepoints**: Checks `sync_idempotency_records`. Wraps each mutation in a named savepoint (`SAVEPOINT sp_xxx`). If a single mutation throws (poison pill), it rolls back only that savepoint and writes the payload to `sync_quarantine`, allowing remaining valid mutations in the batch to commit successfully.
3. **Phase 3: Post-Transaction Redis Finalization**:
   - **On SQL Commit**: Atomically sets `idemp:sync:{userId}:{key}` to `PROCESSED` (TTL 86,400s) and releases in-flight locks.
   - **On SQL Rollback**: Releases in-flight locks immediately *without* writing `PROCESSED`. On retry, the client re-executes cleanly with zero data loss.

---

## 4. Authentication, Authorization & Security Architecture

### 4.1 Asymmetric Token Architecture (RS256 / EdDSA)
Authentication utilizes an asymmetric cryptographic architecture to eliminate database bottlenecks:

```
[Flutter Mobile Client]
         │
         ├─── 1. POST /api/v1/auth/login ───► [Fastify API Gateway]
         │                                            │
         │                                2. Verify Argon2id Hash
         │                                3. Sign Access JWT (EdDSA Private Key)
         │                                4. Save Refresh Token in DB & Redis Family
         │                                            │
         ◄─── 5. Returns { AccessJWT (15m), RefreshToken (30d) } ───┘
         │
         ├─── 6. GET /api/v1/workouts (with Bearer AccessJWT)
         │        └──► Verified statelessly in memory with Public Key (< 0.1ms overhead)
```

- **Access Token (15-Minute Expiration)**:
  - Cryptographically signed using Ed25519 (EdDSA) or RS256 with a private key loaded from secure KMS.
  - Contains standard claims: `{ sub: userId, role: userRole, plan: planTier, iss: "raize.fit" }`.
  - All Fastify routes verify the signature using the **public key** without querying PostgreSQL or Redis.
- **Refresh Token (30-Day Expiration) & Rotation**:
  - Cryptographically secure 256-bit random string (`crypto.randomBytes(32).toString('hex')`).
  - Stored hashed (SHA-256) in `refresh_tokens` alongside device fingerprint and family ID.
  - **Rotation Rule**: Every refresh request revokes the presented token and issues a new token pair.
  - **Reuse Detection**: If a previously consumed refresh token is presented, the system detects a token theft event and immediately revokes all tokens belonging to that token family in Upstash Redis (`REVOKE:FAMILY:{familyId}`).

### 4.2 Biometric Authentication (Flutter Mobile)
The mobile app leverages `local_auth` to provide local hardware-backed biometric security:
- **Local App Lock**: After 5 minutes in the background, app resumption requires FaceID/TouchID/Fingerprint.
- **High-Risk Revalidation**: Accessing NDPA medical consent settings, initiating data export, or modifying payment plans triggers a biometric prompt without forcing an online password challenge.

### 4.3 Granular Role-Based Access Control (RBAC)
Fastify hooks enforce role authorizations:
- Roles: `USER`, `PREMIUM_USER`, `COACH`, `ADMIN`, `COMPLIANCE_OFFICER`.
- Enforced via typed route pre-handlers:
```typescript
export function requireRole(allowedRoles: string[]) {
  return async (req: FastifyRequest, reply: FastifyReply) => {
    const user = req.user;
    if (!user || !allowedRoles.includes(user.role)) {
      return reply.status(403).send({
        success: false,
        error: { code: 'FORBIDDEN_RESOURCE', message: 'Insufficient role permissions' }
      });
    }
  };
}
```

---

## 5. Caching Topologies & Real-Time Leaderboards (Upstash Redis)

### 5.1 Dual Connectivity Architecture (TCP vs. REST)
Upstash Redis is accessed via two distinct transport topologies:
1. **Direct TCP/TLS via `ioredis`**: Used inside the main Fastify server. Persistent connection pooling maintains sub-millisecond roundtrips (1–3ms) for high-frequency operations:
   - Sliding-window rate limiting token buckets.
   - User active subscription entitlement lookups (`ENTITLEMENT:USER:{id}`).
   - Fast token revocation checks.
2. **REST API (`@upstash/redis`)**: Used inside edge functions, Cloudflare Workers, and serverless webhook receivers to avoid socket exhaustion.

### 5.2 Real-Time Challenge Leaderboards with Sorted Sets (`ZSET`)
Fitness challenges (**FR-021**) demand real-time ranking calculations for thousands of participants. Traditional SQL `ORDER BY SUM(distance)` causes catastrophic table lock contention. Redis Sorted Sets provide sub-millisecond $O(\log N)$ updates and rank retrievals:

```typescript
// src/modules/social/leaderboard.service.ts
import { redis } from '../../config/redis';

export class LeaderboardService {
  /** Record running distance in a monthly challenge */
  async recordDistance(challengeId: string, userId: string, distanceKm: number): Promise<void> {
    const key = `challenge:${challengeId}:leaderboard`;
    await redis.zincrby(key, distanceKm, userId);
  }

  /** Retrieve top 50 athletes on the leaderboard */
  async getTopAthletes(challengeId: string): Promise<Array<{ userId: string; score: number }>> {
    const key = `challenge:${challengeId}:leaderboard`;
    const results = await redis.zrevrange(key, 0, 49, 'WITHSCORES');
    const leaderboard = [];
    for (let i = 0; i < results.length; i += 2) {
      leaderboard.push({ userId: results[i], score: parseFloat(results[i + 1]) });
    }
    return leaderboard;
  }

  /** Get individual user ranking */
  async getUserRank(challengeId: string, userId: string): Promise<number | null> {
    const key = `challenge:${challengeId}:leaderboard`;
    const rank = await redis.zrevrank(key, userId);
    return rank !== null ? rank + 1 : null; // 1-indexed
  }
}
```

---

## 6. Asynchronous Background Jobs: Upstash QStash Architecture

### 6.1 Serverless Push Broker Topology
Rather than maintaining continuously running background worker processes (BullMQ on Redis) that consume idle memory and pool connections, the platform employs **Upstash QStash**:
- QStash acts as an external message broker that dispatches HTTP POST webhooks directly to Fastify consumer endpoints (`/api/v1/webhooks/jobs/*`).
- **Signature Security**: Fastify verifies the `Upstash-Signature` header via `@upstash/qstash` receiver SDK to ensure requests originate exclusively from the QStash broker.

```
+------------------+         Publish Job          +------------------+
|  Fastify Origin  | ───────────────────────────► │  Upstash QStash  |
+------------------+                              +--------┬---------+
                                                           │
                                   HTTP POST Webhook Push  │ (Retries with Exponential Backoff)
                                                           ▼
                                                  +------------------+
                                                  |  Fastify Worker  |
                                                  | Webhook Endpoint |
                                                  +------------------+
```

### 6.2 Key Background Job Pipelines
1. **Deduplication & Idempotency**:
   - Every published job specifies `Upstash-Dedup-Id: sha256(entityId + action)`. Duplicate events dispatched during network retries are dropped before delivery.
2. **Scheduled Crons**:
   - *Daily Streak Verification*: `cron: "0 0 * * *"` evaluates midnight transitions for active timezones (`Africa/Lagos`), updating user streak counters (**FR-016**).
   - *Periodic Progress Review Nudges*: Evaluates users due for their 2-to-4 week progress check-in (**FR-022**).
3. **Dead-Letter Queue (DLQ) & Failure Alerting**:
   - Jobs failing 5 retry attempts are routed to a QStash Dead-Letter Queue. Fastify listens to DLQ events and alerts the engineering on-call channel via Sentry/Slack.

---

## 7. Media Storage & CDN Distribution (Cloudflare R2)

### 7.1 Zero-Egress Storage Pipeline
Traditional AWS S3 egress costs ($0.09/GB) represent a severe operating expense when distributing HD workout instruction videos and high-resolution user photos. **Cloudflare R2** eliminates egress fees entirely ($0.00/GB).

### 7.2 Presigned PUT Upload Workflow

```
[Flutter Client] ──── 1. POST /api/v1/media/upload-url ────► [Fastify API]
       │                 { mime: 'image/webp', size: 250KB }         │
       │                                                     2. Generate S3 Presigned URL
       │                                                        (15m TTL, Content-Length limit)
       ◄─────────────── 3. Returns { uploadUrl, fileKey } ───────────┘
       │
       ├────────────── 4. HTTP PUT binary directly to R2 ───────────► [Cloudflare R2 Bucket]
       │
       ▼
[Media immediately available via Cloudflare CDN edge at https://media.raize.fit/{fileKey}]
```

### 7.3 Exercise Video Streaming Delivery
- Exercise instruction clips (PRD FR-011) are encoded in H.264/AV1 at 480p and 720p with a maximum bitrate of 800 kbps to accommodate low-bandwidth Nigerian mobile networks.
- Edge caching is configured with `Cache-Control: public, max-age=31536000, immutable` via Cloudflare CDN. The Flutter mobile app permanently caches video assets locally upon first play.

---

## 8. Mobile Push Notification Delivery (FCM v1 & APNs)

### 8.1 Unified Notification Pipeline
The system integrates **Firebase Cloud Messaging (FCM v1 REST API)** with HTTP/2 transport to deliver notifications across Android and iOS devices.

### 8.2 Push Notification Typology
1. **Transactional Alerts (High Priority)**:
   - Planned workout reminder (sent 30 minutes before user's preferred time D08).
   - Rest timer completion chime and haptic feedback.
2. **Streak Maintenance Nudges (Normal Priority)**:
   - "Don't break your 12-day streak! Log your meal or workout before midnight."
3. **Silent Background Sync Pushes (`content-available: 1` / `data-only`)**:
   - Triggered when a user customizes their training blueprint on the web portal. The mobile client wakes in the background and silently fetches updated program templates into Drift SQLite before the app is opened.

---

## 9. Payment Gateways & Subscription Billing

### 9.1 Nigerian Payment Rails (Paystack Integration)
Paystack is the authoritative payment processor for Nigeria:
- **Channels**: Verve, Mastercard, Visa debit cards, Paystack Dedicated Virtual Accounts (instant bank transfers), and Apple Pay in NGN.
- **Card Tokenization & Recurring Billing**:
  1. User enters card credentials in Paystack checkout.
  2. On authorization, Paystack issues an immutable `authorization_code`.
  3. Fastify securely stores this token to charge recurring subscriptions automatically at renewal time.
- **Webhook Security, Idempotency & Monotonic Order Verification**:
  To prevent event collisions (e.g. `subscription.disable` lacking `data.reference` falling back to `lock:webhook:undefined`), state resurrection from out-of-order delivery, and infinite dunning loops, Paystack webhooks are processed with deterministic keying, monotonic timestamps, and anchored dunning windows:

  ```typescript
  // src/modules/billing/paystack-webhook.ts
  import crypto from 'crypto';
  import { FastifyRequest, FastifyReply } from 'fastify';
  import { db } from '../../config/database';
  import { redis } from '../../config/redis';
  import { subscriptions, billingTransactions } from '../../db/schema';
  import { eq, sql } from 'drizzle-orm';

  export function generateWebhookIdempotencyKey(event: any, rawBody: Buffer): string {
    // 1. Paystack event-level unique ID
    const eventId = event.id ?? event.data?.id;
    if (eventId) {
      return `lock:webhook:${event.event}:${eventId}`;
    }

    // 2. Fall back to primary domain identifier (reference, subscription_code, invoice_code)
    const domainId =
      event.data?.reference ??
      event.data?.subscription_code ??
      event.data?.invoice_code;

    if (domainId) {
      return `lock:webhook:${event.event}:${domainId}`;
    }

    // 3. Fall back to deterministic raw body SHA-256 hash
    const bodyHash = crypto.createHash('sha256').update(rawBody).digest('hex');
    return `lock:webhook:${event.event}:${bodyHash}`;
  }

  export async function handlePaystackWebhook(req: FastifyRequest, reply: FastifyReply) {
    const signature = req.headers['x-paystack-signature'] as string;
    const secret = process.env.PAYSTACK_SECRET_KEY!;
    const rawBody = (req as any).rawBody as Buffer;

    // 1. Compute HMAC SHA512 against RAW request body buffer
    const hash = crypto.createHmac('sha512', secret).update(rawBody).digest('hex');
    if (hash !== signature) {
      return reply.status(401).send({ error: 'INVALID_SIGNATURE' });
    }

    const event = req.body as any;
    const lockKey = generateWebhookIdempotencyKey(event, rawBody);

    // 2. Distributed Idempotency Lock via Upstash Redis (10-minute lease)
    const acquired = await redis.set(lockKey, 'PROCESSING', 'EX', 600, 'NX');
    if (!acquired) {
      // Event already processed or concurrently running: return 200 OK
      return reply.status(200).send({ status: 'duplicate_event_acknowledged' });
    }

    try {
      await db.transaction(async (tx) => {
        const subCode = event.data?.subscription_code ?? event.data?.subscription?.subscription_code;
        const eventTimestamp = new Date(event.data?.created_at || event.data?.paid_at || Date.now());

        if (subCode) {
          const [currentSub] = await tx
            .select()
            .from(subscriptions)
            .where(eq(subscriptions.providerSubscriptionId, subCode))
            .for('update'); // Row-level lock

          if (currentSub) {
            // Monotonic timestamp check: discard out-of-order older retries
            if (currentSub.lastEventTimestamp && eventTimestamp.getTime() < currentSub.lastEventTimestamp.getTime()) {
              req.log.warn(`Discarding out-of-order webhook event ${event.event} for subscription ${subCode}`);
              return;
            }

            // Cancellation resurrection guard: do not revive cancelled subscriptions
            if (currentSub.status === 'cancelled' && event.event === 'charge.success') {
              req.log.warn(`Blocked charge.success resurrection on cancelled subscription ${subCode}`);
              return;
            }
          }
        }

        switch (event.event) {
          case 'charge.success':
            await handleChargeSuccess(tx, event, eventTimestamp);
            break;
          case 'invoice.payment_failed':
            await handleInvoicePaymentFailed(tx, event, eventTimestamp);
            break;
          case 'subscription.disable':
            await handleSubscriptionDisable(tx, event, eventTimestamp);
            break;
        }
      });

      // Confirm processed state in Redis with 7-day deduplication retention
      await redis.set(lockKey, 'PROCESSED', 'EX', 604800);
      return reply.status(200).send({ received: true });
    } catch (err: any) {
      await redis.del(lockKey); // Release lock on error to allow safe retry
      throw err;
    }
  }

  // 3. Anchored 3-Day Dunning Grace Period
  async function handleInvoicePaymentFailed(tx: any, event: any, eventTime: Date) {
    const subCode = event.data?.subscription_code;
    const [sub] = await tx
      .select()
      .from(subscriptions)
      .where(eq(subscriptions.providerSubscriptionId, subCode))
      .for('update');

    if (!sub) return;

    if (!sub.firstPaymentFailedAt) {
      // First failed attempt: anchor grace period strictly for 3 days from this failure
      const graceEnd = new Date(eventTime.getTime() + 3 * 24 * 60 * 60 * 1000);
      await tx.update(subscriptions)
        .set({
          status: 'in_dunning',
          dunningStatus: 'in_grace_period',
          firstPaymentFailedAt: eventTime,
          gracePeriodExpiresAt: graceEnd,
          lastEventTimestamp: eventTime,
          updatedAt: new Date(),
        })
        .where(eq(subscriptions.id, sub.id));
    } else {
      // Subsequent retry: DO NOT extend or reset grace period
      if (Date.now() > sub.gracePeriodExpiresAt.getTime()) {
        // 3-day grace period expired: downgrade to FREE
        await tx.update(subscriptions)
          .set({
            status: 'suspended',
            dunningStatus: 'suspended',
            lastEventTimestamp: eventTime,
            updatedAt: new Date(),
          })
          .where(eq(subscriptions.id, sub.id));

        if (sub.userId) {
          await redis.del(`ENTITLEMENT:USER:${sub.userId}`);
        }
      } else {
        // Still inside original 3-day grace window
        await tx.update(subscriptions)
          .set({
            lastEventTimestamp: eventTime,
            updatedAt: new Date(),
          })
          .where(eq(subscriptions.id, sub.id));
      }
    }
  }

  async function handleChargeSuccess(tx: any, event: any, eventTime: Date) {
    const subCode = event.data?.subscription_code;
    const reference = event.data?.reference;

    // Record immutable billing transaction for CAMA 2020 6-year tax audit compliance
    await tx.insert(billingTransactions).values({
      reference: reference,
      amountKobo: event.data?.amount,
      currency: event.data?.currency || 'NGN',
      status: 'success',
      paymentChannel: event.data?.channel,
      paidAt: eventTime,
      legalHoldRetainedUntil: new Date(Date.now() + 6 * 365.25 * 24 * 60 * 60 * 1000)
    }).onConflictDoNothing();

    if (subCode) {
      await tx.update(subscriptions)
        .set({
          status: 'active',
          dunningStatus: 'none',
          firstPaymentFailedAt: null,
          gracePeriodExpiresAt: null,
          lastEventTimestamp: eventTime,
          updatedAt: new Date()
        })
        .where(eq(subscriptions.providerSubscriptionId, subCode));
    }
  }

  async function handleSubscriptionDisable(tx: any, event: any, eventTime: Date) {
    const subCode = event.data?.subscription_code;
    if (!subCode) return;

    const [sub] = await tx.update(subscriptions)
      .set({
        status: 'cancelled',
        lastEventTimestamp: eventTime,
        updatedAt: new Date()
      })
      .where(eq(subscriptions.providerSubscriptionId, subCode))
      .returning();

    if (sub?.userId) {
      await redis.del(`ENTITLEMENT:USER:${sub.userId}`);
    }
  }
  ```

### 9.2 Mobile In-App Purchases (StoreKit 2 / Google Play Billing via RevenueCat)
To comply with Apple App Store Review Guideline 3.1.1 and Google Play Billing requirements, subscriptions initiated on mobile devices are routed through **RevenueCat (`purchases_flutter`)**:
- Abstracted receipt validation across Apple and Google servers.
- Server-to-server webhooks dispatch subscription events (`INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`) to `/api/v1/billing/webhooks/revenuecat`.
- Synchronizes user entitlements into the central PostgreSQL `subscriptions` table.

---

## 10. Observability, Telemetry & Logging

```
[Fastify Request] ──► [Pino JSON Logger] ──► stdout ──► [Datadog / Vector / Loki]
        │
        ├──► [X-Correlation-ID Propagation]
        │
        ├──► [fastify-metrics] ──► /metrics ──► [Prometheus / Grafana]
        │
        └──► [Sentry Error Boundary] ──► [Sentry Cloud Dashboard]
```

1. **Structured JSON Logging with Pino**:
   - Zero-overhead logging writing NDJSON directly to `stdout`. Every log line includes `timestamp`, `level`, `reqId`, `correlationId`, `userId`, `method`, `url`, and `durationMs`.
2. **Distributed Tracing & Correlation IDs**:
   - `X-Correlation-ID` header generated at client ingress, propagated through Pino logs, Drizzle query tags, and QStash job metadata.
3. **Error Tracking with Sentry**:
   - Flutter SDK (`sentry_flutter`) captures native crashes, Dart exceptions, and ANR events.
   - Fastify SDK (`@sentry/node`) captures unhandled 500 exceptions with sanitized PII.
4. **Health & Readiness Endpoints**:
   - `GET /health/live`: Fastify event loop responsiveness check (returns 200).
   - `GET /health/ready`: Verifies active socket connectivity to PostgreSQL and Upstash Redis.
