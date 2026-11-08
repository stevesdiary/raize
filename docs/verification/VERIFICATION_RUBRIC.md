# Comprehensive Verification Rubric & Acceptance Standards

**Document Version**: 1.0.0  
**Status**: Authoritative Quality & Verification Rubric  
**Date**: 2026-11-07  
**Scope**: Full Verification Matrix for Unified Fitness Platform (`raize.fit`)  
**Cross-References**: FR-001 through FR-027, User Journeys 1–6, NFRs, NDPA 2023  

---

## 1. Executive Summary & Quality Gates

This verification rubric provides the authoritative standard for auditing and validating the Unified Fitness Platform. Every requirement, non-functional constraint, and end-to-end user journey is cross-referenced with explicit test verification methods, input parameters, expected outputs, failure thresholds, and regulatory compliance checks.

A forensic auditor or automated test suite evaluates each requirement against three status classifications:
- **PASS**: Meets 100% of functional assertions, performance budgets, and error invariants.
- **DEGRADED**: Functional assertions pass, but latency, memory, or battery consumption exceeds standard SLA thresholds by $< 20\%$.
- **FAIL**: Any functional regression, unhandled exception, data loss, security vulnerability, or regulatory breach.

---

## 2. Functional Requirements Verification Matrix (FR-001 through FR-027)

| Req ID | Requirement Description | Priority | Test Method & CLI Command | Input Test Vector | Expected Output / Assertion | Failure Criteria |
|---|---|---|---|---|---|---|
| **FR-001** | User Auth & Session Lifecycle | P0 | Automated Integration (`pnpm test:integration auth`) | `POST /auth/register` with valid email & strong password; followed by `POST /auth/login` | HTTP 200, returns short-lived access JWT (15m TTL) and refresh token (30d TTL); password hashed with Argon2id | Password stored in cleartext, access token > 15m, or missing refresh rotation |
| **FR-002** | User Profile Management | P0 | Integration (`pnpm test:integration profile`) | `PATCH /users/me` `{ height: 180, weight: 75, unit_system: 'metric' }` | HTTP 200; `user_profiles` updated; metrics stored in normalized cm and kg; age calculated from DOB | Underage DOB (<18) accepted without error; units stored inconsistently |
| **FR-003** | Multi-Stage Questionnaire | P0 | E2E (`pnpm test:e2e assessment`) | `POST /assessments`, `PUT /assessments/:id/responses` with Stages A through F answers | HTTP 200; `fitness_assessments` status advances from `in_progress` to `completed`; timestamp recorded | Assessment marked completed with mandatory questions (A01, E01–E05) missing |
| **FR-004** | Assessment Progress Persistence | P0 | Integration (`pnpm test:integration assessment-draft`) | User fills Stage A & B, closes app, reopens, calls `GET /assessments/:id` | HTTP 200; returns exactly saved answers for Stages A & B; `completion_percentage: 33` | Data loss upon session drop-off; user forced to restart from Stage A |
| **FR-005** | Assessment Versioning & History | P0 | Integration (`pnpm test:integration assessment-version`) | User retakes assessment: `POST /assessments` after previous completed assessment | New assessment created with `version: 2`; `version: 1` remains read-only and immutable | Direct `PUT` mutation allowed on an already completed assessment record |
| **FR-006** | 6-Dimension Classification | P0 | Unit (`pnpm test:unit classification`) | Assessment with C01="Advanced" and C02="Never (0 days/wk)" | Evaluates to: Goal=WeightLoss, Experience=Beginner (downgraded for safety), Baseline=Sedentary | Classification engine accepts inconsistent self-rating, creating injury hazard |
| **FR-007** | Health & Safety Gatekeeper | P0 | Unit & Integration (`pnpm test:integration safety-gate`) | Stage E response where Question E05 (chest pain / syncope) = "Yes" | Immediate halt; `safety_status = 'exercise_paused_pending_assessment'`; HTTP 403 on workout generation | Workout plan generated despite affirmative cardiac red-flag symptom |
| **FR-008** | Activity Recommender Scoring | P0 | Unit (`pnpm test:unit scoring`) | User profile with weight loss goal, home environment, dumbbells only | Candidate activities ranked via $S(a,u) = \sum w_i r_i$; high score for dumbbell circuits, 0 for barbell squats | Excluded activity appears in recommendation; scoring weights do not sum to 1.00 |
| **FR-009** | Weekly Schedule Generator | P0 | Unit & Integration (`pnpm test:integration schedule-gen`) | Recommend run for user with 3 available days (D01=3) and 30 min (D02=30) | 7-day schedule with exactly 3 training days and $\ge 2$ rest/recovery days; session durations $\le 30\text{min}$ | Consecutive maximal-effort days scheduled for beginner; duration exceeds preference |
| **FR-010** | Plan Customization & Revalidation | P0 | Integration (`pnpm test:integration plan-custom`) | `POST /recommendations/:id/customize` swapping Barbell Squat for Knee Injury user | Substitution evaluated; if replacement stresses injured joint, rejected with HTTP 422 warning | Unsafe exercise permitted in customized plan; schedule balance violated |
| **FR-011** | Structured Program Library | P0 | Integration (`pnpm test:integration program-catalog`) | `GET /workout-programs?goal=strength&level=intermediate` | HTTP 200; paginated list of programs with exercise IDs, week breakdowns, and R2 media URLs | Missing exercise instructional metadata or broken Cloudflare R2 video URLs |
| **FR-012** | Live Workout Set Logging | P0 | Mobile Local & API (`flutter test test/workout_test.dart`) | Log Set 1 (10 reps, 80kg, RPE 8.0) offline, then tap "Complete Workout" | Set logged immediately to local Drift SQLite (<16ms); synced to PostgreSQL on reconnect; PRs updated | Data loss on app background kill; unhandled concurrency on set sequence ordering |
| **FR-013** | Manual Activity Logging | P0 | Integration (`pnpm test:integration manual-activity`) | `POST /activities/manual` `{ type: 'swimming', duration_min: 45, exertion: 7 }` | HTTP 201; `activity_sessions` created; calories calculated; added to daily activity ring | Duration $\le 0$ accepted; invalid activity type accepted |
| **FR-014** | Food Search & Diary Logging | P0 | Integration & Mobile (`pnpm test:integration food-search`) | `GET /foods/search?q=jollof` and `POST /nutrition/entries` for lunch slot | HTTP 200; trigram search matches Nigerian Jollof Rice; diary updates calorie and macro totals | Food search returns 0 results for verified Nigerian staples; macros not scaled |
| **FR-015** | Calorie & Macro Target Tracking | P0 | Unit & Integration (`pnpm test:unit nutrition-tdee`) | User: Male, 80kg, 180cm, age 30, moderate activity, goal weight loss | BMR computed via Mifflin-St Jeor = 1,780 kcal; TDEE = 2,759 kcal; deficit target = 2,259 kcal; macro split | Calorie target falls below biological safe floor (<1200 kcal female, <1500 kcal male) |
| **FR-016** | Unified Home Dashboard | P0 | Integration (`pnpm test:integration dashboard`) | `GET /dashboard/daily-summary` for active user | HTTP 200; aggregated view containing greeting, today's workout card, nutrition ring, and streak | Aggregation query exceeds 350ms p95 latency budget; stale cached data after workout |
| **FR-017** | Historical Telemetry & Analytics | P0 | Integration (`pnpm test:integration progress-analytics`) | `GET /progress/history?metric=weight&range=90d` | HTTP 200; chronological time-series data points; rolling averages; volume tonnage progression | Unordered dates in response; missing volume calculations |
| **FR-018** | Push Reminders & Alerts | P1 | Worker E2E (`pnpm test:e2e push-reminders`) | QStash triggers scheduled workout reminder cron at scheduled workout hour | FCM v1 payload dispatched to registered device token; HTTP 200; respects quiet hours | Push notification sent during user-configured quiet hours or when disabled |
| **FR-019** | Outdoor GPS Activity Tracking | P1 | Sensor Simulation & API (`pnpm test:integration gps-tracking`) | Stream 600 GPS trackpoints (10 min run), simulate tunnel outage, call `POST /activities/gps/complete` | HTTP 201; encoded polyline generated; distance matches Haversine sum ($\pm 2\%$); splits generated | Jitter spikes ($> 30\text{m}$ error) corrupt route; straight-line distance exceeds actual route |
| **FR-020** | Social Feed & Peer Interactions | P1 | Integration (`pnpm test:integration social-feed`) | User shares completed run to feed; followed friend gives kudos and comments | Post rendered in follower feed; kudos incremented; private workouts excluded from feed | Private activity visible to non-owner; unauthenticated user can comment |
| **FR-021** | Challenges & Leaderboards | P1 | Load & Integration (`pnpm test:integration leaderboards`) | 100 concurrent athletes log runs contributing to "May 50km Challenge" | Redis Sorted Set `challenge:{id}:leaderboard` updated via `ZINCRBY`; `ZREVRANGE` returns top 50 in $< 5\text{ms}$ | Leaderboard query locks relational DB; rankings out of sync with logged distance |
| **FR-022** | Periodic Fitness Reassessment | P1 | Integration (`pnpm test:integration reassessment`) | User completes 4-week check-in: logs new weight (-2kg) and manageability rating | HTTP 200; comparison report generated; adaptation engine triggers progressive volume increase | Reassessment prompts user when check-in is not due; updates overwrite history |
| **FR-023** | Continuous Plan Adaptation | P1 | Unit (`pnpm test:unit adaptation-engine`) | User logs 3 consecutive sessions as "Too Hard" (RPE 9.5) and skips 1 session | Adaptation engine reduces next week's working weight by 5% and suggests 15m shorter session | Engine fails to adjust loads, causing chronic overtraining fatigue |
| **FR-024** | Meal Planning & Recipe Library | P1 | Integration (`pnpm test:integration recipes`) | Create recipe: "Egusi Soup with Fish" with 4 ingredients; schedule for dinner | Recipe entity saved with aggregated macro breakdown per serving; meal plan updated | Macro sum does not equal sum of individual ingredients; negative servings accepted |
| **FR-025** | HealthKit / Health Connect Sync | P2 | Mobile Platform Mock (`flutter test test/health_sync_test.dart`) | Simulate 8,500 passive steps and 62 bpm resting HR from Apple HealthKit | Steps synced to daily activity dashboard; conflict resolution avoids double-counting active runs | Passive steps overwrite GPS run distance; duplicate step counts |
| **FR-026** | AI Coaching Explainability | P2 | Integration (`pnpm test:integration ai-coaching`) | `POST /ai/coach-query` asking: "Why did my workout volume decrease this week?" | Contextual explanation citing deload week rules and high reported RPE; safety disclaimer appended | AI generates unverified medical prescription or rehabilitation claim |
| **FR-027** | Monetization & Subscription Billing | P1 | Integration & Webhook (`pnpm test:integration billing-paystack`) | Paystack webhook `charge.success` received with valid HMAC SHA512 signature | Webhook verified; idempotency lock prevents duplicate processing; user upgraded to `PREMIUM` | Unsigned webhook accepted; duplicate webhook doubles subscription duration |

---

## 3. End-to-End User Journey Verification Protocols

```
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ UJ-1: Onboarding, Assessment & Blueprint Activation                                            │
│ Steps: Register (18+) ──► Stages A–F ──► PAR-Q+ Screening ──► 7-Day Blueprint ──► Accept       │
│ Validation: Users record created; assessment immutable; active workout schedule generated.     │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ UJ-2: Structured Workout Execution & Live Set Logging                                          │
│ Steps: Dashboard ──► Start Session ──► Log Sets/Reps/Weight ──► Rest Timer ──► Finish Workout   │
│ Validation: SQLite local commit < 16ms; PR detection; streak incremented; volume calculated.   │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ UJ-3: Outdoor GPS Activity Tracking & Route Privacy Masking                                    │
│ Steps: Select Run ──► Foreground GPS ──► Live HUD ──► Privacy Zone Clipping ──► Save & Sync    │
│ Validation: Distance accurate via Haversine; home radius masked; polyline compressed.          │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ UJ-4: Localized Nutrition Diary & Calorie Budgeting                                            │
│ Steps: Open Diary ──► Search Jollof Rice / Scan Barcode ──► Log Portion ──► Macro Bars Animate  │
│ Validation: BioNutrient composition loaded; consumed macros subtracted from budget in real time│
└────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ UJ-5: Goal Recalibration & Program Re-Blueprint                                                │
│ Steps: Settings ──► Switch Goal to Hypertrophy ──► Compare Diff ──► Confirm New Blueprint       │
│ Validation: Old program archived; new volume structure active; historical workout logs intact. │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                │
                                                ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ UJ-6: Periodic Progress Review & Continuous Adaptation                                         │
│ Steps: Check-in Prompt ──► Log Weight & Manageability ──► Review Adaptation ──► Approve Changes │
│ Validation: Weight trend updated; progressive overload applied to upcoming mesocycle.          │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 3.1 User Journey 1: New User Onboarding & Assessment
- **Objective**: Verify that a new athlete can register, provide explicit health consent, complete the 6-stage assessment, navigate the PAR-Q+ safety screen, and activate their weekly blueprint.
- **Verification Script**: `pnpm test:e2e user-journey-1`
- **Pass Assertions**:
  1. `user_consents` record contains verified IP hash and privacy policy version (NDPA Section 30).
  2. `fitness_assessments` status is `completed` with immutable response state.
  3. Generated blueprint contains exactly $N$ workout sessions corresponding to available days (D01).
  4. Response time from assessment completion to blueprint display is $< 1,500\text{ms}$.

### 3.2 User Journey 2: Workout Execution & Set Logging
- **Objective**: Verify that an athlete can execute a structured session, log weights/reps offline, utilize rest timers, and finish with zero data loss.
- **Verification Script**: `flutter test integration_test/uj2_workout_execution_test.dart`
- **Pass Assertions**:
  1. Each set checkmark commits to local SQLite in $< 16\text{ms}$ with optimistic UI state update.
  2. App kill simulation mid-workout restores active elapsed timer and completed sets on relaunch.
  3. Completion calculates total volume tonnage ($\sum \text{reps} \times \text{weight}$) with 100% precision.
  4. Personal Records (PRs) update in `progress_records` if working weight exceeds historical maximum.

### 3.3 User Journey 3: Outdoor GPS Activity Tracking
- **Objective**: Verify that an outdoor runner can record a run with background resilience, Kalman filtering, accurate splits, and location privacy masking.
- **Verification Script**: `flutter test integration_test/uj3_gps_tracking_test.dart`
- **Pass Assertions**:
  1. Ongoing Android Foreground Service notification displays live distance and pace while device screen is locked.
  2. Great-Circle Haversine calculation matches ground truth within $\pm 2\%$.
  3. Encoded polyline compresses 3,600 raw GPS fixes to an ASCII string $< 10\text{KB}$.
  4. Polyline waypoints within 500m of user's configured home privacy zone are clipped from public route.

### 3.4 User Journey 4: Nutrition Diary & Localized Food Logging
- **Objective**: Verify that an athlete can search local Nigerian foods, scan barcodes, log meals, and view real-time calorie budgets.
- **Verification Script**: `flutter test integration_test/uj4_nutrition_logging_test.dart`
- **Pass Assertions**:
  1. Offline food search for "Jollof Rice" returns instant results from local Drift SQLite FTS5 ($< 10\text{ms}$).
  2. Logging a 250g portion correctly scales calories, protein, carbs, and fat according to verified BioNutrient values.
  3. Daily remaining calorie budget decrements instantaneously across UI widgets.

### 3.5 User Journey 5: Goal Modification & Re-Blueprint
- **Objective**: Verify that an athlete can change their primary goal, review a side-by-side blueprint diff, and transition programs without destructive overwrites.
- **Verification Script**: `pnpm test:e2e user-journey-5`
- **Pass Assertions**:
  1. Previous `workout_programs` status updated to `archived`; historical set logs remain linked to original program.
  2. New active program instantiated with updated volume, exercise selection, and calorie targets.
  3. Dashboard renders new pathway emphasis immediately upon confirmation.

### 3.6 User Journey 6: Periodic Progress Review & Adaptation
- **Objective**: Verify that the system prompts periodic reviews, analyzes adherence and manageability, and adjusts training volume.
- **Verification Script**: `pnpm test:e2e user-journey-6`
- **Pass Assertions**:
  1. User adherence $\ge 85\%$ with "Too Easy" feedback triggers a progressive overload recommendation ($+2.5\text{kg}$ to $+5\text{kg}$ on compound lifts).
  2. User adherence $< 50\%$ with "Impractical" feedback triggers a deload recommendation reducing days/week.
  3. Next check-in date scheduled 14 to 28 days in future.

---

## 4. Non-Functional Requirements (NFR) Verification Matrix

| Category | SLA / Budget Target | Test Tool & Method | Assertion & Validation Procedure | Failure Threshold |
|---|---|---|---|---|
| **API Latency** | p95 $< 500\text{ms}$ across all REST endpoints | Autocannon (`pnpm --filter backend run bench:p95`) | Benchmark 1,000 concurrent requests against `/dashboard/daily-summary` and `/foods/search` | p95 $\ge 500\text{ms}$ or error rate $> 0.1\%$ |
| **Subsystem Latency** | Auth JWT verify $< 0.1\text{ms}$; DB read $< 50\text{ms}$ | OpenTelemetry & Pino metrics | Inspect internal span durations during load runs | Database query duration $\ge 50\text{ms}$ p95 |
| **Throughput** | 1,500 req/sec sustained peak | Autocannon load generator | Run 10-minute load test simulating morning peak (06:00–08:30 WAT) | 5xx errors $> 0.01\%$ or container crash |
| **Offline Sync** | Zero data loss on intermittent connectivity | Network Link Conditioner | Simulate 3G drop, queue 20 mutations, restore network, inspect PostgreSQL | Any dropped set, duplicate set, or sync deadlock |
| **Battery Consumption**| $< 12\%$ battery drain per 60 min GPS run | Android Battery Historian / iOS Instruments | Execute continuous background GPS tracking for 60 minutes with screen off | Battery consumption $> 15\%$ per hour |
| **Bandwidth Budget** | Average REST JSON payload $< 10\text{KB}$; Video $< 800\text{kbps}$ | Chrome DevTools / Charles Proxy | Inspect Content-Length of Gzip/Brotli responses and video stream bitrates | Uncompressed JSON payloads or video $> 1.0\text{Mbps}$ |
| **Data Encryption** | AES-256-GCM application-level encryption | PostgreSQL Direct Inspection | `SELECT encrypted_notes FROM health_restrictions;` must return `v{version}:{iv}:{tag}:{ciphertext}` | Cleartext medical notes readable in database |
| **NDPA Data Export**| Machine-readable ZIP export in $< 60\text{s}$ | E2E Integration (`pnpm --filter backend run test:e2e export`) | Trigger `POST /users/me/export-data`; download ZIP; verify JSON/CSV schema | Corrupted archive, missing health logs, or timeout |
| **NDPA Data Erasure**| Permanent purge after 30-day grace period | Scheduled Worker Simulation | Trigger `DELETE /users/me`; fast-forward clock 30 days; verify all PII deleted | Orphaned health records or media remaining in R2 |

---

## 5. Automated Verification Test Suite Execution Command Reference

```bash
# ==============================================================================
# UNIFIED FITNESS PLATFORM: COMPLETE AUDIT & VERIFICATION TEST RUNNER
# ==============================================================================

# 1. Static Analysis & Lint Verification
pnpm --filter backend run lint
pnpm --filter backend run typecheck
cd mobile && flutter analyze && cd ..

# 2. Backend Unit Test Suite (Scoring Algorithm, TDEE, Polyline Compression)
pnpm --filter backend run test:unit

# 3. Backend Integration Test Suite (Fastify Routes, PostgreSQL, Redis, QStash)
pnpm --filter backend run test:integration

# 4. Mobile Client Unit & Widget Tests
cd mobile && flutter test && cd ..

# 5. Mobile Offline Synchronization Tests
cd mobile && flutter test test/offline_sync_test.dart && cd ..

# 6. Mobile End-to-End Integration Tests (Emulator / Simulator)
cd mobile && flutter test integration_test/ && cd ..

# 7. Full User Journeys 1 through 6 End-to-End Verification
pnpm --filter backend run test:e2e

# 8. High-Concurrency Performance & SLA Verification (Autocannon)
pnpm --filter backend run bench:p95

# 9. NDPA 2023 Security & Cryptographic Compliance Audit
pnpm --filter backend run audit:ndpa
```
