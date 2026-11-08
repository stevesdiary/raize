# Test Infrastructure & Methodology Specification

**Document Version**: 1.0.0  
**Status**: Authoritative Test Infrastructure Specification  
**Date**: 2026-11-07  
**Scope**: Full-Stack Test Strategy, 4-Tier Methodology & CI/CD Verification Tracks  
**Target Coverage**: 100% Core Domain Logic, > 90% Integration Routes, Zero Unhandled Edge Cases  

---

## 1. Test Architecture Overview

The testing infrastructure is architected to guarantee deterministic, reproducible verification across the entire polyglot stack: Node.js 22 LTS / Fastify 5.x, PostgreSQL 16 + PostGIS, Drizzle ORM, Upstash Redis/QStash, Cloudflare R2, and the Flutter 3.x mobile client with Drift SQLite.

```
+--------------------------------------------------------------------------------------------------+
|                                    4-TIER TESTING METHODOLOGY                                    |
|                                                                                                  |
|  [ Tier 1: Category-Partition ]  ──► Input space partitioned into disjoint equivalence classes  |
|  [ Tier 2: Boundary Value (BVA)] ──► Explicit testing at minimum, nominal, and maximum limits   |
|  [ Tier 3: Pairwise Matrix ]     ──► Combinatorial testing across orthogonal dimensions          |
|  [ Tier 4: Real-World Workloads] ──► Flaky networks, battery drains, OS kills & load spikes     |
+--------------------------------------------------------------------------------------------------+
                                                  │
                                                  ▼
+--------------------------------------------------------------------------------------------------+
|                                      TEST EXECUTION TRACKS                                       |
|                                                                                                  |
|  Track 1: Unit & Pure Domain Logic (Vitest & Dart Test)                                          |
|  Track 2: Backend Integration with Testcontainers (Ephemeral PostgreSQL + PostGIS + Redis)      |
|  Track 3: Mobile Component & Widget Testing (Flutter Test Harness)                              |
|  Track 4: Offline Outbox & Drift SQLite Sync (Simulated Intermittent Connectivity)               |
|  Track 5: End-to-End User Journeys 1 through 6 Automation                                       |
|  Track 6: Performance, Concurrency & SLA Load Testing (Autocannon Benchmark Suite)               |
|  Track 7: NDPA 2023 Security, Cryptography & Compliance Audit Verification                      |
+--------------------------------------------------------------------------------------------------+
```

---

## 2. The 4-Tier Test Case Design Methodology

### 2.1 Tier 1: Category-Partition Testing (Equivalence Partitioning)
Every input domain is partitioned into mutually exclusive equivalence classes where system behavior is invariant. Test cases sample representative inputs from valid and invalid partitions.

#### Example: Assessment Question Stage A (Demographics & Biological Age)
- **Equivalence Partitions**:
  - Partition $P_1$ (Underage Invalid): $\text{Age} < 18$ (e.g., DOB representing 16 years, 364 days). Expected: HTTP 400 `UNDERAGE_NOT_PERMITTED`.
  - Partition $P_2$ (Standard Adult Valid): $18 \le \text{Age} \le 75$ (e.g., age 28). Expected: Registration proceeds.
  - Partition $P_3$ (Senior Guidance Trigger): $\text{Age} > 75$. Expected: Flagged for mandatory physician clearance check.
  - Partition $P_4$ (Biological Absurdity Invalid): $\text{Age} > 120$ or Future DOB ($\text{DOB} > \text{Today}$). Expected: HTTP 400 `INVALID_INPUT`.

### 2.2 Tier 2: Boundary Value Analysis (BVA)
Defects cluster disproportionately around the edges of input domains. Tests explicitly probe values at the boundaries: $\text{Min} - 1$, $\text{Min}$, $\text{Min} + 1$, $\text{Nominal}$, $\text{Max} - 1$, $\text{Max}$, $\text{Max} + 1$.

#### Boundary Value Matrix for Core Inputs

| Input Domain | Lower Boundary Vector | Nominal Vector | Upper Boundary Vector |
|---|---|---|---|
| **User Age (DOB)** | $17\text{ yrs } 364\text{ days}$ (Reject), $18\text{ yrs } 0\text{ days}$ (Accept) | $30\text{ yrs}$ (Accept) | $120\text{ yrs}$ (Accept), $120\text{ yrs } 1\text{ day}$ (Reject) |
| **User Weight (kg)** | $24.9\text{ kg}$ (Reject), $25.0\text{ kg}$ (Accept) | $75.0\text{ kg}$ (Accept) | $400.0\text{ kg}$ (Accept), $400.1\text{ kg}$ (Reject) |
| **User Height (cm)** | $49.9\text{ cm}$ (Reject), $50.0\text{ cm}$ (Accept) | $175.0\text{ cm}$ (Accept) | $260.0\text{ cm}$ (Accept), $260.1\text{ cm}$ (Reject) |
| **Workout Reps** | $-1$ (Reject), $0$ (Accept for static hold) | $10$ (Accept) | $500$ (Accept), $501$ (Reject) |
| **Barbell Weight (kg)**| $-0.1\text{ kg}$ (Reject), $0.0\text{ kg}$ (Accept) | $100.0\text{ kg}$ (Accept) | $1000.0\text{ kg}$ (Accept), $1000.1\text{ kg}$ (Reject) |
| **Calorie Deficit Floor**| $1199\text{ kcal}$ Female (Clamped to 1200) | $1800\text{ kcal}$ | Unrestricted surplus |
| **GPS Fix Accuracy (m)**| $29.9\text{m}$ (Accept), $30.0\text{m}$ (Accept) | $5.0\text{m}$ (Accept) | $30.1\text{m}$ (Reject / Kalman filter drops) |
| **Privacy Radius (m)** | $199\text{m}$ (Reject), $200\text{m}$ (Accept) | $500\text{m}$ (Accept) | $2000\text{m}$ (Accept), $2001\text{m}$ (Reject) |

### 2.3 Tier 3: Pairwise Combinatorial Testing
The recommendation engine and classification matrix evaluate multiple orthogonal dimensions simultaneously. Exhaustive testing across all parameter combinations would require $> 100,000$ permutations. **Pairwise Combinatorial Testing** generates an optimal subset ensuring that every pair of input values across dimensions is tested at least once.

#### Pairwise Matrix Dimensions:
1. **Primary Goal (9 choices)**: Weight Loss, Muscle Building, Strength, Endurance, Functional Mobility, etc.
2. **Fitness Experience (3 choices)**: Beginner, Intermediate, Advanced.
3. **Training Environment (4 choices)**: Home, Gym, Outdoors, Mixed.
4. **Equipment Access (5 choices)**: None (Bodyweight), Dumbbells, Resistance Bands, Home Gym, Full Commercial Gym.
5. **Safety Status (4 choices)**: Standard, Joint Limitation, Medical Condition, Acute Symptoms (E05).

The generated pairwise suite produces **64 high-coverage test cases** covering 100% of two-way interactions without combinatorial explosion.

### 2.4 Tier 4: Real-World Workloads & Stress Testing
Simulates adverse production conditions:
- **Mobile Battery Exhaustion**: Tracking runs with low battery ($< 15\%$), evaluating throttling of GPS sample rate.
- **OS Low Memory Killer (LMK)**: Simulating background application termination during set 3 of a 5-set workout; verifying 100% local SQLite state restoration.
- **Flaky Cellular Connectivity**: Simulating 3G/EDGE dropouts and subway tunnel passages during GPS route recording and outbox sync flushes.
- **Payment Webhook Retries**: Simulating duplicate Paystack webhooks dispatched simultaneously to test Redis distributed locks.

---

## 3. Test Execution Tracks

### Track 1: Unit & Pure Domain Logic Testing
- **Framework**: Vitest (Backend) & `test` (Dart).
- **Execution Speed**: $< 5\text{ms}$ per test; executed on every file save.
- **Scope**:
  - 7-factor activity recommendation scoring formula ($S(a,u) = \sum w_i r_i$).
  - Mifflin-St Jeor BMR and TDEE calorie calculation.
  - Great-Circle Haversine spherical distance accumulator.
  - Google Encoded Polyline encoder and decoder.
  - Kalman filter jitter smoothing algorithms.

### Track 2: Backend Integration Testing
- **Framework**: Vitest with Testcontainers for Node.js (`testcontainers`).
- **Infrastructure**: Boots an ephemeral Docker container running PostgreSQL 16 + PostGIS and an ephemeral Upstash-compatible Redis container.
- **Scope**:
  - Drizzle ORM database migrations and foreign key cascading.
  - Fastify route pre-handler hooks (asymmetric JWT validation, role-based RBAC).
  - Rate limiting sliding-window token buckets.
  - Paystack and RevenueCat webhook signature verification and idempotency locks.

### Track 3: Mobile Component & Widget Testing
- **Framework**: Flutter Test (`flutter_test`).
- **Scope**:
  - Onboarding card carousel state transitions and input validation.
  - Live workout execution screen (quick stepper reps/weight adjustments).
  - Sticky rest countdown timer rendering and audio trigger invocations.
  - Food diary macro ring animation and calorie budget decrements.

### Track 4: Mobile Offline Outbox & Drift SQLite Sync Testing
- **Framework**: Flutter integration test with mock Dio HTTP adapter.
- **Scope**:
  - Offline write-ahead log (`mutation_queue`) transactional integrity.
  - Commutative event append operations for workout sets and GPS trackpoints.
  - Network state transition detection (`connectivity_plus`) and automated queue flushing.
  - Server delta reconciliation into local Drift SQLite tables.

### Track 5: End-to-End User Journeys 1–6 Automation
- **Framework**: Playwright (Web) & Flutter Driver / Patrol (Mobile).
- **Scope**:
  - Complete automated execution of User Journeys 1 through 6 without manual interventions.
  - Simulates new user onboarding, live workout completion, outdoor GPS run, food logging, goal modification, and periodic check-in.

### Track 6: Non-Functional SLA & Load Testing
- **Framework**: Autocannon & k6.
- **Scope**:
  - Sustained 1,500 requests/sec throughput simulating morning and evening workout peaks in Nigeria.
  - Verification that p95 latency remains strictly $< 500\text{ms}$ across all endpoints.
  - Database connection pool saturation tests under PgBouncer transaction mode.

### Track 7: NDPA 2023 Security & Cryptographic Compliance Audit
- **Scope**:
  - Automated verification of AES-256-GCM application-level encryption on sensitive health notes.
  - Verification of immutable audit trail entries in `audit_logs`.
  - Automated generation and structural validation of NDPA data portability export ZIP files.
  - 30-day soft-delete purge worker simulation.

---

## 4. Test Coverage Matrix

| Subsystem / Module | Primary Track | Methodology Tiers | Target Coverage |
|---|---|---|---|
| **Authentication & RBAC** | Track 1, 2 | Tier 1, Tier 2 | 100% lines, 100% branches |
| **Assessment & Questionnaire** | Track 1, 2, 5 | Tier 1, Tier 2 | 100% lines, 100% branches |
| **PAR-Q+ Safety Screening Gate**| Track 1, 2 | Tier 1, Tier 2, Tier 4 | 100% lines, 100% branches |
| **Recommendation Scoring Engine**| Track 1 | Tier 2, Tier 3 | 100% lines, 100% branches |
| **Weekly Schedule Generator** | Track 1, 2 | Tier 1, Tier 3 | > 95% lines |
| **Workout Execution & Live Sets**| Track 3, 4, 5 | Tier 1, Tier 2, Tier 4 | > 95% lines |
| **GPS Telemetry & Kalman Filter**| Track 1, 4 | Tier 2, Tier 4 | 100% algorithm logic |
| **Route Privacy Zones** | Track 1, 2 | Tier 1, Tier 2 | 100% clipping logic |
| **Nutrition & TDEE Calculations**| Track 1, 2 | Tier 1, Tier 2 | 100% math calculations |
| **Food Database Trigram Search** | Track 2, 4 | Tier 1, Tier 4 | > 90% lines |
| **Social Feeds & Redis Leaderboard**| Track 2, 6 | Tier 1, Tier 4 | > 90% lines |
| **Paystack & RevenueCat Billing**| Track 2 | Tier 1, Tier 4 | 100% webhook & idempotency |
| **Offline WAL Mutation Queue** | Track 4 | Tier 2, Tier 4 | 100% state transitions |
| **NDPA Data Export & Erasure** | Track 2, 7 | Tier 1, Tier 4 | 100% compliance paths |
