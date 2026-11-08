# Test Execution & Readiness Manual

**Document Version**: 1.0.0  
**Status**: Authoritative Test Execution Guide  
**Date**: 2026-11-07  
**Scope**: Verification Runbook for QA Engineers, Developers & Forensic Auditors  
**Companion Artifacts**: `TEST_INFRA.md`, `docs/verification/VERIFICATION_RUBRIC.md`  

---

## 1. Test Environment Prerequisites & Configuration

Before executing the test suite, ensure your workstation or CI environment meets the following specifications:

### 1.1 Toolchain Requirements
- **Node.js**: `v22.x LTS` (verify with `node -v`)
- **pnpm**: `v9.x` (verify with `pnpm -v`)
- **Docker & Docker Compose**: Docker Engine `v26.x+` (verify with `docker --version`)
- **Flutter SDK**: `v3.24.x+` (verify with `flutter --version`)
- **PostgreSQL Client Tools**: `psql` (optional, for direct inspection)

### 1.2 Environment Variables Configuration
Create a `.env.test` file in the `backend/` directory with the following test credentials:

```bash
# Node Environment
NODE_ENV=test
PORT=3001
HOST=0.0.0.0

# Database Configuration (Ephemeral Docker Container)
DATABASE_URL=postgres://fitness_test:fitness_test_pass@localhost:5433/fitness_test_db
DB_MAX_CONNECTIONS=20

# Upstash Redis & QStash (Local or Ephemeral Mock)
UPSTASH_REDIS_URL=redis://localhost:6380
UPSTASH_REDIS_TOKEN=mock_test_token
QSTASH_URL=http://localhost:8081
QSTASH_TOKEN=mock_qstash_token
QSTASH_CURRENT_SIGNING_KEY=mock_sig_key
QSTASH_NEXT_SIGNING_KEY=mock_next_sig_key

# Cloudflare R2 Mock / MinIO
R2_ACCOUNT_ID=mock_account
R2_ACCESS_KEY_ID=mock_access_key
R2_SECRET_ACCESS_KEY=mock_secret_key
R2_BUCKET_NAME=fitness-test-media
R2_PUBLIC_DOMAIN=http://localhost:9000

# Authentication & Cryptographic Keys
JWT_PRIVATE_KEY_PATH=./tests/fixtures/test_ed25519_private.pem
JWT_PUBLIC_KEY_PATH=./tests/fixtures/test_ed25519_public.pem
HEALTH_DATA_MASTER_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

# Payment Gateways (Sandbox Keys)
PAYSTACK_SECRET_KEY=sk_test_mock_paystack_secret_key
REVENUECAT_WEBHOOK_AUTH_TOKEN=mock_rc_webhook_secret
```

---

## 2. Test Environment Initialization & Data Seeding

Run the following commands to provision the local test database and seed reference catalogs:

```bash
# 1. Spin up ephemeral test services (Postgres + PostGIS & Redis)
docker compose -f docker-compose.test.yml up -d

# 2. Run database migrations to establish authoritative schema
pnpm --filter backend run db:migrate:test

# 3. Seed verified exercise catalog, assessment questions, and Nigerian food data
pnpm --filter backend run db:seed:test
```

---

## 3. Step-by-Step Test Execution Commands

### 3.1 Static Code Quality & Type-Check Verification
Verifies that all TypeScript and Dart code adheres strictly to static analysis rules with zero errors:

```bash
# Backend linting and TypeScript compilation
pnpm --filter backend run lint
pnpm --filter backend run typecheck

# Mobile Flutter static analysis
cd mobile && flutter analyze && cd ..
```
*Expected Result*: Zero errors and zero warnings across all packages.

---

### 3.2 Track 1: Pure Domain Logic & Unit Tests
Executes unit tests for the 7-factor activity scoring formula, Mifflin-St Jeor TDEE math, Kalman filtering, and Google Encoded Polyline compression:

```bash
# Execute backend domain unit tests
pnpm --filter backend run test:unit
```
*Expected Result*:
```
✓ tests/unit/scoring.test.ts (14 tests)
✓ tests/unit/tdee.test.ts (8 tests)
✓ tests/unit/polyline.test.ts (6 tests)
✓ tests/unit/kalman.test.ts (10 tests)
Test Files  4 passed (4)
Tests       38 passed (38)
Duration    1.24s
```

---

### 3.3 Track 2: Backend Integration Tests (Database, Redis, Fastify Routes)
Tests Fastify API endpoints against the live test database, verifying asymmetric JWT auth, Drizzle ORM queries, rate-limiting, and webhook HMAC signature validation:

```bash
# Execute backend integration test suite
pnpm --filter backend run test:integration
```
*Expected Result*:
```
✓ tests/integration/auth.test.ts (12 tests)
✓ tests/integration/assessment.test.ts (16 tests)
✓ tests/integration/recommendations.test.ts (10 tests)
✓ tests/integration/workout.test.ts (14 tests)
✓ tests/integration/nutrition.test.ts (11 tests)
✓ tests/integration/gps_activity.test.ts (9 tests)
✓ tests/integration/billing_paystack.test.ts (8 tests)
✓ tests/integration/offline_sync.test.ts (7 tests)
Test Files  8 passed (8)
Tests       87 passed (87)
Duration    4.82s
```

---

### 3.4 Track 3 & 4: Mobile Client Tests & Offline Drift SQLite Sync
Tests mobile widget rendering, user interaction, and offline outbox mutation queuing via Drift SQLite:

```bash
cd mobile

# Run Flutter unit and widget test suite
flutter test

# Run mobile offline synchronization test suite
flutter test test/offline_sync_test.dart

cd ..
```
*Expected Result*: All mobile tests pass; offline mutations successfully commit to local SQLite and resolve upon sync flush.

---

### 3.5 Track 5: Full End-to-End User Journeys (1 to 6)
Executes end-to-end integration flows covering all six canonical user journeys:

```bash
# Run User Journeys 1 through 6 E2E suite
pnpm --filter backend run test:e2e
```
*Verified Journeys*:
1. `uj1_onboarding_assessment.e2e.ts`: Register $\rightarrow$ Consent $\rightarrow$ Stages A–F $\rightarrow$ Safety Check $\rightarrow$ Blueprint Activation.
2. `uj2_workout_execution.e2e.ts`: Start session $\rightarrow$ Log sets/reps $\rightarrow$ Rest countdown $\rightarrow$ Complete session $\rightarrow$ PR detection.
3. `uj3_outdoor_gps.e2e.ts`: Track GPS points $\rightarrow$ Kalman filter $\rightarrow$ Encoded polyline $\rightarrow$ Privacy zone clipping.
4. `uj4_nutrition_diary.e2e.ts`: Search Nigerian food $\rightarrow$ Barcode lookup $\rightarrow$ Log meal $\rightarrow$ Real-time macro decrement.
5. `uj5_goal_modification.e2e.ts`: Switch primary goal $\rightarrow$ Diff comparison $\rightarrow$ Program re-blueprint without data loss.
6. `uj6_periodic_adaptation.e2e.ts`: 4-week check-in $\rightarrow$ Adherence evaluation $\rightarrow$ Progressive overload adjustment.

---

### 3.6 Track 6: Non-Functional SLA & Latency Benchmark (p95 < 500ms)
Executes high-concurrency performance benchmark using Autocannon:

```bash
# Run p95 latency benchmark (1,000 requests, 100 concurrent connections)
pnpm --filter backend run bench:p95
```
*Expected Result*:
```
Running 30s test @ http://localhost:3001/api/v1/dashboard/daily-summary
100 connections

Stat         Avg     Stdev   Max     p95
Latency (ms) 124.5   32.1    312.0   188.4 ms
Req/Sec      1640    142     1890    1520 req/s

0 errors, 0 timeouts (p95 SLA < 500ms PASSED)
```

---

### 3.7 Track 7: NDPA 2023 Security & Compliance Verification
Audits sensitive health data encryption, audit trails, and data subject rights:

```bash
# Run NDPA compliance audit verification script
pnpm --filter backend run audit:ndpa
```
*Verification Assertions*:
- `user_consents` verified: explicit consent recorded with SHA-256 IP hash and policy version.
- `health_restrictions` field encryption verified: notes stored as `v{version}:{iv}:{tag}:{ciphertext}` using AES-256-GCM.
- Data export verified: `POST /users/me/export-data` generates valid ZIP containing machine-readable JSON/CSV files.
- Soft-delete grace period and hard purge cascade verified: zero orphaned records remaining after 30-day simulation.

---

## 4. Test Pass / Fail Checklist for Auditors

| Verification Item | Command / Inspection | Expected Value | Auditor Sign-off |
|---|---|---|---|
| Static Analysis Clean | `pnpm --filter backend run lint && pnpm --filter backend run typecheck && cd mobile && flutter analyze && cd ..` | 0 errors, 0 warnings | [ ] PASS |
| Unit Test Suite Passed | `pnpm --filter backend run test:unit` | 100% tests green | [ ] PASS |
| Backend Integration Passed| `pnpm --filter backend run test:integration` | 100% tests green | [ ] PASS |
| Mobile Offline Sync Passed| `cd mobile && flutter test test/offline_sync_test.dart && cd ..` | 0 data loss | [ ] PASS |
| All 6 User Journeys Passed| `pnpm --filter backend run test:e2e` | 6/6 journeys green | [ ] PASS |
| p95 Latency SLA Met | `pnpm --filter backend run bench:p95` | p95 $< 500\text{ms}$ | [ ] PASS |
| AES-256-GCM Field Encryption| `psql -c "SELECT encrypted_notes FROM health_restrictions LIMIT 1;"`| Ciphertext format (`v{ver}:{iv}:{tag}:{ct}`)| [ ] PASS |
| NDPA Consent Audit Passed | `pnpm --filter backend run audit:ndpa` | 100% compliant | [ ] PASS |
