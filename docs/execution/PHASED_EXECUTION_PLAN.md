# Phased Execution Plan & Engineering Checklists

**Document Version**: 1.0.0  
**Status**: Authoritative Execution Roadmap  
**Date**: 2026-11-07  
**Scope**: Full Engineering Lifecycle (Phase 0 through Phase 8) for `raize.fit`  
**Cross-References**: FR-001 through FR-027, User Journeys 1 through 6, NDPA 2023  

---

## 1. Roadmap Overview & Execution Philosophy

The execution plan structures engineering into **nine sequential phases** (Phase 0 through Phase 8). Each phase represents an independently verifiable stage of platform readiness with explicit entry prerequisites, actionable engineering task checklists cross-referenced to PRD functional requirements, quality gates, and milestone artifacts.

```
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 0: Foundation, Tooling & Monorepo Setup                                                  │
└───────────────────────────────────────────────┬────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: Core Domain Modeling, Database Migrations & Auth (FR-001, FR-002, UJ-1)               │
└───────────────────────────────────────────────┬────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: Assessment Engine, Safety Screening & Recommendation Core (FR-003–FR-010, FR-022, UJ-1│
└───────────────────────────────────────────────┬────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: Flutter Mobile Client Core & Structured Workouts (FR-011, FR-012, FR-016, FR-017, UJ-2│
└───────────────────────────────────────────────┬────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: Outdoor GPS Tracking & Offline Synchronization Engine (FR-013, FR-019, UJ-3)          │
└───────────────────────────────────────────────┬────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 5: Nutrition Logging, Localized Food DB & Meal Planning (FR-014, FR-015, FR-024, UJ-4)   │
└───────────────────────────────────────────────┬────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 6: Community Social Feeds, Challenges & Gamification (FR-020, FR-021)                    │
└───────────────────────────────────────────────┬────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 7: Monetization, Billing Rails & Push Notifications (FR-018, FR-027)                     │
└───────────────────────────────────────────────┬────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ PHASE 8: Production Launch Hardening, Observability & NDPA Audit (FR-025, FR-026, UJ-5, UJ-6)  │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Phase 0: Foundation, Tooling & Monorepo Environment Setup

### 2.1 Scope & Objectives
Establish the multi-language repository infrastructure, containerized local services, environment validation, and automated CI/CD code quality gates.

### 2.2 Entry Prerequisites
- Developer workstation equipped with Node.js 22 LTS, Flutter 3.x SDK, Docker Desktop, and Git.
- Cloudflare R2 bucket and Upstash Redis/QStash developer accounts provisioned.

### 2.3 Actionable Engineering Checklist
- [ ] **CHKL-001**: Initialize polyglot monorepo layout with root `package.json`, `pnpm-workspace.yaml`, and Flutter mobile project under `mobile/`.
- [ ] **CHKL-002**: Configure `docker-compose.yml` defining PostgreSQL 16 with PostGIS extension enabled (`postgis/postgis:16-3.4-alpine`) and local PgBouncer instance.
- [ ] **CHKL-003**: Initialize backend Fastify 5.x TypeScript project with `@fastify/type-provider-typebox`, `@sinclair/typebox`, and strict `tsconfig.json`.
- [ ] **CHKL-004**: Implement configuration loader validating all environment variables (database credentials, Upstash keys, R2 endpoints) at application startup using TypeBox schemas.
- [ ] **CHKL-005**: Configure root GitHub Actions CI pipeline running `eslint`, `prettier`, TypeScript compilation (`tsc --noEmit`), and Flutter analyzer (`dart analyze`).
- [ ] **CHKL-006**: Set up pre-commit Git hooks using Husky and lint-staged to prevent committing unformatted or failing code.

### 2.4 Exit Criteria & Quality Gates
- `docker compose up -d` boots healthy PostgreSQL + PostGIS instance and passes readiness probe within 10s.
- `pnpm run build` and `flutter analyze` exit with return code `0` and zero warnings.
- Environment schema fails fast with informative error if any required variable is omitted.

### 2.5 Milestone Deliverable
- Clean monorepo foundation with passing CI pipeline and validated local environment.

---

## 3. Phase 1: Core Domain Modeling, Database Migrations & Authentication

### 3.1 Scope & Objectives
Implement the relational database schema, database migrations via Drizzle ORM, asymmetric JWT authentication with refresh token rotation, biometric mobile lock, and NDPA consent logging (**FR-001**, **FR-002**, **EXT-004**, **User Journey 1**).

### 3.2 Entry Prerequisites
- Phase 0 foundation verified.
- Access to active PostgreSQL database and Upstash Redis instance.

### 3.3 Actionable Engineering Checklist
- [ ] **CHKL-007**: Define Drizzle ORM schemas in `backend/src/db/schema/` for `users`, `user_profiles`, `health_restrictions`, `refresh_tokens`, `user_consents`, and `audit_logs` (FR-001, FR-002).
- [ ] **CHKL-008**: Generate and execute initial migration (`0001_initial_auth_and_profiles.sql`) using `drizzle-kit generate:pg` and `drizzle-kit push:pg`.
- [ ] **CHKL-009**: Configure `postgres.js` client driver with transaction-mode PgBouncer connection pooling (`max: 20`, `prepare: false`).
- [ ] **CHKL-010**: Implement password hashing service using Argon2id (`argon2` npm package) with memory cost 65536 KB and time cost 3.
- [ ] **CHKL-011**: Build asymmetric JWT service signing short-lived access tokens (15m TTL) with RS256/EdDSA private key and verifying statelessly with public key (FR-001).
- [ ] **CHKL-012**: Implement refresh token rotation service with token family reuse detection backed by PostgreSQL and Upstash Redis (`REVOKE:FAMILY:{id}`) (FR-001).
- [ ] **CHKL-013**: Implement user registration endpoint `POST /api/v1/auth/register` enforcing email validation, password strength, and mandatory age $\ge 18$ check (FR-001, FR-002).
- [ ] **CHKL-014**: Implement login endpoint `POST /api/v1/auth/login` and refresh endpoint `POST /api/v1/auth/refresh` with sliding-window rate limiting (FR-001).
- [ ] **CHKL-015**: Implement NDPA explicit health consent capture recording timestamp, IP hash, and privacy policy version in `user_consents` (NDPA Section 30).
- [ ] **CHKL-016**: Implement user profile endpoints `GET /api/v1/users/me` and `PATCH /api/v1/users/me` normalizing height (cm) and weight (kg) to metric values (FR-002).

### 3.4 Exit Criteria & Quality Gates
- 100% test coverage for password hashing, token issuance, and refresh rotation attacks.
- Underage registration attempt ($< 18$ years old) correctly rejected with HTTP 400 `UNDERAGE_NOT_PERMITTED`.
- Attempted reuse of an expired refresh token revokes all sibling sessions in Redis.

### 3.5 Milestone Deliverable
- Operational authentication, profile, and consent management subsystem with end-to-end integration tests.

---

## 4. Phase 2: Assessment Engine, Safety Screening & Recommendation Core

### 4.1 Scope & Objectives
Implement the complete 6-stage fitness questionnaire lifecycle, PAR-Q+ health screening gate, 6-dimension classification engine, weighted activity scoring formula, and weekly blueprint schedule generator (**FR-003** through **FR-010**, **FR-022**, **FR-023**, **User Journey 1**, **User Journey 5**, **User Journey 6**).

### 4.2 Entry Prerequisites
- Phase 1 authentication and profile subsystem operational.

### 4.3 Actionable Engineering Checklist
- [ ] **CHKL-018**: Define questionnaire schema and questions seed data for Stages A through F (Questions A01–A06, B01–B04, C01–C06, D01–D08, E01–E06, F01–F05) in `backend/src/db/seeds/questions.json` (FR-003).
- [ ] **CHKL-019**: Create Drizzle schemas for `fitness_assessments`, `fitness_profiles`, `recommendation_runs`, and `fitness_recommendations` (FR-003, FR-005).
- [ ] **CHKL-020**: Implement `POST /api/v1/assessments` to initialize versioned draft assessments and `PUT /api/v1/assessments/:id/responses` for auto-saving partial progress per stage (FR-003, FR-004).
- [ ] **CHKL-021**: Implement immutable assessment freezing on `POST /api/v1/assessments/:id/complete`; reject any subsequent mutation attempts with HTTP 403 (FR-005).
- [ ] **CHKL-022**: Implement 6-dimension classification service mapping responses to Goal, Experience, Baseline, Environment, Availability, and Safety status (FR-006).
- [ ] **CHKL-023**: Build behavioral consistency check in classification engine: if self-reported experience is "Advanced" but frequency is "Never", down-rank classification to "Beginner" (FR-006).
- [ ] **CHKL-024**: Implement Health & Safety Screening Gate (Stage E):
  - Exclude contraindicated exercises for reported joint injuries (E01) or chronic conditions (E02) (FR-007).
  - Enforce Question E05 refusal hardening: if Question E05 (cardiovascular red flags: chest pain, syncope, unusual breathlessness) is answered "Yes", "Prefer not to say", or omitted, immediately halt plan generation, set `safety_status = 'exercise_paused_pending_assessment'`, display urgent clinical disclaimer, and automatically update any pre-existing scheduled/in-progress sessions to `cancelled_medical_hold` in an atomic database transaction (FR-007, Edge Case 1).
- [ ] **CHKL-025**: Implement 7-factor weighted scoring algorithm in `backend/src/modules/recommendation/scoring.service.ts`:
  $$S(a, u) = \sum_{i=1}^7 w_i \cdot r_i(a, u)$$
  (Goal: 30%, Pref: 20%, Exp: 15%, Equip: 10%, Time: 10%, Env: 10%, Secondary: 5%) (FR-008).
- [ ] **CHKL-026**: Implement 7-day schedule generator balancing training days with required recovery intervals based on available days (D01) and session length (D02) (FR-009).
- [ ] **CHKL-027**: Implement plan customization endpoint `POST /api/v1/recommendations/:id/customize` allowing exercise swaps while validating safety constraints (FR-010).
- [ ] **CHKL-028**: Build 2-to-4 week progress check-in endpoint `POST /api/v1/progress/reassessments` and adaptation feedback listener `POST /api/v1/recommendations/:id/feedback` (FR-022, FR-023).

### 4.4 Exit Criteria & Quality Gates
- Unit test suite verifies scoring formula produces mathematical results identical to PRD Section 3.3.
- Stage E05 affirmative response reliably pauses plan generation and sets emergency safety status across 100% of test runs.
- Blueprint generation returns complete 7-day plan in $< 1,500\text{ms}$ under load.

### 4.5 Milestone Deliverable
- Intelligence core capable of processing onboarding assessments into customized, safety-validated weekly training plans.

---

## 5. Phase 3: Flutter Mobile Client Core & Structured Workouts

### 5.1 Scope & Objectives
Construct the cross-platform Flutter mobile client adhering to Clean Architecture, initialize the local Drift (SQLite) database, build the live workout execution tracker, exercise video streamer, and historical analytics dashboard (**FR-011**, **FR-012**, **FR-013**, **FR-016**, **FR-017**, **EXT-003**, **User Journey 2**).

### 5.2 Entry Prerequisites
- Phase 2 assessment and blueprint endpoints operational.
- Cloudflare R2 bucket seeded with exercise instruction media.

### 5.3 Actionable Engineering Checklist
- [ ] **CHKL-029**: Initialize Flutter Clean Architecture folder structure: `core/`, `features/auth/`, `features/onboarding/`, `features/dashboard/`, `features/workout/`, and `features/progress/`.
- [ ] **CHKL-030**: Configure Riverpod 2.x state management with `@riverpod` code generation and declarative routing via `go_router`.
- [ ] **CHKL-030A**: Build mobile biometric lock wrapper in Flutter using `local_auth` and `WidgetsBindingObserver`, enforcing biometric re-authentication after 5 minutes in background via GoRouter redirect guards (EXT-004).
- [ ] **CHKL-031**: Configure Drift SQLite database (`AppDatabase`) with tables for `local_workout_sessions`, `local_workout_sets`, `exercises`, and the client Write-Ahead Log `mutation_queue` table (FR-012, UJ-2).
- [ ] **CHKL-031A**: Define backend Drizzle ORM schemas in `backend/src/db/schema/workout.ts` for `exercises`, `workout_programs`, `workout_sessions`, `workout_sets`, and `progress_records` with foreign keys, composite partition keys (`scheduled_date`), and JSONB configurations (FR-011, FR-012, FR-017).
- [ ] **CHKL-031B**: Generate and execute Drizzle migration `0002_workouts_and_progress.sql` creating relational workout tables, composite primary keys, and performance B-tree indexes (`idx_workout_sets_session_order`, `idx_workout_sessions_user_date`) (FR-011, FR-012).
- [ ] **CHKL-031C**: Seed exercise library in `backend/src/db/seeds/exercises.json` with 150+ standardized movements, primary/secondary muscle targets, equipment requirements, and Cloudflare R2 media URLs (FR-011).
- [ ] **CHKL-031D**: Implement Fastify workout service and endpoints:
  - `GET /api/v1/workout-programs` & `GET /api/v1/workout-programs/:id` (FR-011)
  - `GET /api/v1/exercises` with muscle group and equipment query filters (FR-011)
  - `POST /api/v1/workout-sessions` with `enforceSafetyGate` pre-handler hook (FR-012)
  - `PUT /api/v1/workout-sessions/:id/sets` logging reps, weight, and RPE (FR-012)
  - `POST /api/v1/workout-sessions/:id/complete` calculating volume tonnage and recording PRs in `progress_records` (FR-012, FR-017)
  - `POST /api/v1/activities/manual` with `enforceSafetyGate` pre-handler hook (FR-013)
  - `GET /api/v1/dashboard/daily-summary` (FR-016)
  - `GET /api/v1/progress/history` (FR-017)
- [ ] **CHKL-032**: Build conversational multi-stage onboarding questionnaire UI carousel (Stages A through F) with progress bar and auto-saving state notifiers (FR-003, FR-004).
- [ ] **CHKL-033**: Build Fitness Blueprint screen displaying 6-dimension classification badges, 7-day calendar preview, and "Accept Plan" CTA (User Journey 1).
- [ ] **CHKL-034**: Build Unified Home Dashboard showing today's workout card, streak count, and daily objective ring (FR-016).
- [ ] **CHKL-035**: Build Structured Program Catalog browser with filters for difficulty, goal, and equipment (FR-011).
- [ ] **CHKL-036**: Build Live Workout Execution screen:
  - Exercise instruction cues and Cloudflare R2 cached looping video demo (FR-011).
  - Set-by-set rep and weight logger with quick stepper controls (+ / -) (FR-012).
  - Immediate optimistic commit to local Drift SQLite database per completed set (FR-012, UJ-2).
  - Monotonic rest countdown timer with audio chime and haptic vibration trigger (EXT-003).
  - Superset group linking: suppress rest timer until final exercise of superset is logged (PRD Page 15).
- [ ] **CHKL-037**: Implement session recovery modal: on app launch, detect unfinalized sessions (`in_progress`) in SQLite and restore active timer and logged sets (FR-012, Edge Case 4).
- [ ] **CHKL-038**: Build Manual Activity Logging modal for off-platform sports and walks (FR-013).
- [ ] **CHKL-039**: Build Historical Analytics tab displaying volume tonnage progression, streak consistency, and personal records broken (FR-017).

### 5.4 Exit Criteria & Quality Gates
- App force-close / crash during active workout recovers 100% of completed sets upon restart.
- Set completion latency $< 16\text{ms}$ on mobile device (optimistic UI render).
- Video demo streams reliably with local disk caching preventing duplicate downloads.

### 5.5 Milestone Deliverable
- Fully functional mobile client capable of completing the full onboarding flow and executing live workouts offline.

---

## 6. Phase 4: Outdoor GPS Tracking & Offline Synchronization Engine

### 6.1 Scope & Objectives
Implement high-precision outdoor GPS tracking, background foreground services, speed-adaptive sampling, Kalman filtering, route polyline compression, privacy zone masking, and the client-server Write-Ahead Log (WAL) outbox sync protocol (**FR-019**, **EXT-002**, **User Journey 3**).

### 6.2 Entry Prerequisites
- Phase 3 Flutter client foundation operational.
- PostGIS extension active in PostgreSQL database.

### 6.3 Actionable Engineering Checklist
- [ ] **CHKL-040**: Integrate `flutter_background_geolocation` (or Android Foreground Service with `location` type and iOS `allowsBackgroundLocationUpdates`) (FR-019).
- [ ] **CHKL-041**: Implement speed-adaptive sampling: 5m distance filter, variable sample frequency, and auto-pause when velocity drops below $0.5\text{ m/s}$ for $\ge 5\text{s}$ (FR-019, Section 4.2).
- [ ] **CHKL-042**: Implement on-device Kalman filter with process noise floor $Q \ge 1.0\,\text{m}^2/\text{s}^2$, stationary variance floor ($4.0\,\text{m}^2$), and $3\sigma$ speed step detector rejecting multi-path glitches while instantly recovering from intersection pauses without map freezing (FR-019, Section 4.2).
- [ ] **CHKL-043**: Implement Great-Circle Haversine distance accumulation and automatic 1km split snapshot recorder (FR-019).
- [ ] **CHKL-044**: Build live outdoor activity tracking UI: high-contrast dark AMOLED mode, real-time pace/distance HUD, and lock-screen controls (FR-019, UJ-3).
- [ ] **CHKL-045**: Implement Google Encoded Polyline algorithm on mobile client, compressing GPS trackpoints into compact ASCII strings (FR-019).
- [ ] **CHKL-046**: Implement user Privacy Zones: configuration UI (home/work radius 200m–2,000m) and server-side route clipping algorithm masking public polylines with 250m anti-triangulation threshold, authentic metric invariance, and Abstract Activity Summary Card fallback for 100% masked routes (EXT-002, Section 4.4).
- [ ] **CHKL-047**: Define Drift SQLite `mutation_queue` table for offline write-ahead logging (WAL) (Section 3.1).
- [ ] **CHKL-048**: Build Outbox Synchronization Manager (`SyncOutboxManager`) listening to `connectivity_plus` transitions, quarantining failed poison pills locally into `local_dead_letter_queue`, and scheduling periodic background flushes via `workmanager` (Section 3.4).
- [ ] **CHKL-048A**: Define backend Drizzle ORM schemas in `backend/src/db/schema/activity.ts` for `activity_sessions` and `activity_routes` with PostGIS `GEOGRAPHY(LineString, 4326)` geometry, monthly range partitions, authentic metrics, and privacy flags; generate and execute migration `0003_activity_and_routes.sql` (FR-019).
- [ ] **CHKL-048B**: Implement Fastify GPS activity endpoints:
  - `POST /api/v1/activities/gps/start` with `enforceSafetyGate` pre-handler hook (FR-019)
  - `POST /api/v1/activities/gps/complete` decoding polylines, calculating elevation/splits, and applying privacy zone masking with 250m threshold (FR-019, EXT-002)
  - `GET /api/v1/activities/gps/:id` (FR-019)
- [ ] **CHKL-049**: Implement Fastify batch sync endpoint `POST /api/v1/sync/batch` with two-phase commit: Redis pre-gate check and distributed locking outside DB transaction, itemized SQL savepoints with poison pill isolation into `sync_quarantine`, and post-transaction Redis confirmation/lock release (Section 3.3).
- [ ] **CHKL-050**: Enforce UUIDv7 `Idempotency-Key` verification in Upstash Redis and transactional `sync_idempotency_records` table on all sync mutations (Section 3.3).

### 6.4 Exit Criteria & Quality Gates
- GPS tracking executes in background for 60 minutes with screen locked without OS process termination.
- Zero data loss when 5 consecutive workouts are recorded in Airplane Mode and flushed upon reconnection.
- Public route polylines strictly exclude waypoints located within configured privacy zones.

### 6.5 Milestone Deliverable
- Resilient outdoor activity tracking engine and verified offline-first outbox synchronization protocol.

---

## 7. Phase 5: Nutrition Logging, Localized Food Database & Meal Planning

### 7.1 Scope & Objectives
Implement localized food search, barcode scanning, Mifflin-St Jeor TDEE calorie budgeting, food diary logging, meal planning, and photo-assisted meal logging (**FR-014**, **FR-015**, **FR-024**, **EXT-001**, **User Journey 4**).

### 7.2 Entry Prerequisites
- Phase 3 mobile core and Phase 1 database operational.

### 7.3 Actionable Engineering Checklist
- [ ] **CHKL-051**: Seed PostgreSQL `food_catalog` with verified global items (USDA FoodData Central) and localized Nigerian food compositions (BioNutrient / NAFDAC: *Jollof rice, Egusi soup, Pounded yam, Suya, Akara, Moi moi*) with confidence ratings (FR-014).
- [ ] **CHKL-051A**: Define backend Drizzle ORM schemas in `backend/src/db/schema/nutrition.ts` for `food_catalog`, `food_portion_units`, `nutrition_entries`, `recipes`, `recipe_ingredients`, and `meal_plans` with GIN trigram indexes and composite index `(user_id, logged_date)`; generate and execute migration `0004_nutrition_and_portions.sql` (FR-014, FR-024).
- [ ] **CHKL-051B**: Implement Fastify nutrition endpoints:
  - `GET /api/v1/foods/search` with trigram similarity matching and portion unit expansion (FR-014)
  - `POST /api/v1/nutrition/entries` calculating macros via `food_portion_units` (FR-014)
  - `GET /api/v1/nutrition/summary` computing calories against BMR/TDEE budget (FR-015)
  - `POST /api/v1/recipes` & `GET /api/v1/recipes/:id` (FR-024)
- [ ] **CHKL-052**: Create GIN trigram indexes on `food_catalog(name)` and build server search endpoint `GET /api/v1/foods/search` with typo tolerance (FR-014).
- [ ] **CHKL-053**: Pre-populate local Drift SQLite database with top 500 common staple foods and configure SQLite FTS5 for instant zero-latency offline food search (FR-014).
- [ ] **CHKL-054**: Integrate Google ML Kit Barcode Scanning API in Flutter camera view and build lookup endpoint `GET /api/v1/foods/barcode/:code` with OpenFoodFacts fallback (FR-014).
- [ ] **CHKL-055**: Implement custom food creation flow for unlisted domestic items (`source = 'user_submitted'`, `confidence = 0.50`) (FR-014, Edge Case 9).
- [ ] **CHKL-056**: Implement TDEE & BMR calculation service using Mifflin-St Jeor equation:
  $$\text{BMR} = 10 \times \text{weight(kg)} + 6.25 \times \text{height(cm)} - 5 \times \text{age} + s$$
  where $s = +5$ (male), $s = -161$ (female), or exact unisex midpoint $s = -78$ when biological sex is omitted (Question A02 "Prefer not to say"), multiplied by activity factor, allocating protein, carb, and fat gram targets (FR-015).
- [ ] **CHKL-057**: Enforce physiological calorie deficit floor: clamp targets to $\ge 1,200\text{ kcal}$ (females), $\ge 1,500\text{ kcal}$ (males), and $\ge 1,350\text{ kcal}$ (unisex). When clamped, dynamically recalculate goal completion timeline and prescribe active caloric burn (cardio sessions, step targets at $0.04\text{ kcal/step}$) to bridge the deficit gap without metabolic starvation (FR-015, Edge Case 15).
- [ ] **CHKL-058**: Build Food Diary UI: meal slots (Breakfast, Lunch, Dinner, Snacks), portion scaler integrating `food_portion_units` colloquial measures (plates, wraps, ladles, derica cups, milk tins), and real-time macronutrient progress bars (FR-014, FR-015).
- [ ] **CHKL-059**: Implement Meal Planning & Recipe Library (`recipes`, `recipe_ingredients`, `meal_plans`) with automatic ingredient macro scaling (FR-024).
- [ ] **CHKL-060**: Build Photo-Assisted Meal Logging pipeline: Flutter camera capture, Cloudflare R2 presigned upload, vision LLM inference proposing items/portions, and interactive confirmation sheet (EXT-001).

### 7.4 Exit Criteria & Quality Gates
- Local SQLite FTS5 food search executes in $< 10\text{ms}$ on device without network connectivity.
- Food diary updates calorie budget remaining in real time across meal additions and deletions.
- Barcode scanning resolves valid UPC/EAN barcodes in $< 500\text{ms}$.

### 7.5 Milestone Deliverable
- Comprehensive nutrition logging engine tailored for Nigerian cuisine and global food staples.

---

## 8. Phase 6: Community Social Feeds, Challenges & Gamification

### 8.1 Scope & Objectives
Implement social follow relationships, community activity feeds, peer interactions (kudos/cheers, comments), and time-bound challenges powered by Upstash Redis Sorted Sets (**FR-020**, **FR-021**).

### 8.2 Entry Prerequisites
- Phase 3 workout logging and Phase 4 GPS telemetry operational.
- Upstash Redis instance accessible over TCP.

### 8.3 Actionable Engineering Checklist
- [ ] **CHKL-061**: Create Drizzle schemas for `user_follows`, `social_posts`, `social_interactions`, `challenges`, and `challenge_participants` (FR-020, FR-021).
- [ ] **CHKL-062**: Implement follow/unfollow endpoints and user social graph queries (FR-020).
- [ ] **CHKL-063**: Implement activity sharing endpoint `POST /api/v1/community/posts` linking workout sessions or GPS runs with configurable visibility (`public`, `followers`, `private`) (FR-020).
- [ ] **CHKL-064**: Enforce privacy boundary: private activities strictly excluded from community feed queries; public routes apply privacy zone clipping (FR-020, EXT-002).
- [ ] **CHKL-065**: Implement kudos and comments endpoints with real-time counter updates (`kudos_count`, `comments_count`) (FR-020).
- [ ] **CHKL-066**: Implement time-bound fitness challenge engine (`POST /api/v1/challenges/:id/join`) supporting distance and workout count metrics (FR-021).
- [ ] **CHKL-067**: Implement real-time challenge leaderboards using Upstash Redis Sorted Sets (`ZINCRBY`, `ZREVRANGE`, `ZREVRANK`) achieving sub-millisecond ranking queries (FR-021, Section 5.2).
- [ ] **CHKL-068**: Build Community Tab UI in Flutter: chronological social feed, activity cards with polyline route thumbnails, kudos button, comment sheets, and live challenge leaderboards (FR-020, FR-021).

### 8.4 Exit Criteria & Quality Gates
- Leaderboard ranking retrieval (`ZREVRANGE` top 50) executes in $< 5\text{ms}$ under 1,000 concurrent requests.
- Private workouts are 100% inaccessible to non-owner users across all feed queries.

### 8.5 Milestone Deliverable
- High-concurrency social community feed and real-time gamified challenge leaderboard engine.

---

## 9. Phase 7: Monetization, Billing Rails & Push Notifications

### 9.1 Scope & Objectives
Implement multi-tiered subscription billing (Free, Premium, Coaching), Nigerian payment rails via Paystack (recurring card tokens, Dedicated Virtual Accounts), mobile IAP via RevenueCat (Apple StoreKit 2 & Google Play Billing), and Firebase Cloud Messaging (FCM v1) push notifications (**FR-018**, **FR-027**).

### 9.2 Entry Prerequisites
- Active Paystack merchant account and RevenueCat project configured.
- Firebase project provisioned with APNs certificate and FCM service account key.

### 9.3 Actionable Engineering Checklist
- [ ] **CHKL-069**: Create Drizzle schemas for `subscriptions` and `billing_transactions` (FR-027).
- [ ] **CHKL-070**: Implement Paystack checkout initialization `POST /api/v1/billing/paystack/initialize` supporting NGN card tokens and Dedicated Virtual Accounts (FR-027).
- [ ] **CHKL-071**: Build Paystack webhook endpoint `POST /api/v1/billing/webhooks/paystack`:
  - Verify HMAC SHA512 signature against raw request body using `PAYSTACK_SECRET_KEY` (FR-027).
  - Enforce deterministic idempotency: construct key from `event.id`, `event.data.id`, domain entity IDs (`reference`, `subscription_code`, `invoice_code`), or raw body SHA-256 digest, preventing `lock:webhook:undefined` collisions (`SET lock:webhook:{event}:{id} PROCESSING NX EX 600`) (FR-027, Edge Case 6).
  - Enforce monotonic event timestamp ordering: compare incoming event timestamp against `subscriptions.last_event_timestamp` under row-level lock (`for update`), discarding out-of-order retries and preventing cancellation resurrection (FR-027).
  - Update subscription status in PostgreSQL and refresh Redis entitlement cache (`ENTITLEMENT:USER:{id}`) (FR-027).
- [ ] **CHKL-072**: Implement anchored 3-day dunning grace period on Paystack `invoice.payment_failed`: anchor `grace_period_expires_at` strictly to the first failed billing attempt (`first_payment_failed_at`), preventing daily debit retries from resetting the grace clock indefinitely (FR-027, Edge Case 7).
- [ ] **CHKL-073**: Integrate RevenueCat Flutter SDK (`purchases_flutter`) in mobile app to comply with Apple Guideline 3.1.1 and Google Play Billing requirements (FR-027).
- [ ] **CHKL-074**: Build RevenueCat webhook receiver `POST /api/v1/billing/webhooks/revenuecat` syncing IAP renewals and cancellations into central `subscriptions` table (FR-027).
- [ ] **CHKL-075**: Implement cross-platform entitlement validator: grant premium features if user has active subscription via Paystack OR Apple/Google IAP (FR-027).
- [ ] **CHKL-076**: Integrate Firebase Cloud Messaging (FCM v1 REST API) with HTTP/2 transport for mobile push delivery (FR-018).
- [ ] **CHKL-077**: Build push notification dispatch workers in Fastify triggered by Upstash QStash crons (workout reminders, streak danger alerts, silent data sync) (FR-018).

### 9.4 Exit Criteria & Quality Gates
- Duplicate Paystack webhooks processed idempotently without duplicate subscription credits.
- Mobile IAP purchases correctly unlock premium entitlements in both mobile app and web portal.
- Push notification dispatch respects user notification preferences and timezone quiet hours.

### 9.5 Milestone Deliverable
- Automated multi-currency subscription monetization engine and transactional push delivery pipeline.

---

## 10. Phase 8: Production Launch Hardening, Observability & NDPA Compliance Audit

### 10.1 Scope & Objectives
Implement wearable health platform sync, AI coaching explainability, catalog CMS admin, end-to-end observability (Pino, Sentry, OpenTelemetry), p95 < 500ms load testing, and formal NDPA 2023 compliance audit readiness (**FR-025**, **FR-026**, **EXT-005**, **User Journey 5**, **User Journey 6**).

### 10.2 Entry Prerequisites
- All previous phases (Phase 0 through Phase 7) complete and verified.
- Staging environment mirroring production infrastructure.

### 10.3 Actionable Engineering Checklist
- [ ] **CHKL-078**: Implement Apple HealthKit and Android Health Connect synchronization worker for passive step counts and resting heart rate (FR-025).
- [ ] **CHKL-079**: Implement AI Coaching Explainability endpoint `POST /api/v1/ai/coach-query` with guardrailed prompt templates strictly preventing unverified medical prescriptions (FR-026).
- [ ] **CHKL-080**: Build Catalog Admin CMS web module for managing exercises, video URLs, and verified food nutritional entries (EXT-005).
- [ ] **CHKL-081**: Configure Pino structured JSON logging across Fastify services with `X-Correlation-ID` request tracing (Section 10).
- [ ] **CHKL-082**: Configure Sentry error monitoring on Fastify (`@sentry/node`) and Flutter (`sentry_flutter`) with PII/health data sanitization (Section 10).
- [ ] **CHKL-083**: Implement Prometheus metrics exporter (`fastify-metrics`) at `/metrics` and build Grafana dashboards monitoring p95 latency, event loop lag, and connection pools.
- [ ] **CHKL-084**: Execute Autocannon load testing against API gateway: verify 1,500 req/sec sustained throughput with p95 latency $< 500\text{ms}$.
- [ ] **CHKL-085**: Implement NDPA Data Portability ZIP export worker `POST /api/v1/users/me/export-data` producing machine-readable JSON/CSV bundles (NDPA Section 38).
- [ ] **CHKL-086**: Implement NDPA 30-day soft-delete account purge worker `DELETE /api/v1/users/me` permanently scrubbing PII, health logs, and R2 media (NDPA Section 34).
- [ ] **CHKL-087**: Execute 72-hour breach reporting simulation drill and assemble Data Protection Officer (DPO) compliance dossier for NDPC registration.

### 10.4 Exit Criteria & Quality Gates
- Autocannon load tests confirm p95 latency $< 500\text{ms}$ under 1,500 req/sec peak concurrency.
- Zero high/critical vulnerabilities reported in static security scans (Trivy, Snyk, npm audit).
- Complete NDPA 2023 compliance audit checklist passed and verified by forensic auditor.

### 10.5 Milestone Deliverable
- Production-certified, hardened, and NDPA-compliant Unified Fitness Platform ready for commercial public launch.
