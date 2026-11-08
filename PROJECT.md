# Project: Unified Fitness Platform (raize.fit)

## 1. Architecture Overview

### 1.1 System Vision & Operating Paradigm
The **Unified Fitness Platform** (`raize.fit`) is an integrated health, training, and nutrition ecosystem combining the core strengths of three industry precedents:
- **MyFitnessPal**: Comprehensive food diary, macronutrient and calorie budgeting, barcode scanning, and localized culinary composition.
- **Strava**: Outdoor endurance telemetry, high-precision GPS route tracking, split analysis, segment privacy masking, and community social challenges.
- **LADDER**: Structured progressive resistance training, periodized programs, exercise instruction media, and live set-by-set execution tracking.

The entire platform operates on a closed-loop adaptive cybernetic paradigm:
$$\text{Assess} \longrightarrow \text{Understand} \longrightarrow \text{Recommend} \longrightarrow \text{Act} \longrightarrow \text{Measure} \longrightarrow \text{Adapt}$$

```
                                  ┌───────────────────────────┐
                                  │   Stage A-F Assessment    │
                                  └─────────────┬─────────────┘
                                                │
                                                ▼
                                  ┌───────────────────────────┐
                                  │ 6-D Classification Engine │
                                  └─────────────┬─────────────┘
                                                │
                                                ▼
                                  ┌───────────────────────────┐
                                  │ Weighted Activity Scorer  │
                                  │   S(a,u) = Σ (wi * ri)    │
                                  └─────────────┬─────────────┘
                                                │
                                                ▼
                                  ┌───────────────────────────┐
                                  │ Weekly Blueprint Generator│
                                  └─────────────┬─────────────┘
                                                │
                         ┌──────────────────────┴──────────────────────┐
                         ▼                                             ▼
          ┌─────────────────────────────┐               ┌─────────────────────────────┐
          │  Structured Workout Tracker │               │   Outdoor GPS Activity Run  │
          │  (Sets, Reps, Weight, RPE)  │               │ (Pace, Elevation, Polyline) │
          └──────────────┬──────────────┘               └──────────────┬──────────────┘
                         │                                             │
                         └──────────────────────┬──────────────────────┘
                                                │
                                                ▼
                                  ┌───────────────────────────┐
                                  │ Nutrition & Energy Balance│
                                  │ (TDEE, Intake vs Deficit) │
                                  └─────────────┬─────────────┘
                                                │
                                                ▼
                                  ┌───────────────────────────┐
                                  │ 2-4 Week Progress Review  │
                                  │ & Continuous Adaptation   │
                                  └─────────────┬─────────────┘
                                                │
                                                └────► [Recalibrate Blueprint]
```

### 1.2 Target Market & Regional Strategy
- **Initial Commercial Launch**: **Nigeria** (Lagos, Abuja, Port Harcourt urban hubs), followed by pan-African and international global rollout.
- **Demographic Boundary**: **18+ years old** for initial launch. Strict safety controls prevent automated caloric deficit prescriptions or extreme training loads for minors. Minors requiring specialized youth-safeguarded programs are deferred to post-MVP releases.
- **African Infrastructure Optimizations**: Designed for spotty 2G/3G/4G network coverage, expensive mobile data tariffs ($1–$2/GB relative to local purchasing power), and dual-currency payment dynamics (Nigerian Naira NGN via Paystack and USD/EUR via App Store and Google Play).

### 1.3 High-Level Technology Topology

```
+---------------------------------------------------------------------------------------+
|                                    CLIENT TIER                                        |
|  +---------------------------------------------------------------------------------+  |
|  |                     Flutter Mobile Client (iOS & Android)                       |  |
|  |  - Presentation: Riverpod 2.x StateNotifiers + Declarative GoRouter             |  |
|  |  - Domain: Clean Architecture Use Cases, Repositories Contracts, Pure Dart      |  |
|  |  - Data: Drift (SQLite) Local DB + Offline WAL Mutation Queue + Dio Client      |  |
|  |  - Background: Flutter Background Geolocation + Foreground Service + WorkManager|  |
|  +---------------------------------------------------------------------------------+  |
+-------------------------------------------|-------------------------------------------+
                                            | HTTPS / TLS 1.3 (Signed JWT, Idempotency)
                                            v
+---------------------------------------------------------------------------------------+
|                                    EDGE / INGRESS                                     |
|  +---------------------------------------------------------------------------------+  |
|  |       Cloudflare Edge Network: Global CDN + DDoS Protection + SSL Termination   |  |
|  +---------------------------------------------------------------------------------+  |
+-------------------------------------------|-------------------------------------------+
                                            | Reverse Proxy / Load Balancer
                                            v
+---------------------------------------------------------------------------------------+
|                             API APPLICATION TIER (FASTIFY)                            |
|  +---------------------------------------------------------------------------------+  |
|  |  Fastify 5.x Modular Monolith Runtime (Node.js 22 LTS, TypeScript 5.x)          |  |
|  |  - Find-My-Way High-Throughput Radix Tree Router                                |  |
|  |  - TypeBox Ahead-of-Time JSON Schema Compilation                                |  |
|  |  - Security: @fastify/jwt (Asymmetric EdDSA/RS256), @fastify/rate-limit         |  |
|  |  - Observability: Pino Structured JSON Logging + OpenTelemetry Tracing         |  |
|  |                                                                                 |  |
|  |  Domain Modules:                                                                |  |
|  |  [ Auth & Identity ]     [ Assessment Engine ]    [ Recommendation Core ]       |  |
|  |  [ Workout Execution ]   [ Nutrition Engine ]     [ GPS Telemetry & Routes ]    |  |
|  |  [ Social & Feed ]       [ Billing & Payments ]   [ NDPA 2023 Compliance ]      |  |
|  +---------------------------------------------------------------------------------+  |
+--------------------|-----------------------------|-----------------------|------------+
                     |                             |                       |
                     v                             v                       v
+-----------------------------+  +----------------------------+  +----------------------+
|       DATABASE TIER         |  |      CACHE & JOBS TIER     |  |    STORAGE TIER      |
|  PostgreSQL 16 + PostGIS    |  |  Upstash Redis & QStash    |  |  Cloudflare R2       |
|                             |  |                            |  |                      |
|  - Drizzle ORM Type-Safe    |  |  - Upstash Redis (TCP/REST)|  |  - S3 Compatible API |
|  - postgres.js Driver       |  |    * Active Session Cache  |  |  - $0 Egress Fees    |
|  - PgBouncer Pool (20 conn) |  |    * Rate Limiting Windows |  |  - Presigned PUT URLs|
|  - PostGIS LineString       |  |    * Leaderboards (ZSET)   |  |  - Cloudflare Edge   |
|  - pg_trgm Food Search      |  |  - Upstash QStash Engine   |  |    Video Streaming   |
|  - Monthly Range Partitions |  |    * Serverless HTTP Webhook|  |  - User Avatars &   |
|  - AES-256 Field Encryption |  |    * Crons (Streaks/Review)|  |    Meal Photographs  |
|                             |  |    * Retries & DLQ Routing |  |                      |
+-----------------------------+  +----------------------------+  +----------------------+
```

---

## 2. Feature Inventory

The platform encompasses 27 primary Functional Requirements (FR-001 through FR-027) categorized by engineering priority (P0: Essential MVP, P1: Commercial Launch, P2: Post-Launch Scale) and 5 architectural extensions discovered during specification mining.

| Feature ID | Category | Feature Name | Description | Priority | Assigned Milestone | Status |
|---|---|---|---|---|---|---|
| **FR-001** | Authentication | User Auth & Session Lifecycle | Secure registration, login, logout, password recovery, OAuth2 (Apple, Google), asymmetric JWT issuance, refresh token rotation with reuse detection. | P0 | Milestone 1 | Planned |
| **FR-002** | Profile | User Profile & Demographics | Physical characteristics (height, weight, DOB), country, measurement unit preference (metric/imperial), avatar. Normalized to metric in DB. | P0 | Milestone 1 | Planned |
| **FR-003** | Assessment | Multi-Stage Fitness Questionnaire | 6-stage structured assessment (Stages A–F: Demographics, Goals, Baseline, Preferences, Safety, Motivation). Interactive completion in 3–5 min. | P0 | Milestone 2 | Planned |
| **FR-004** | Assessment | Assessment Progress Persistence | Auto-save responses at each stage to local storage and remote draft state to eliminate onboarding abandonment data loss. | P0 | Milestone 2 | Planned |
| **FR-005** | Assessment | Assessment Versioning & History | Immutably version completed assessments. Retakes generate version $N+1$, preserving historical auditability. | P0 | Milestone 2 | Planned |
| **FR-006** | Classification | 6-Dimension User Classification | Classifies completed assessments across Goal, Experience, Baseline, Environment, Availability, and Safety status. Resolves self-report conflicts. | P0 | Milestone 2 | Planned |
| **FR-007** | Safety | Health Screening & Medical Gate | Safety-critical gatekeeper (Stage E). Excludes contraindicated movements for injuries. If critical cardiac symptoms (E05) present, halts workout generation. | P0 | Milestone 2 | Planned |
| **FR-008** | Recommendations | Personalized Activity Recommender | Computes suitability score $S(a,u) = \sum_{i=1}^7 w_i \cdot r_i(a,u)$ across 7 dimensions (Goal 30%, Pref 20%, Exp 15%, Equip 10%, Time 10%, Env 10%, Sec 5%). | P0 | Milestone 2 | Planned |
| **FR-009** | Recommendations | Weekly Workout Schedule Generator | Builds balanced 7-day training schedule mapping recommended activities to days, respecting recovery intervals and user session duration. | P0 | Milestone 2 | Planned |
| **FR-010** | Recommendations | Plan Customization & Revalidation | Enables users to swap exercises, change training days, and adjust duration. Revalidates substitutions against safety constraints. | P0 | Milestone 2 | Planned |
| **FR-011** | Workouts | Structured Program Library | Curated progressive training programs (strength, hypertrophy, running, mobility) with video instruction links and coaching notes. | P0 | Milestone 3 | Planned |
| **FR-012** | Workouts | Live Workout Execution & Set Logging | Real-time tracking of sets, reps, weight, RPE, rest countdown timers, and completion timestamps. Optimistic offline UI. | P0 | Milestone 3 | Planned |
| **FR-013** | Activity | Manual Activity Logging | Manual entry for off-platform sports, swimming, walking, and martial arts with duration, estimated distance, and perceived exertion. | P0 | Milestone 3 | Planned |
| **FR-014** | Nutrition | Food Search & Diary Logging | Multi-source food database search (USDA + Nigerian staples), meal slot allocation (Breakfast, Lunch, Dinner, Snacks), and portion scaling. | P0 | Milestone 5 | Planned |
| **FR-015** | Nutrition | Calorie & Macro Target Tracking | Daily energy expenditure calculation (Mifflin-St Jeor BMR $\times$ activity multiplier) and real-time tracking of consumed vs remaining macros. | P0 | Milestone 5 | Planned |
| **FR-016** | Dashboard | Unified Home Dashboard | Central hub showing personalized greeting, today's workout card, calorie/macro budget ring, consistency streak, and active goals. | P0 | Milestone 3 | Planned |
| **FR-017** | Progress | Historical Telemetry & Analytics | Volume tonnage progression, body weight trends, workout consistency streaks, and personal records (PRs) over time. | P0 | Milestone 3 | Planned |
| **FR-018** | Notifications | Push Reminders & Alerts | Scheduled notifications for planned workouts, meal logging nudges, streak danger alerts, and periodic review prompts via FCM/APNs. | P1 | Milestone 7 | Planned |
| **FR-019** | Activity | Outdoor GPS Activity Tracking | High-accuracy outdoor tracking for running, walking, and cycling. Records distance, duration, pace, elevation, and encoded polyline route. | P1 | Milestone 4 | Planned |
| **FR-020** | Community | Social Feed & Peer Interactions | Social activity feed, follow network, activity sharing, peer kudos/reactions, and comments with privacy boundary enforcement. | P1 | Milestone 6 | Planned |
| **FR-021** | Community | Fitness Challenges & Leaderboards | Time-bound and volume-bound group challenges. Sub-millisecond leaderboards powered by Upstash Redis Sorted Sets (`ZSET`). | P1 | Milestone 6 | Planned |
| **FR-022** | Progress | Periodic Reassessment & Check-ins | Automated 2–4 week check-in prompt: updates body metrics, evaluates plan manageability, and prompts goal recalibration. | P1 | Milestone 2 | Planned |
| **FR-023** | Recommendations | Continuous Plan Adaptation Engine | Refines future volume, intensity, and schedule based on explicit (ratings), behavioral (skips), and performance (overload) feedback streams. | P1 | Milestone 2 | Planned |
| **FR-024** | Nutrition | Meal Planning & Recipe Library | Structured weekly meal planner, custom recipe builder with automatic macro calculations, and grocery list generation. | P1 | Milestone 5 | Planned |
| **FR-025** | Integrations | HealthKit & Health Connect Sync | Passive activity sync (steps, active calories, resting heart rate, sleep duration) from Apple HealthKit and Android Health Connect. | P2 | Milestone 8 | Planned |
| **FR-026** | Intelligence | AI-Assisted Coaching Explainability | Context-aware conversational AI coach providing natural language rationale for exercise prescriptions and adjustments, strictly guardrailed. | P2 | Milestone 8 | Planned |
| **FR-027** | Monetization | Subscription Billing & Entitlements | 3-tier monetization (Free, Premium, Coaching). Integrates Paystack (recurring NGN billing) and mobile IAP (StoreKit 2 / Google Play via RevenueCat). | P1 | Milestone 7 | Planned |
| **EXT-001** | Nutrition | Photo-Assisted Meal Logging | Camera meal capture, Cloudflare R2 upload, vision LLM inference proposing food items and portion estimates, user confirmation before logging. | P1 | Milestone 5 | Planned |
| **EXT-002** | Activity | Location Privacy Zones | User-defined privacy buffers (200m–2000m radius around Home/Work) clipping public route polylines while preserving authentic total distance. | P1 | Milestone 4 | Planned |
| **EXT-003** | Workouts | Dynamic Rest Timers & Audio Chimes | Exercise-specific countdown timers executing against monotonic clocks with high-priority local push chimes and haptic vibrations. | P0 | Milestone 3 | Planned |
| **EXT-004** | Security | Biometric App Lock & High-Risk Auth | Flutter `local_auth` protecting app resumption and requiring FaceID/Fingerprint for viewing sensitive health records or billing settings. | P1 | Milestone 1 | Planned |
| **EXT-005** | Admin | Exercise & Food Catalog CMS | Administrative web interface for managing exercises, Cloudflare R2 video URLs, verified Nigerian food items, and assessment question rules. | P1 | Milestone 8 | Planned |

---

## 3. Milestones & Delivery Roadmap

The platform implementation is partitioned into 9 structured, sequential milestones spanning foundation through production launch hardening:

```
[M0: Foundation & Environment Setup]
                 │
                 ▼
[M1: Core Domain Modeling & Database Migrations]
                 │
                 ▼
[M2: Assessment Engine, Safety Screening & Recommendations]
                 │
                 ▼
[M3: Flutter Mobile Client Core & Structured Workouts]
                 │
                 ▼
[M4: Outdoor GPS Activity Tracking & Offline Sync Engine]
                 │
                 ▼
[M5: Nutrition Logging, Localized Food DB & Meal Planning]
                 │
                 ▼
[M6: Social Community, Activity Feeds & Gamification]
                 │
                 ▼
[M7: Monetization, Billing Rails & Push Notifications]
                 │
                 ▼
[M8: Production Launch Hardening, Observability & NDPA Audit]
```

### Milestone M0: Architectural Foundation & Environment Setup
- **Scope**: Repository initialization, monorepo structure, Node.js 22 LTS + Fastify 5.x bootstrap, Flutter 3.x project setup, Docker compose for local PostgreSQL 16 + PostGIS, Upstash Redis/QStash credentials, Cloudflare R2 bucket provisioning, and CI/CD linting/typechecking pipelines.
- **Deliverables**: Verified build pipelines, linting configurations (`eslint`, `dart analyze`), environment variable schemas.

### Milestone M1: Core Domain Modeling & Database Migrations
- **Scope**: Implements authentication, identity, and profile management (**FR-001**, **FR-002**, **EXT-004**). Drizzle ORM schema configuration, PostgreSQL connection pooling with `postgres.js` and PgBouncer, migration runner, asymmetric JWT auth plugin, refresh token rotation with reuse detection, and NDPA 2023 consent tables (`user_consents`, `audit_logs`).
- **Deliverables**: Migrations 0001–0004, auth endpoints (`/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/me`), profile endpoints.

### Milestone M2: Assessment Engine, Safety Gate & Recommendation Core
- **Scope**: Implements questionnaire lifecycle (**FR-003**, **FR-004**, **FR-005**), 6-dimension classification engine (**FR-006**), safety screening gate (**FR-007**), weighted activity recommendation scoring (**FR-008**), 7-day schedule generator (**FR-009**), customization/revalidation (**FR-010**), periodic reassessments (**FR-022**), and continuous plan adaptation (**FR-023**).
- **Deliverables**: Assessment state machine, scoring formula implementation, blueprint generation endpoints (`POST /assessments/:id/complete`, `POST /recommendations/generate`, `POST /recommendations/:id/accept`).

### Milestone M3: Flutter Mobile Client Core & Structured Workouts
- **Scope**: Flutter Clean Architecture foundation, Riverpod 2.x state management, Drift (SQLite) local relational DB, workout program catalog (**FR-011**), interactive live workout execution tracker (**FR-012**, **EXT-003**), manual activity logging (**FR-013**), unified home dashboard (**FR-016**), and historical progress analytics (**FR-017**).
- **Deliverables**: Mobile workout execution UI, set/rep logging with optimistic SQLite commits, monotonic rest timers with haptic alerts, PR detection engine.

### Milestone M4: Outdoor GPS Activity Tracking & Offline Synchronization Engine
- **Scope**: Outdoor endurance telemetry (**FR-019**, **EXT-002**). Flutter background geolocation service (`FOREGROUND_SERVICE_TYPE_LOCATION`), Kalman filtering for GPS jitter, dead-reckoning during signal loss, Great-Circle Haversine distance accumulation, Google Encoded Polyline compression, location privacy zones, and the offline Write-Ahead Log (WAL) outbox synchronization queue.
- **Deliverables**: Live GPS running screen, background tracking service, route polyline compression, privacy zone masking, `POST /api/v1/sync/batch` offline sync protocol.

### Milestone M5: Nutrition Logging, Localized Food Database & Meal Planning
- **Scope**: Food search and logging (**FR-014**, **EXT-001**), TDEE and macronutrient tracking (**FR-015**), meal planning and recipe library (**FR-024**). Seed verified Nigerian Food Composition Table (BioNutrient/NAFDAC) alongside USDA data, client-side Drift SQLite FTS5 search cache, barcode scanner integration via Google ML Kit, and camera photo meal capture pipeline with Cloudflare R2.
- **Deliverables**: Nutrition diary UI, barcode scanner, multi-source food catalog search endpoints with `pg_trgm`, TDEE/macro target calculation engine.

### Milestone M6: Social Community, Activity Feeds & Gamification
- **Scope**: Social follow graph, activity feed, cheers/kudos, and comments (**FR-020**). Time-bound and metric-bound fitness challenges with real-time leaderboards powered by Upstash Redis Sorted Sets (`ZSET`) (**FR-021**). Privacy zone clipping on shared social feed maps.
- **Deliverables**: Community feed endpoints, kudos/comment state mutations, Redis leaderboard rankings (`ZADD`, `ZREVRANGE`, `ZREVRANK`).

### Milestone M7: Monetization, Billing Rails & Push Notifications
- **Scope**: Subscription billing engine (**FR-027**) and push notification delivery (**FR-018**). Paystack recurring billing integration (NGN cards, Dedicated Virtual Accounts, webhook HMAC SHA512 verification, 3-day dunning grace periods). Mobile in-app purchase integration via RevenueCat (Apple StoreKit 2 & Google Play Billing). Firebase Cloud Messaging (FCM v1) transactional and streak reminders.
- **Deliverables**: Paystack webhook handler, RevenueCat webhook handler, subscription entitlement cache in Redis, push notification scheduler via QStash crons.

### Milestone M8: Production Launch Hardening, Observability & NDPA Audit
- **Scope**: Wearable integrations (**FR-025**), AI coaching explainability (**FR-026**), catalog CMS admin (**EXT-005**). Pino structured logging, Sentry crash analytics, OpenTelemetry distributed tracing, Prometheus metrics (`/metrics`), p95 < 500 ms load testing, NDPA 2023 compliance audit (DPO readiness, data export ZIP generator, 30-day soft-delete purge worker, 72-hour breach response runbook).
- **Deliverables**: Final production Docker containers, Grafana dashboard configs, NDPA audit compliance attestation, end-to-end regression test suite pass.

---

## 4. Interface Contracts & Global Standards

### 4.1 REST API Standards & Protocols
- **Transport**: HTTPS / TLS 1.3 enforced. All unencrypted HTTP traffic redirected to HTTPS with HSTS headers.
- **Base URL**: `/api/v1`
- **Authentication Header**: `Authorization: Bearer <access_token>`
- **Idempotency Header**: `Idempotency-Key: <UUIDv7>` (Mandatory on all `POST`, `PUT`, `PATCH`, and sync endpoints).
- **Client Correlation Header**: `X-Correlation-ID: <UUIDv7>` (Propagated across logs, traces, and worker jobs).
- **Compression**: Mandatory Gzip and Brotli content-encoding for all request and response JSON payloads.

### 4.2 Standard API Response Envelope

#### Success Envelope (HTTP 200, 201)
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "timestamp": "2026-11-07T00:30:00.000Z",
    "correlation_id": "018e6e5a-7b3c-7000-8b4d-123456789abc",
    "pagination": {
      "page": 1,
      "limit": 20,
      "total_items": 142,
      "total_pages": 8
    }
  },
  "error": null
}
```

#### Error Envelope (HTTP 4xx, 5xx)
```json
{
  "success": false,
  "data": null,
  "meta": {
    "timestamp": "2026-11-07T00:30:00.000Z",
    "correlation_id": "018e6e5a-7b3c-7000-8b4d-123456789abc"
  },
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Input validation failed on request body",
    "details": [
      {
        "field": "date_of_birth",
        "message": "User must be at least 18 years of age to register"
      }
    ]
  }
}
```

### 4.3 Standard Error Codes & HTTP Status Mappings

| HTTP Status | Internal Error Code | Trigger Condition / Description |
|---|---|---|
| **400 Bad Request** | `INVALID_INPUT` | Malformed JSON, failed schema validation, unparseable parameters. |
| **400 Bad Request** | `UNDERAGE_NOT_PERMITTED` | Date of birth indicates age < 18 years. |
| **401 Unauthorized** | `AUTH_TOKEN_EXPIRED` | JWT access token has expired (client must invoke `/auth/refresh`). |
| **401 Unauthorized** | `AUTH_INVALID_CREDENTIALS` | Incorrect email or password combination. |
| **401 Unauthorized** | `AUTH_TOKEN_REVOKED` | Refresh token presented has been revoked or family invalidated. |
| **403 Forbidden** | `FORBIDDEN_RESOURCE` | Authenticated user lacks permission to access target entity. |
| **403 Forbidden** | `SAFETY_INTERCEPT_ACTIVE` | Workout generation blocked due to active cardiac red-flag symptom (E05). |
| **404 Not Found** | `RESOURCE_NOT_FOUND` | Target entity ID does not exist in database. |
| **409 Conflict** | `EMAIL_ALREADY_EXISTS` | Registration attempted with an email already in `users` table. |
| **409 Conflict** | `CONCURRENT_ACTIVE_SESSION` | User attempts to start a workout session while another is active. |
| **422 Unprocessable** | `ASSESSMENT_INCOMPLETE` | Assessment completion attempted with required questions missing. |
| **429 Too Many Requests**| `RATE_LIMIT_EXCEEDED` | Request frequency exceeds sliding-window rate limit. |
| **500 Internal Error** | `SERVER_ERROR` | Unhandled application exception (correlation ID logged to Sentry). |
| **503 Unavailable** | `SERVICE_DEGRADED` | Database connection pool exhausted or external payment gateway timeout. |

### 4.4 Canonical API Endpoint Catalog

```
====================================================================================================
MODULE: AUTHENTICATION & IDENTITY (FR-001)
====================================================================================================
POST   /api/v1/auth/register                 Register new user account (email, password, consent)
POST   /api/v1/auth/login                    Authenticate with credentials; returns access & refresh tokens
POST   /api/v1/auth/refresh                  Exchange valid refresh token for rotated token pair
POST   /api/v1/auth/logout                   Revoke current session and blacklist token
POST   /api/v1/auth/forgot-password          Dispatch password reset email with secure token
POST   /api/v1/auth/reset-password           Set new password using verified reset token
POST   /api/v1/auth/oauth/apple              Authenticate or register via Apple Sign In (JWS)
POST   /api/v1/auth/oauth/google             Authenticate or register via Google Identity (OIDC)

====================================================================================================
MODULE: USER PROFILE & SETTINGS (FR-002, EXT-004)
====================================================================================================
GET    /api/v1/users/me                      Retrieve authenticated user profile and entitlements
PATCH  /api/v1/users/me                      Update physical metrics (height, weight, units, avatar)
POST   /api/v1/users/me/device-token         Register or update mobile FCM push device token
DELETE /api/v1/users/me                      Initiate NDPA 30-day soft-delete account purge workflow
POST   /api/v1/users/me/export-data          Request NDPA machine-readable JSON/CSV data export archive

====================================================================================================
MODULE: ASSESSMENT & CLASSIFICATION (FR-003, FR-004, FR-005, FR-006, FR-007, FR-022)
====================================================================================================
POST   /api/v1/assessments                   Initialize draft assessment questionnaire (Version N+1)
GET    /api/v1/assessments/:id               Retrieve current assessment state and saved answers
PUT    /api/v1/assessments/:id/responses     Auto-save question responses for active stage (FR-004)
POST   /api/v1/assessments/:id/complete      Finalize assessment; triggers classification & safety gate
GET    /api/v1/assessments/history           Retrieve user's historical immutable assessments (FR-005)
POST   /api/v1/assessments/reassess          Submit 2-to-4 week progress review and recalibrate plan (FR-022)

====================================================================================================
MODULE: DASHBOARD & DAILY AGGREGATION (FR-016)
====================================================================================================
GET    /api/v1/dashboard/daily-summary       Retrieve unified daily home dashboard snapshot (FR-016)

====================================================================================================
MODULE: PROGRESS ANALYTICS & TIME-SERIES (FR-017)
====================================================================================================
GET    /api/v1/progress/history              Retrieve historical metric progression time-series (FR-017)

====================================================================================================
MODULE: RECOMMENDATIONS & BLUEPRINT (FR-008, FR-009, FR-010, FR-023)
====================================================================================================
POST   /api/v1/recommendations/generate      Compute weighted activity scores and generate 7-day plan
GET    /api/v1/recommendations/active        Retrieve current active fitness blueprint and schedule
POST   /api/v1/recommendations/:id/accept    Accept proposed blueprint; activates workout sessions
POST   /api/v1/recommendations/:id/customize Swap exercises or adjust days; triggers revalidation
POST   /api/v1/recommendations/:id/feedback  Submit difficulty/adherence feedback for adaptation (FR-023)

====================================================================================================
MODULE: AI COACHING EXPLAINABILITY (FR-026)
====================================================================================================
POST   /api/v1/ai/explain-recommendation     Generate context-aware natural language plan explanation (FR-026)

====================================================================================================
MODULE: WORKOUTS & EXECUTION (FR-011, FR-012, FR-013, EXT-003)
====================================================================================================
GET    /api/v1/workout-programs              Browse structured program catalog (goals, levels)
GET    /api/v1/workout-programs/:id          Retrieve full program details, weeks, and session templates
GET    /api/v1/exercises                     Search exercise library (muscle group, equipment, video)
POST   /api/v1/workout-sessions              Initialize new live workout session
PUT    /api/v1/workout-sessions/:id/sets     Commit completed exercise set (weight, reps, RPE, rest)
POST   /api/v1/workout-sessions/:id/complete Finalize workout session; computes volume and records PRs
POST   /api/v1/activities/manual             Log off-platform physical activity manually (FR-013)

====================================================================================================
MODULE: OUTDOOR GPS TELEMETRY & ROUTES (FR-019, EXT-002)
====================================================================================================
POST   /api/v1/activities/gps/start          Initialize active outdoor GPS tracking session
POST   /api/v1/activities/gps/complete       Finalize GPS run; upload encoded polyline and splits
GET    /api/v1/activities/gps/:id            Retrieve run details, pace splits, and elevation graph
POST   /api/v1/users/privacy-zones           Create or update location privacy masking zones (EXT-002)
GET    /api/v1/users/privacy-zones           List active privacy masking zones for authenticated user

====================================================================================================
MODULE: NUTRITION & FOOD DIARY (FR-014, FR-015, FR-024, EXT-001)
====================================================================================================
GET    /api/v1/foods/search                  Fuzzy text search across verified global and Nigerian foods
GET    /api/v1/foods/barcode/:code           Lookup food item by UPC/EAN barcode string
POST   /api/v1/nutrition/entries             Log consumed food to meal slot (Breakfast, Lunch, etc.)
DELETE /api/v1/nutrition/entries/:id         Remove food diary entry
GET    /api/v1/nutrition/summary             Retrieve daily consumed vs target calories and macros
POST   /api/v1/nutrition/photo-estimate      Upload meal photo for vision inference estimation (EXT-001)

====================================================================================================
MODULE: COMMUNITY, SOCIAL & CHALLENGES (FR-020, FR-021)
====================================================================================================
GET    /api/v1/community/feed                Chronological social activity feed of followed athletes
POST   /api/v1/community/posts               Share completed workout or GPS run to community feed
POST   /api/v1/community/posts/:id/kudos     Give kudos / reaction to peer activity post
POST   /api/v1/community/posts/:id/comments  Post comment on peer activity post
GET    /api/v1/challenges                    List active global and community fitness challenges
POST   /api/v1/challenges/:id/join           Join fitness challenge
GET    /api/v1/challenges/:id/leaderboard    Retrieve real-time ranked leaderboard (from Redis ZSET)

====================================================================================================
MODULE: BILLING & MONETIZATION (FR-027)
====================================================================================================
GET    /api/v1/billing/plans                 List available subscription plans (Free, Premium, Coaching)
POST   /api/v1/billing/paystack/initialize   Initialize Paystack checkout transaction (NGN)
POST   /api/v1/billing/webhooks/paystack     Paystack webhook handler (HMAC SHA512 verified)
POST   /api/v1/billing/webhooks/revenuecat   RevenueCat webhook handler (Apple / Google IAP sync)
GET    /api/v1/billing/subscription          Retrieve active subscription status and renewal date

====================================================================================================
MODULE: OFFLINE DATA SYNCHRONIZATION (FR-012, FR-019)
====================================================================================================
POST   /api/v1/sync/batch                    Flush queued client mutations (WAL) in an ACID transaction
GET    /api/v1/sync/delta                    Fetch server entity updates since specified timestamp
```

### 4.5 Core Domain Relational Entity Catalog (PRD Section 7.3)

The platform persistence model comprises exactly **25 core domain entities** mandated by PRD Section 7.3 (Pages 14–15), supplemented by operational infrastructure tables for colloquial food portion conversions, dead-letter sync quarantine, statutory billing audits, and NDPA compliance:

| Entity # | Entity Name (PostgreSQL Table) | Domain Classification | Primary Key / Partition Key | Description & Referential Integrity |
|---|---|---|---|---|
| **1** | `users` | Identity & Access | `id (UUID)` | Core authentication account, hashed credentials, role, status. |
| **2** | `user_profiles` | User Demographics | `user_id (UUID)` $\to$ `users.id` | Height, weight, DOB, sex, country, metric/imperial unit preference. |
| **3** | `fitness_assessments` | Assessment Engine | `id (UUID)` | Multi-stage questionnaire execution instances, immutable version history. |
| **4** | `assessment_questions` | Assessment Engine | `id (VARCHAR)` | Standardized questionnaire items across Stages A through F. |
| **5** | `assessment_options` | Assessment Engine | `id (UUID)` | Selectable options per question with scoring factor mappings. |
| **6** | `assessment_responses` | Assessment Engine | `id (UUID)` | Normalized, immutable user responses captured during assessment runs. |
| **7** | `health_restrictions` | Health & Safety | `id (UUID)` | Musculoskeletal restrictions, injuries, and AES-256-GCM encrypted clinical notes. |
| **8** | `fitness_goals` | Training Pathway | `id (UUID)` | Primary and supporting user fitness goals, targets, and deadlines. |
| **9** | `fitness_profiles` | Classification | `user_id (UUID)` $\to$ `users.id` | 6-dimension classified state, experience, and medical safety status. |
| **10** | `fitness_pathways` | Blueprint Core | `id (VARCHAR)` | High-level training archetypes defining progression boundaries and rules. |
| **11** | `activity_catalog` | Activity Master | `id (UUID)` | Catalog of physical training activities with MET scores, equipment, and constraints. |
| **12** | `recommendation_runs` | Recommendation Core | `id (UUID)` | Immutable execution log of recommendation generation with scoring snapshots. |
| **13** | `fitness_recommendations`| Recommendation Core | `id (UUID)` | Prescribed activities with 7-dimension suitability scores $S(a,u)$. |
| **14** | `workout_programs` | Structured Workouts | `id (UUID)` | Curated periodized resistance training programs (duration, days/week). |
| **15** | `workout_sessions` | Workout Telemetry | `(id, scheduled_date)` Range Partition | Scheduled and completed resistance training sessions. |
| **16** | `exercises` | Exercise Master | `id (UUID)` | Movement catalog with muscle targets, equipment, and Cloudflare R2 video URLs. |
| **17** | `workout_sets` | Workout Telemetry | `(id, scheduled_date)` Range Partition | Set-by-set logs (reps, weight, RPE) referencing `workout_sessions(id, scheduled_date)`. |
| **18** | `nutrition_entries` | Nutrition & Diet | `id (UUID)` | User daily food diary logs by meal slot (Breakfast, Lunch, Dinner, Snack). |
| **19** | `food_catalog` | Nutrition Master | `id (UUID)` | USDA & verified Nigerian food database with calorie/macro composition. |
| **20** | `activity_sessions` | GPS Telemetry | `(id, started_at)` Range Partition | Outdoor endurance runs, walks, cycles with distance, duration, and pace. |
| **21** | `activity_routes` | Geospatial Route | `(id, started_at)` Range Partition | PostGIS LineString geometry, encoded polylines, and privacy masking zones. |
| **22** | `progress_records` | Analytics Telemetry | `id (UUID)` | Time-series biometric and performance records (weight, volume tonnage, PRs). |
| **23** | `user_feedback` | Adaptation Engine | `id (UUID)` | User adherence ratings, perceived difficulty, and plan adaptation triggers. |
| **24** | `subscriptions` | Billing & Monetization | `id (UUID)` | User membership tier, billing cycle, Paystack/IAP references (`onDelete: 'set null'`). |
| **25** | `notification_preferences`| Notifications | `id (UUID)` | Multi-channel opt-ins, quiet hours, workout reminders, and streak nudges. |
| *Sup* | `food_portion_units` | Nutrition Extension | `id (UUID)` | Colloquial Nigerian culinary measure conversions (plates, wraps, ladles, tins). |
| *Sup* | `sync_quarantine` | Offline Sync DLQ | `id (UUID)` | Dead-letter queue isolating corrupted offline sync mutations. |
| *Sup* | `sync_idempotency_records`| Offline Sync Gate | `(key, user_id)` Composite PK | Transactional idempotency tracking for batch sync operations. |
| *Sup* | `billing_transactions` | Statutory Finance | `id (UUID)` | Immutable financial ledger retained for 6 years per CAMA 2020 s.375 and FIRS. |
| *Sup* | `user_consents` | NDPA Compliance | `id (UUID)` | Immutable explicit consent records (health processing, cross-border transfer). |
| *Sup* | `audit_logs` | Security Audit | `(id, created_at)` Range Partition | Append-only security audit trail of sensitive record access and modifications. |

---

## 5. Code Layout & Monorepo Structure

The project is structured as a polyglot monorepo cleanly decoupling the Fastify backend service, Flutter mobile client, shared assets, documentation, and operational scripts:

```
/Users/Apple/Documents/PersonalProjects/Fitness/
├── .agents/                        # Teamwork and agent execution metadata ONLY
│   └── teamwork/
├── backend/                        # Node.js 22 LTS + Fastify 5.x API Service
│   ├── src/
│   │   ├── config/                 # Environment validation, constants, DB connection
│   │   │   ├── env.ts              # TypeBox environment schema validation
│   │   │   ├── database.ts         # postgres.js pool & Drizzle client initialization
│   │   │   ├── redis.ts            # Upstash Redis ioredis (TCP) & REST client setup
│   │   │   ├── qstash.ts           # Upstash QStash client & webhook receiver
│   │   │   └── r2.ts               # Cloudflare R2 S3 client configuration
│   │   ├── db/                     # Drizzle ORM schemas, relations & migrations
│   │   │   ├── schema/             # Modular entity definitions
│   │   │   │   ├── auth.ts         # users, refresh_tokens, user_consents, audit_logs
│   │   │   │   ├── profile.ts      # user_profiles, health_restrictions, privacy_zones
│   │   │   │   ├── assessment.ts   # fitness_assessments, assessment_responses
│   │   │   │   ├── recommendation.ts# fitness_profiles, recommendation_runs, recommendations
│   │   │   │   ├── workout.ts      # exercises, workout_programs, sessions, workout_sets
│   │   │   │   ├── activity.ts     # activity_sessions, activity_routes (PostGIS)
│   │   │   │   ├── nutrition.ts    # food_catalog, nutrition_entries, meal_plans
│   │   │   │   ├── social.ts       # social_posts, social_interactions, challenges
│   │   │   │   └── billing.ts      # subscriptions, billing_transactions
│   │   │   ├── migrations/         # Pure SQL migration files generated by drizzle-kit
│   │   │   └── seeds/              # Seed scripts (Nigerian foods, exercises, questions)
│   │   ├── plugins/                # Fastify plugins (JWT, CORS, Rate Limit, Telemetry)
│   │   │   ├── auth.plugin.ts      # Asymmetric JWT verification & RBAC hooks
│   │   │   ├── rate-limit.plugin.ts# Upstash Redis sliding window limiter
│   │   │   ├── pino.plugin.ts      # Pino structured JSON logging configuration
│   │   │   └── sentry.plugin.ts    # Sentry error handler & correlation ID tracking
│   │   ├── modules/                # Feature modules (Controller, Service, Schema)
│   │   │   ├── auth/               # Auth controller, service, TypeBox contracts
│   │   │   ├── assessment/         # Assessment questionnaire & state machine
│   │   │   ├── recommendation/     # Scoring formula, eligibility, weekly generator
│   │   │   ├── workout/            # Workout session & live set logging
│   │   │   ├── activity/           # GPS session ingestion & route compression
│   │   │   ├── nutrition/          # Food search (pg_trgm), macro budgeting
│   │   │   ├── social/             # Activity feed & Redis ZSET leaderboards
│   │   │   ├── billing/            # Paystack & RevenueCat webhook processing
│   │   │   ├── sync/               # Batch mutation sync & delta queries
│   │   │   └── compliance/         # NDPA data export & erasure workflows
│   │   └── server.ts               # Fastify application entrypoint & listener
│   ├── tests/                      # Automated test suites
│   │   ├── unit/                   # Scoring algorithm, Mifflin-St Jeor, polyline tests
│   │   ├── integration/            # Fastify route tests with ephemeral PostgreSQL
│   │   └── e2e/                    # Complete user journey simulation tests
│   ├── drizzle.config.ts           # Drizzle Kit migration configuration
│   ├── package.json
│   ├── tsconfig.json
│   └── Dockerfile                  # Multi-stage production container build
├── mobile/                         # Flutter 3.x Cross-Platform Client
│   ├── android/                    # Native Android project (Foreground Services, FCM)
│   ├── ios/                        # Native iOS project (Background Location, APNs)
│   ├── lib/
│   │   ├── core/                   # Platform utilities, networking, themes, errors
│   │   │   ├── database/           # Drift SQLite database & DAOs
│   │   │   │   ├── app_database.dart
│   │   │   │   ├── daos/           # WorkoutDao, NutritionDao, OutboxDao
│   │   │   │   └── tables/         # Local table definitions & FTS5 search table
│   │   │   ├── network/            # Dio HTTP client, auth interceptor, idempotency
│   │   │   ├── sync/               # Outbox mutation queue manager & connectivity listener
│   │   │   ├── location/           # Background GPS location tracker & Kalman filter
│   │   │   ├── theme/              # Dark mode AMOLED design system, typography
│   │   │   └── router/             # Declarative GoRouter routing & auth guards
│   │   ├── features/               # Clean Architecture feature modules
│   │   │   ├── auth/               # Login, Register, Biometric lock screens
│   │   │   ├── onboarding/         # 6-stage conversational assessment & blueprint
│   │   │   ├── dashboard/          # Home tab, daily rings, streak counters
│   │   │   ├── workout/            # Program browser, live workout execution, rest timer
│   │   │   ├── activity/           # Live GPS run screen, route map overlay, splits
│   │   │   ├── nutrition/          # Food diary, barcode scanner, macro progress
│   │   │   ├── community/          # Social feed, challenges, leaderboard views
│   │   │   ├── progress/           # Weight trends, volume tonnage, 2-week check-in
│   │   │   └── settings/           # Privacy zones, NDPA data export/delete, billing
│   │   └── main.dart               # Flutter application entrypoint
│   ├── test/                       # Flutter unit & widget tests
│   ├── integration_test/           # Mobile end-to-end integration flows
│   └── pubspec.yaml
├── docs/                           # Architecture, Execution, Verification Documentation
│   ├── architecture/
│   │   ├── TECHNICAL_ARCHITECTURE.md
│   │   └── COMPLIANCE_AND_OFFLINE_SYNC.md
│   ├── execution/
│   │   └── PHASED_EXECUTION_PLAN.md
│   └── verification/
│       └── VERIFICATION_RUBRIC.md
├── TEST_INFRA.md                   # E2E test track specification & methodology
├── TEST_READY.md                   # Test runner command manual & validation checklist
├── Fitness App.pdf                 # Authoritative 22-page Product Requirements Document
└── docker-compose.yml              # Local development services (Postgres + PostGIS)
```
