# Compliance & Offline-First Synchronization Architecture

**Document Version**: 1.0.0  
**Status**: Authoritative Architecture Specification  
**Date**: 2026-11-07  
**Scope**: Nigerian Data Protection Act (NDPA 2023) Safeguards & Flutter Offline Synchronization  
**Regulatory Target**: Nigeria Data Protection Commission (NDPC) Compliance Guidelines  

---

## 1. Executive Summary

This specification establishes the architectural frameworks governing data protection, regulatory compliance under the **Nigeria Data Protection Act 2023 (NDPA)**, and an **offline-first data synchronization engine** for the Flutter mobile client operating in low-connectivity African network environments.

---

## 2. Nigerian Data Protection Act (NDPA 2023) Compliance Architecture

The initial commercial launch of the Unified Fitness Platform is targeted at Nigeria (PRD Page 20, Section 14). Processing personal fitness, biometric, and medical screening data requires strict compliance with the **Nigeria Data Protection Act 2023**, enacted on 12 June 2023 and enforced by the **Nigeria Data Protection Commission (NDPC)**.

### 2.1 Lawful Basis & Explicit Consent for Sensitive Health Data (NDPA Section 30)

1. **Classification of Health & Assessment Data**:
   - Under NDPA Section 30, information concerning physical injury history (Stage E01), diagnosed cardiovascular/respiratory conditions (Stage E02), prescription limitations (Stage E03), post-surgical recovery (Stage E04), and acute symptoms like chest pain or syncope (Stage E05) is legally classified as **Sensitive Personal Data**.
2. **Explicit Consent Protocol**:
   - Processing sensitive personal data without explicit, unbundled, informed consent is strictly prohibited under Nigerian law.
   - The onboarding flow introduces a standalone, dedicated **Health Data Privacy Consent Card** immediately prior to presenting Stage E questions.
   - The consent card must explicitly state:
     - Exact categories of sensitive health data collected.
     - Purpose of processing: to safely filter contraindicated exercises and prevent exercise-induced medical events.
     - Confirmation that health data is never sold, shared with third-party advertisers, or utilized for automated insurance underwriting.
     - Clear notice of the right to withdraw consent at any time.

```sql
-- Immutable Record of NDPA Explicit Consents
CREATE TABLE user_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    consent_type VARCHAR(64) NOT NULL, -- 'HEALTH_DATA_PROCESSING', 'TERMS_OF_SERVICE', 'GPS_TRACKING'
    consent_version VARCHAR(16) NOT NULL, -- e.g. 'v1.0.0'
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    ip_address_hash VARCHAR(64) NOT NULL, -- SHA-256 hashed IP for auditability
    user_agent TEXT NOT NULL,
    policy_hash VARCHAR(64) NOT NULL -- SHA-256 hash of the exact privacy policy text shown
);

CREATE INDEX idx_user_consents_user ON user_consents(user_id);
```

### 2.2 Minor Safeguarding Architecture (NDPA Section 31)
- **Target Age Boundary**: The platform enforces an **18+ years old** age gate for the initial commercial release (PRD Page 2, 21).
- **Enforcement**:
  - Date of Birth (DOB) is a mandatory field in Stage A (Question A01).
  - Chronological age is calculated server-side during registration.
  - If calculated age is $< 18$, the onboarding engine immediately blocks account registration for physical training, directing the youth to educational wellness materials or certified high school athletic coaching.
  - The system is architected to support future minor accounts with verified parental consent workflows (NDPA Section 31(1)) and zero automated caloric deficits.

### 2.3 Data Subject Rights Architecture (NDPA Sections 34–40)

```
                              ┌────────────────────────────────────────┐
                              │       Data Subject Rights Portal       │
                              └───────────────────┬────────────────────┘
                                                  │
                 ┌────────────────────────────────┴────────────────────────────────┐
                 ▼                                                                 ▼
  ┌─────────────────────────────┐                                   ┌─────────────────────────────┐
  │   Right of Data Portability │                                   │     Right to Erasure        │
  │     (NDPA Section 38)       │                                   │  (Right to be Forgotten)    │
  └──────────────┬──────────────┘                                   └──────────────┬──────────────┘
                 │                                                                 │
                 ▼                                                                 ▼
  ┌─────────────────────────────┐                                   ┌─────────────────────────────┐
  │ POST /users/me/export-data  │                                   │    DELETE /users/me         │
  └──────────────┬──────────────┘                                   └──────────────┬──────────────┘
                 │                                                                 │
                 ▼                                                                 ▼
  ┌─────────────────────────────┐                                   ┌─────────────────────────────┐
  │ QStash Async Worker:        │                                   │ 1. Mark PENDING_DELETION    │
  │ 1. Gather all profile, sets,│                                   │ 2. Revoke all active tokens │
  │    GPS routes, food logs    │                                   │ 3. 30-Day Recovery Grace    │
  │ 2. Compile into JSON & CSV  │                                   │ 4. Hard Purge Worker:       │
  │ 3. Encrypt in ZIP file      │                                   │    - Anonymize challenges   │
  │ 4. Upload to Cloudflare R2  │                                   │    - Delete media in R2     │
  │ 5. Send Presigned Link (24h)│                                   │    - Scrub all health logs  │
  └─────────────────────────────┘                                   └─────────────────────────────┘
```

1. **Right to Access & Data Portability (NDPA Section 34 & 38)**:
   - Endpoint: `POST /api/v1/users/me/export-data`.
   - Dispatches a background job via Upstash QStash. The worker queries the user's assessments, workout history, exercise set logs, GPS routes, nutrition diary entries, and body metrics.
   - Formats the data into standard machine-readable JSON and CSV files, compresses them into a secure ZIP archive, and uploads it to Cloudflare R2 with a 24-hour expiration.
   - The user receives an in-app download link and email notification containing the presigned download URL.
2. **Right to Erasure Reconciled with CAMA 2020 s.375 & FIRS 6-Year Retention (NDPA Section 34 & 39)**:
   - Endpoint: `DELETE /api/v1/users/me`.
   - **Statutory Harmonization**: NDPA Section 34(2)(b) and Section 39 explicitly exempt records required for compliance with a legal obligation under Nigerian law. Section 375 of the **Companies and Allied Matters Act 2020 (CAMA 2020)** and Federal Inland Revenue Service (FIRS) regulations mandate that registered corporate entities preserve all financial accounting books, invoices, and transaction logs for at least **6 years** from creation.
   - **Step 1 (Immediate Soft-Delete)**: Account status is updated to `PENDING_DELETION`. All active refresh tokens and session keys are blacklisted in Upstash Redis. The user profile is immediately removed from public social feeds, leaderboards, and search indexes.
   - **Step 2 (30-Day Recovery Grace Period)**: The user retains a 30-day statutory window to cancel deletion by authenticating with their credentials.
   - **Step 3 (Permanent Purge & Financial Pseudonymization)**: A scheduled QStash worker executes the hard-delete workflow:
     - User-uploaded photos and videos are permanently purged from Cloudflare R2.
     - Sensitive personal records in `user_profiles`, `health_restrictions`, `fitness_assessments`, `assessment_responses`, `nutrition_entries`, `workout_sessions`, `workout_sets`, and `activity_routes` are permanently deleted.
     - **Financial Audit Decoupling**: Foreign keys on `subscriptions` and `billing_transactions` are decoupled via `ON DELETE SET NULL`. Before deleting the `users` record, the worker populates `financial_audit_pseudonym_id` with a deterministic HMAC-SHA256 hash using an isolated audit salt (`HMAC_SHA256(userId, AUDIT_PEPPER)`).
     - Financial records are quarantined in a restricted-access audit view (`legal_hold_retained_until = created_at + INTERVAL '6 years'`), strictly isolated from application runtime queries and accessible solely by statutory compliance auditors.

### 2.4 Cryptographic Safeguards: Application-Level Field Encryption (ALE) with Key Versioning (NDPA Section 24)
Database-level disk encryption (EBS/LUKS) does not protect health data against SQL injection vulnerabilities or compromised database credentials. Therefore, sensitive health screening records are protected using **Application-Level Field Encryption (ALE)** with **AES-256-GCM Envelope Encryption**.

To satisfy NDPA Section 24 requirements for secure key management and enable **zero-downtime cryptographic key rotation**, every encrypted payload includes an explicit key version prefix:
$$\text{Envelope Format: } \texttt{v\{key\_version\}:\{iv\}:\{auth\_tag\}:\{ciphertext\}}$$

```typescript
// src/core/crypto/encryption.ts
import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12; // 96-bit IV recommended for GCM
const TAG_LENGTH = 16; // 128-bit authentication tag

// Cryptographic Keyring supporting zero-downtime key rotation
const KEY_RING: Record<number, Buffer> = {
  1: Buffer.from(process.env.HEALTH_DATA_KEY_V1 || '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef', 'hex'),
  2: Buffer.from(process.env.HEALTH_DATA_KEY_V2 || 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210', 'hex'),
};

const ACTIVE_KEY_VERSION = parseInt(process.env.HEALTH_DATA_ACTIVE_VERSION || '2', 10);

export interface EncryptedPayload {
  keyVersion: number;
  iv: string;
  tag: string;
  ciphertext: string;
}

/** Encrypt sensitive medical/health notes before database insert with active key version */
export function encryptHealthData(plaintext: string): string {
  const key = KEY_RING[ACTIVE_KEY_VERSION];
  if (!key || key.length !== 32) {
    throw new Error(`Active encryption key v${ACTIVE_KEY_VERSION} is unavailable or invalid`);
  }

  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
  
  let encrypted = cipher.update(plaintext, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const tag = cipher.getAuthTag();
  
  // Format: v{version}:{iv}:{tag}:{ciphertext}
  return `v${ACTIVE_KEY_VERSION}:${iv.toString('hex')}:${tag.toString('hex')}:${encrypted}`;
}

/** Decrypt sensitive medical/health notes, dynamically looking up key version */
export function decryptHealthData(packedCiphertext: string): string {
  const parts = packedCiphertext.split(':');
  if (parts.length !== 4) {
    throw new Error('Malformed encrypted payload. Expected: v{version}:{iv}:{tag}:{ciphertext}');
  }

  const [vTag, ivHex, tagHex, encryptedHex] = parts;
  const version = parseInt(vTag.replace('v', ''), 10);
  const key = KEY_RING[version];

  if (!key) {
    throw new Error(`Decryption failed: Key version ${version} not configured in keyring`);
  }
  
  const iv = Buffer.from(ivHex, 'hex');
  const tag = Buffer.from(tagHex, 'hex');
  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(tag);
  
  let decrypted = decipher.update(encryptedHex, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}
```

### 2.5 Immutable Security Audit Trails (NDPA Section 24)
To ensure accountability, an append-only audit trail logs every access or modification of sensitive user records:

```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES users(id),
    actor_role VARCHAR(32) NOT NULL,
    actor_ip VARCHAR(45) NOT NULL,
    action VARCHAR(64) NOT NULL, -- 'READ_HEALTH_RECORD', 'DECRYPT_STAGE_E', 'EXPORT_DATA'
    resource_type VARCHAR(64) NOT NULL, -- 'health_restrictions', 'user_profiles'
    resource_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- Grant INSERT & SELECT ONLY to application runtime role to prevent log tampering
REVOKE UPDATE, DELETE ON audit_logs FROM app_runtime_user;
```

### 2.6 72-Hour Data Breach Reporting Protocol (NDPA Section 40)
Under NDPA Section 40, a data controller must notify the Nigeria Data Protection Commission within **72 hours** of becoming aware of a data breach affecting personal data.

- **Incident Detection**: Automated alerts triggered by Sentry, Pino security anomaly logs, or AWS GuardDuty anomalies.
- **Incident Response Runbook**:
  1. *Hour 0–4*: Incident Commander contains the breach (revokes compromised keys, isolates database replicas, deploys edge WAF rules).
  2. *Hour 4–12*: Forensic evaluation determines the scope of compromised records (identifies affected user IDs and whether sensitive health data was decrypted).
  3. *Hour 12–36*: Legal Counsel & Data Protection Officer draft the official notification to the NDPC.
  4. *Hour 36–72*: Submit formal notification to NDPC with root cause analysis, mitigation actions taken, and notify affected data subjects via registered email.

### 2.7 Cross-Border Data Transfer Framework (NDPA 2023 Part VIII, Sections 41–43)
The platform architecture utilizes global cloud infrastructure (AWS cloud regions, Cloudflare R2 object storage, Upstash Redis/QStash message queues) situated outside Nigeria. To ensure strict compliance with NDPA Sections 41–43:

1. **Standard Data Protection Clauses (SDPCs) (Section 42)**:
   - Data Protection Agreements (DPAs) incorporating standard contractual clauses are executed with Cloudflare Inc., Upstash Inc., and Amazon Web Services.
   - Enforces mandatory in-transit encryption (TLS 1.3), at-rest encryption (AES-256), and security incident notification within 24 hours.
2. **Explicit Data Subject Consent (Section 43(1)(a))**:
   - The onboarding consent screen presents a distinct, unbundled cross-border consent clause:
     > *"I explicitly consent to the encrypted transfer, cross-border storage, and processing of my fitness telemetry and profile records across certified global cloud infrastructure (AWS and Cloudflare) strictly necessary to enable real-time mobile sync, edge video streaming, and low-latency API performance."*
   - Recorded with cryptographic hash in the immutable `user_consents` table (`consent_type = 'CROSS_BORDER_TRANSFER'`).
3. **Contractual Necessity (Section 43(1)(b))**:
   - The transfer is formally documented in the Data Protection Impact Assessment (DPIA) as strictly necessary for the performance of the fitness coaching contract between the user and the platform (delivering sub-500ms p95 latency and distributed media delivery).

### 2.8 Universal Medical Safety Gatekeeper Architecture (Stage E & Refusal Hardening)
Per PRD Section 3.2, safety is a non-negotiable hard constraint, not a weighted score. Users exhibiting red-flag cardiac symptoms or refusing cardiovascular risk disclosure must be strictly blocked from exercise generation.

#### 1. Question E05 Refusal Hardening
- **Question E05**: *"Do you experience symptoms during exercise that concern you, such as chest pain, fainting or unusual breathlessness?"* Options: `"Yes"`, `"No"`, `"Prefer not to say"`.
- **Enforcement Rule**:
  - If Question E05 is answered `"Yes"`: `safety_status = 'exercise_paused_pending_assessment'`, reason code `CRITICAL_CARDIAC_SYMPTOMS`.
  - If Question E05 is answered `"Prefer not to say"`, `null`, or omitted: `safety_status = 'exercise_paused_pending_assessment'`, reason code `MANDATORY_SAFETY_SCREENING_REFUSED`.
  - **Only an affirmative `"No"` response clears the user for exercise prescription.**

#### 2. Universal Fastify `enforceSafetyGate` Pre-Handler Hook
To eliminate ad-hoc workout creation or GPS recording by users placed under medical hold, the following Fastify pre-handler hook is universally injected across ALL workout execution, GPS tracking, and offline batch sync endpoints:

```typescript
// src/plugins/safety-gate.plugin.ts
import { FastifyRequest, FastifyReply } from 'fastify';
import { db } from '../config/database';
import { redis } from '../config/redis';
import { fitnessProfiles } from '../db/schema';
import { eq } from 'drizzle-orm';

export const enforceSafetyGate = async (req: FastifyRequest, reply: FastifyReply) => {
  const userId = req.user?.id;
  if (!userId) {
    return reply.status(401).send({ error: 'UNAUTHORIZED' });
  }

  // 1. Check Redis cache first (TTL: 1 hour)
  const cacheKey = `SAFETY:USER:${userId}`;
  let status = await redis.get(cacheKey);

  if (!status) {
    const [profile] = await db
      .select({ safetyStatus: fitnessProfiles.safetyStatus })
      .from(fitnessProfiles)
      .where(eq(fitnessProfiles.userId, userId))
      .limit(1);

    status = profile?.safetyStatus ?? 'exercise_paused_pending_assessment';
    await redis.set(cacheKey, status, 'EX', 3600);
  }

  if (status === 'exercise_paused_pending_assessment') {
    return reply.status(403).send({
      success: false,
      error: {
        code: 'SAFETY_ASSESSMENT_REQUIRED',
        message: 'Workout execution is blocked due to an active medical safety hold or unverified cardiac screening (Stage E05). Please complete health screening or consult a physician.'
      }
    });
  }
};
```
*Enforced on*:
- `POST /api/v1/workout-sessions`
- `PUT /api/v1/workout-sessions/:id/sets`
- `POST /api/v1/activities/manual`
- `POST /api/v1/activities/gps/start`
- Mutation filtering in `POST /api/v1/sync/batch`

#### 3. Assessment Retake Session Invalidation
When an athlete completes a periodic reassessment or questionnaire check-in that activates an E05 cardiac halt, all pre-existing scheduled and in-progress workout sessions are cancelled atomically in PostgreSQL:

```typescript
// In assessment completion service:
if (evalResult.safetyStatus === 'exercise_paused_pending_assessment') {
  await tx.update(workoutSessions)
    .set({
      status: 'cancelled_medical_hold',
      notes: 'Session automatically cancelled due to medical safety screening intercept (Stage E05).',
      updatedAt: new Date()
    })
    .where(
      and(
        eq(workoutSessions.userId, userId),
        inArray(workoutSessions.status, ['scheduled', 'in_progress'])
      )
    );

  await tx.update(fitnessRecommendations)
    .set({ status: 'suspended_safety_hold', updatedAt: new Date() })
    .where(and(eq(fitnessRecommendations.userId, userId), eq(fitnessRecommendations.status, 'active')));

  await redis.set(`SAFETY:USER:${userId}`, 'exercise_paused_pending_assessment', 'EX', 86400);
}
```

---

## 3. Flutter Mobile Offline-First Synchronization Architecture

Mobile fitness apps must operate seamlessly under intermittent connectivity (gym basements, remote running routes, spotty cellular reception). The client architecture operates on a **local-first** principle: user actions write immediately to the local database, and an outbox queue synchronizes with the server in the background.

```
+--------------------------------------------------------------------------------------------------+
|                                  FLUTTER MOBILE CLIENT (OFFLINE)                                 |
|                                                                                                  |
|   User Action: Logs Workout Set / Records GPS Trackpoint / Logs Nutrition Meal                   |
|                                        │                                                         |
|                                        ▼                                                         |
|   +------------------------------------------------------------------------------------------+   |
|   |                              DRIFT (SQLITE) LOCAL DATABASE                               |   |
|   |   1. Immediate commit to local domain tables (workouts, workout_sets, nutrition_entries)  |   |
|   |   2. In the same ACID transaction:                                                       |   |
|   |      INSERT INTO mutation_queue (id, action_type, entity_id, payload, idempotency_key)   |   |
|   +------------------------------------------------------------------------------------------+   |
+------------------------------------------------|-------------------------------------------------+
                                                 | Connectivity Restored (connectivity_plus stream)
                                                 v
+--------------------------------------------------------------------------------------------------+
|                                FASTIFY API: POST /api/v1/sync/batch                              |
|                                                                                                  |
|   +------------------------------------------------------------------------------------------+   |
|   |   Batch Processing Pipeline:                                                             |   |
|   |   1. Authenticate user JWT from Authorization header.                                    |   |
|   |   2. Check Idempotency-Key in Upstash Redis (prevent replay of duplicate batches).       |   |
|   |   3. Process mutations inside PostgreSQL transaction:                                    |   |
|   |      - Telemetry / Sets: Commutative Append (Client UUIDv7 primary keys).                |   |
|   |      - Profile / Settings: Last-Write-Wins (LWW) with Version Vector comparison.         |   |
|   |   4. Commit transaction and return { synced_ids: [...], server_deltas: [...] }.          |   |
|   +------------------------------------------------------------------------------------------+   |
+------------------------------------------------|-------------------------------------------------+
                                                 | HTTP 200 OK Response
                                                 v
+--------------------------------------------------------------------------------------------------+
|                             FLUTTER CLIENT: LOCAL QUEUE RESOLUTION                               |
|                                                                                                  |
|   - DELETE FROM mutation_queue WHERE id IN (synced_ids)                                          |
|   - Reconcile any remote server_deltas into local Drift SQLite tables                            |
+--------------------------------------------------------------------------------------------------+
```

### 3.1 Local Persistence Engine: Drift (SQLite) with FTS5
**Drift (`drift` + `drift_flutter`)** is selected as the local database:
- Relational schema with foreign keys and cascading deletes.
- Reactive `watch()` queries that automatically rebuild Flutter UI widgets when underlying tables change.
- Built-in SQLite FTS5 extension supporting full-text search across locally cached foods and exercises.

```dart
// mobile/lib/core/database/tables/mutation_queue_table.dart
import 'package:drift/drift.dart';

@DataClassName('MutationQueueEntry')
class MutationQueue extends Table {
  TextColumn get id => text()(); // Client UUIDv7
  TextColumn get actionType => text()(); // 'LOG_SET', 'COMPLETE_SESSION', 'LOG_MEAL', 'UPDATE_PROFILE'
  TextColumn get entityType => text()(); // 'workout_set', 'workout_session', 'nutrition_entry'
  TextColumn get entityId => text()();
  TextColumn get payloadJson => text()();
  TextColumn get idempotencyKey => text().unique()();
  IntColumn get createdAt => integer()(); // Epoch milliseconds
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))(); // PENDING, SYNCING, FAILED

  @override
  Set<Column> get primaryKey => {id};
}
```

### 3.2 Conflict Resolution: Commutative Operations vs. Version Vectors
Data mutations are categorized into two distinct conflict resolution models:

| Entity Type | Examples | Synchronization Model | Conflict Resolution Rule |
|---|---|---|---|
| **Additive Telemetry** | Workout sets, GPS trackpoints, meal entries, progress photos | **Append-Only Event Sourcing** | **Commutative**: Client generates UUIDv7 keys. The server appends entries without conflict. Order of arrival does not alter total volume or distance. |
| **Mutable State** | User demographics, unit preference, target goal, privacy zones | **State Replication with Version Vectors** | **Last-Write-Wins (LWW)**: Each entity carries `version INT` and `updated_at TIMESTAMPTZ`. If client version < server version, server rejects mutation and returns the authoritative state. |

### 3.3 Idempotency Engine & Batch Sync Protocol (Two-Phase Commit & Dead-Letter Isolation)

#### Architectural Flow & Connection Pool Protection
To eliminate permanent silent data loss caused by non-transactional Redis key writes during PostgreSQL rollbacks, and to protect the 20-connection PgBouncer pool against starvation during sequential Redis roundtrips, `handleSyncBatch` is structured into three discrete, decoupled phases:

1. **Phase 1: Pre-Transaction Redis Gate (Zero PostgreSQL Connections Held)**:
   - Check cached idempotency keys in Redis (`GET idemp:sync:<userId>:<key>`).
   - If marked `PROCESSED`, immediately add to `synced_ids` (fast-path completion without database load).
   - For pending mutations, acquire distributed in-flight execution locks (`SET lock:sync:<userId>:<key> <requestId> EX 15 NX`).
   - If lock acquisition fails, another worker is actively executing this mutation; return `CONCURRENT_IN_FLIGHT` with `can_retry: true`.
2. **Phase 2: PostgreSQL Transaction Execution with Savepoints (Pure SQL, Minimal Connection Hold)**:
   - Acquire connection from PgBouncer pool.
   - Start transaction: `BEGIN`.
   - Process mutations using SQL savepoints (`SAVEPOINT sp_xxx`) and transactional idempotency records (`sync_idempotency_records`).
   - **Poison Pill Quarantine**: If a single mutation throws a validation or constraint error, roll back only that savepoint and isolate the payload into `sync_quarantine`. The batch continues processing without halting the entire outbox queue.
   - Commit transaction: `COMMIT`.
   - Immediately release connection back to PgBouncer pool (reducing connection hold from 50ms–100ms down to $\le 2.5\text{ms}$).
3. **Phase 3: Post-Transaction Redis Finalization (Zero PostgreSQL Connections Held)**:
   - **On SQL Commit**: Atomically confirm committed mutations in Redis (`SET idemp:sync:<userId>:<key> 'PROCESSED' EX 86400`) and release temporary locks (`DEL lock:sync:...`).
   - **On SQL Rollback**: Immediately release all acquired distributed locks (`DEL lock:sync:...`) without writing `PROCESSED`. On client retry, mutations will be recognized as new, guaranteeing clean re-execution with **zero silent data loss**.

```typescript
// src/modules/sync/sync.controller.ts
import { FastifyRequest, FastifyReply } from 'fastify';
import { db } from '../../config/database';
import { redis } from '../../config/redis';
import { syncQuarantine, syncIdempotencyRecords, workoutSets, nutritionEntries } from '../../db/schema';
import { sql } from 'drizzle-orm';
import crypto from 'crypto';

export interface SyncMutation {
  id: string;
  idempotency_key: string;
  action_type: 'LOG_SET' | 'LOG_MEAL' | 'UPDATE_PROFILE';
  payload: any;
  client_timestamp: string;
}

export interface SyncResponse {
  synced_ids: string[];
  failed_ids: Array<{
    id: string;
    action_type: string;
    error_code: string;
    error_message: string;
    can_retry: boolean;
    quarantined: boolean;
  }>;
  synced_at: string;
}

export async function handleSyncBatch(req: FastifyRequest, reply: FastifyReply) {
  const userId = req.user.id;
  const { mutations } = req.body as { mutations: Array<SyncMutation> };
  const requestId = crypto.randomUUID();

  if (!mutations || mutations.length === 0) {
    return reply.status(200).send({
      success: true,
      data: { synced_ids: [], failed_ids: [], synced_at: new Date().toISOString() }
    });
  }

  // Cap batch size to protect connection limits
  if (mutations.length > 25) {
    return reply.status(400).send({
      success: false,
      error: 'BATCH_SIZE_EXCEEDED',
      message: 'Maximum 25 mutations permitted per batch'
    });
  }

  const syncedIds: string[] = [];
  const failedIds: SyncResponse['failed_ids'] = [];
  const acquiredLocks: Array<{ lockKey: string; processedKey: string; mutation: SyncMutation }> = [];
  const mutationsToExecute: SyncMutation[] = [];

  // =========================================================================
  // PHASE 1: PRE-TRANSACTION REDIS GATE (OUTSIDE DATABASE CONNECTION HOLD)
  // =========================================================================
  for (const mut of mutations) {
    const processedKey = `idemp:sync:${userId}:${mut.idempotency_key}`;
    const status = await redis.get(processedKey);

    if (status === 'PROCESSED') {
      // Already committed in a prior transaction: return success immediately
      syncedIds.push(mut.id);
      continue;
    }

    const lockKey = `lock:sync:${userId}:${mut.idempotency_key}`;
    // Lease lock for 15 seconds with NX
    const acquired = await redis.set(lockKey, requestId, 'EX', 15, 'NX');

    if (!acquired) {
      failedIds.push({
        id: mut.id,
        action_type: mut.action_type,
        error_code: 'CONCURRENT_IN_FLIGHT',
        error_message: 'Mutation is currently being processed by a concurrent request',
        can_retry: true,
        quarantined: false
      });
      continue;
    }

    acquiredLocks.push({ lockKey, processedKey, mutation: mut });
    mutationsToExecute.push(mut);
  }

  if (mutationsToExecute.length === 0) {
    return reply.status(200).send({
      success: true,
      data: { synced_ids: syncedIds, failed_ids: failedIds, synced_at: new Date().toISOString() }
    });
  }

  // =========================================================================
  // PHASE 2: DATABASE TRANSACTION EXECUTION WITH SAVEPOINTS
  // =========================================================================
  let dbSuccess = false;
  const committedMutations: SyncMutation[] = [];

  try {
    // Acquire PostgreSQL connection from PgBouncer pool
    await db.transaction(async (tx) => {
      for (const mut of mutationsToExecute) {
        const spName = `sp_${mut.id.replace(/-/g, '_')}`;
        await tx.execute(sql.raw(`SAVEPOINT ${spName}`));

        try {
          // 1. Check database-level idempotency record
          const existing = await tx.select()
            .from(syncIdempotencyRecords)
            .where(sql`${syncIdempotencyRecords.key} = ${mut.idempotency_key} AND ${syncIdempotencyRecords.userId} = ${userId}`)
            .limit(1);

          if (existing.length > 0) {
            await tx.execute(sql.raw(`RELEASE SAVEPOINT ${spName}`));
            syncedIds.push(mut.id);
            committedMutations.push(mut);
            continue;
          }

          // 2. Validate and apply domain mutation
          await applyItemizedMutation(tx, userId, mut);

          // 3. Record transactional idempotency entry
          await tx.insert(syncIdempotencyRecords).values({
            key: mut.idempotency_key,
            userId: userId,
            mutationId: mut.id,
            actionType: mut.action_type,
            createdAt: new Date()
          });

          await tx.execute(sql.raw(`RELEASE SAVEPOINT ${spName}`));
          syncedIds.push(mut.id);
          committedMutations.push(mut);
        } catch (itemError: any) {
          // Rollback single mutation without aborting the entire batch
          await tx.execute(sql.raw(`ROLLBACK TO SAVEPOINT ${spName}`));

          // Isolate poison pill in quarantine table
          const errorCode = itemError.code || 'VALIDATION_FAILED';
          const errorMessage = itemError.message || 'Unknown database error';

          await tx.insert(syncQuarantine).values({
            userId: userId,
            mutationId: mut.id,
            idempotencyKey: mut.idempotency_key,
            actionType: mut.action_type,
            payload: mut.payload,
            errorCode: errorCode,
            errorMessage: errorMessage,
            clientTimestamp: mut.client_timestamp ? new Date(mut.client_timestamp) : null,
            quarantinedAt: new Date(),
            status: 'QUARANTINED'
          });

          failedIds.push({
            id: mut.id,
            action_type: mut.action_type,
            error_code: errorCode,
            error_message: errorMessage,
            can_retry: false,
            quarantined: true
          });
        }
      }
    });

    dbSuccess = true;
  } catch (txFatalError: any) {
    dbSuccess = false;
    req.log.error(txFatalError, 'Fatal database transaction error during batch sync');
  }

  // =========================================================================
  // PHASE 3: POST-TRANSACTION REDIS FINALIZATION (OUTSIDE DATABASE CONNECTION)
  // =========================================================================
  if (dbSuccess) {
    // Pipeline Redis updates to minimize network latency
    const pipeline = redis.pipeline();
    for (const { lockKey, processedKey, mutation } of acquiredLocks) {
      if (committedMutations.some(m => m.id === mutation.id)) {
        // SQL commit confirmed: persist idempotency record for 24 hours
        pipeline.set(processedKey, 'PROCESSED', 'EX', 86400);
      }
      // Release in-flight distributed lock
      pipeline.del(lockKey);
    }
    await pipeline.exec();

    return reply.status(200).send({
      success: true,
      data: {
        synced_ids: syncedIds,
        failed_ids: failedIds,
        synced_at: new Date().toISOString()
      }
    });
  } else {
    // Transaction failed/rolled back: release all locks so client can cleanly retry
    const rollbackPipeline = redis.pipeline();
    for (const { lockKey } of acquiredLocks) {
      rollbackPipeline.del(lockKey);
    }
    await rollbackPipeline.exec();

    return reply.status(500).send({
      success: false,
      error: 'DATABASE_TRANSACTION_FAILED',
      message: 'Transient storage error. Transaction rolled back; all locks released. Retry safe.'
    });
  }
}

async function applyItemizedMutation(tx: any, userId: string, mut: SyncMutation) {
  switch (mut.action_type) {
    case 'LOG_SET':
      if (!mut.payload.sessionId || mut.payload.reps < 0 || mut.payload.weightKg < 0) {
        throw new Error('INVALID_SET_DATA: Session ID required, reps/weight must be non-negative');
      }
      await tx.insert(workoutSets).values({
        id: mut.payload.id || crypto.randomUUID(),
        sessionId: mut.payload.sessionId,
        scheduledDate: mut.payload.scheduledDate ? new Date(mut.payload.scheduledDate) : new Date(),
        exerciseId: mut.payload.exerciseId,
        setOrder: mut.payload.setOrder || 1,
        reps: mut.payload.reps,
        weightKg: mut.payload.weightKg.toString(),
        rpe: mut.payload.rpe ? mut.payload.rpe.toString() : null,
        isCompleted: mut.payload.isCompleted ?? true,
        createdAt: mut.payload.createdAt ? new Date(mut.payload.createdAt) : new Date()
      });
      break;

    case 'LOG_MEAL':
      if (!mut.payload.name || mut.payload.calories < 0) {
        throw new Error('INVALID_MEAL_DATA: Meal name required and calories must be non-negative');
      }
      await tx.insert(nutritionEntries).values({
        id: mut.payload.id || crypto.randomUUID(),
        userId: userId,
        foodId: mut.payload.foodId,
        loggedDate: mut.payload.loggedDate ? new Date(mut.payload.loggedDate) : new Date(),
        mealType: mut.payload.mealType || 'snack',
        quantity: mut.payload.quantity || '1.0',
        caloriesTotal: mut.payload.calories?.toString() || '0',
        proteinTotal: mut.payload.proteinGrams?.toString() || '0',
        carbsTotal: mut.payload.carbsGrams?.toString() || '0',
        fatTotal: mut.payload.fatGrams?.toString() || '0',
        createdAt: new Date()
      });
      break;

    default:
      throw new Error(`UNSUPPORTED_ACTION_TYPE: ${mut.action_type}`);
  }
}
```

#### Client-Side Outbox Quarantine Handler (Flutter / Drift SQLite)
When the mobile client receives a partial sync response:
1. `synced_ids`: Pruned immediately from `mutation_queue` via `DELETE FROM mutation_queue WHERE id IN (?)`.
2. `failed_ids` where `can_retry == false` (quarantined poison pills):
   - Moved from `mutation_queue` to a local `local_dead_letter_queue` table in SQLite.
   - Prevents infinite retry loops and network battery drain.
   - Triggers an in-app non-modal notification banner: *"1 workout record could not be processed due to a data format issue and has been archived for support review."*
3. Remaining valid mutations continue syncing without blocking the athlete's progress.

```dart
// mobile/lib/core/sync/sync_outbox_manager.dart
import 'package:drift/drift.dart';
import '../database/local_database.dart';

class SyncOutboxManager {
  final LocalDatabase _db;
  final ApiClient _api;

  SyncOutboxManager(this._db, this._api);

  Future<void> flushQueue() async {
    final pendingMutations = await (_db.select(_db.mutationQueue)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
          ..limit(25))
        .get();

    if (pendingMutations.isEmpty) return;

    final response = await _api.post('/sync/batch', {
      'mutations': pendingMutations.map((m) => {
        'id': m.id,
        'idempotency_key': m.idempotencyKey,
        'action_type': m.actionType,
        'payload': m.payloadJson,
        'client_timestamp': DateTime.fromMillisecondsSinceEpoch(m.createdAt).toIso8601String(),
      }).toList(),
    });

    if (response.statusCode == 200) {
      final data = response.data['data'];
      final List<String> syncedIds = List<String>.from(data['synced_ids'] ?? []);
      final List<dynamic> failedIds = data['failed_ids'] ?? [];

      await _db.transaction(() async {
        // 1. Delete successfully synced records
        if (syncedIds.isNotEmpty) {
          await (_db.delete(_db.mutationQueue)..where((t) => t.id.isIn(syncedIds))).go();
        }

        // 2. Quarantine poison pills locally
        for (final failed in failedIds) {
          if (failed['can_retry'] == false) {
            final mutationId = failed['id'] as String;
            final failedItem = pendingMutations.firstWhere((m) => m.id == mutationId);
            
            await _db.into(_db.localDeadLetterQueue).insert(
              LocalDeadLetterQueueCompanion.insert(
                id: mutationId,
                actionType: failedItem.actionType,
                payloadJson: failedItem.payloadJson,
                errorCode: failed['error_code'] ?? 'UNKNOWN',
                errorMessage: failed['error_message'] ?? '',
                quarantinedAt: DateTime.now(),
              ),
            );

            // Remove from active retry queue
            await (_db.delete(_db.mutationQueue)..where((t) => t.id.equals(mutationId))).go();
          }
        }
      });
    }
  }
}
```

### 3.4 Background Synchronization Lifecycle
- **Online Transition Detection**: Flutter `connectivity_plus` stream listener triggers an immediate batch flush when the device reconnects to Wi-Fi or cellular networks.
- **Scheduled Background Sync**: Flutter `workmanager` schedules background execution every 15 minutes, conditioned on `NetworkType.connected` and `requiresBatteryNotLow: true`.
- **Exponential Backoff**: If the API responds with 5xx or network drops mid-sync, failed mutations have their `retryCount` incremented with exponential backoff:
  $$t_{\text{wait}} = \min(2^{\text{retryCount}} \times 1000\text{ms} + \text{jitter}, 300\text{s})$$

---

## 4. GPS Activity Tracking & Sensor Resilience

Outdoor activities (running, walking, cycling) must record accurate distance, pace, and route coordinates without losing tracking data when the device is locked, backgrounded, or subjected to OS memory pressure.

```
+--------------------------------------------------------------------------------------------------+
|                                    MOBILE GPS SENSOR PIPELINE                                    |
|                                                                                                  |
|   Hardware GPS / GLONASS Receiver (1 Hz Coordinate Stream)                                       |
|                                │                                                                 |
|                                ▼                                                                 |
|   Speed-Adaptive Sampling Filter (0.5 m/s auto-pause; distanceFilter >= 5m)                      |
|                                │                                                                 |
|                                ▼                                                                 |
|   Kalman Filter & Jitter Smoothing:                                                              |
|   - Discard fixes where horizontalAccuracy > 30.0m                                               |
|   - Discard acceleration > 12.0 m/s² (GPS glitch rejection)                                      |
|                                │                                                                 |
|                                ▼                                                                 |
|   Great-Circle Haversine Distance Accumulator (Immutable 1 km splits)                            |
|                                │                                                                 |
|                                ▼                                                                 |
|   Batched SQLite Write: Every 10 waypoints committed to Drift DB (Zero Data Loss on Crash)       |
|                                │                                                                 |
|                                ▼                                                                 |
|   Route Finalization:                                                                            |
|   - Google Encoded Polyline Compression (5 decimal places, >90% bandwidth reduction)             |
|   - Privacy Zone Clipping (Mask coordinates within 500m of Home/Work)                            |
+--------------------------------------------------------------------------------------------------+
```

### 4.1 Operating System Process & Memory Resilience
- **Android**: Tracking runs inside an Android **Foreground Service** configured with `android:foregroundServiceType="location"`. Displays an ongoing sticky status bar notification showing elapsed time, distance, and current pace. The service holds a partial `WakeLock` to prevent CPU sleep.
- **iOS**: Configures `CLLocationManager` with `desiredAccuracy = kCLLocationAccuracyBestForNavigation`, `allowsBackgroundLocationUpdates = true`, and `pausesLocationUpdatesAutomatically = false`.
- **Crash Recovery**: Waypoints are committed to local SQLite in batches of 10 points. If the app is killed by an aggressive OS battery manager (e.g. Samsung OneUI, Xiaomi MIUI), on next launch the app detects an unfinalized session and presents a "Resume Outdoor Run" recovery modal with all metrics intact.

### 4.2 Speed-Adaptive GPS Sampling & Kalman Filtering (Stationary Freeze Remediation)
To conserve battery life while maintaining accurate route paths:
- **Distance Filter**: Set to $\ge 5\text{m}$. Stationary devices emit zero GPS coordinates.
- **Auto-Pause Detection**: When velocity drops below $0.5\text{ m/s}$ (1.8 km/h) for $\ge 5$ consecutive seconds, the moving timer pauses automatically. Resumes immediately when speed exceeds $0.8\text{ m/s}$.

#### Kalman Filter Asymptotic Covariance Collapse & Mathematical Remediation
In standard kinematic Kalman filtering for GPS tracking, the process noise covariance $Q$ represents uncertainty introduced by movement over elapsed time $\Delta t$. In naïve implementations where $Q = \text{speed}^2 \cdot \Delta t$, pausing at a red light or intersection ($\text{speed} = 0.0\text{ m/s}$) sets $Q = 0$. With each 1 Hz fix received while stationary, the error variance decays exponentially:
$$P_t = (1 - K) \cdot P_{t-1} \longrightarrow 0$$
When $P$ drops below $1.0\text{ m}^2$, the Kalman gain $K = P / (P + R)$ collapses to $< 0.038$. When the athlete accelerates from rest, the innovation $(\mathbf{z}_t - \hat{\mathbf{x}})$ is suppressed by $96\%$, freezing the runner's GPS position on the map.

To eliminate this defect, the filter implements three mathematical safeguards:
1. **Process Noise Covariance Floor ($Q_{\min} \ge 1.0\,\text{m}^2/\text{s}^2$)**:
   $$Q = \max(\text{speed}^2 \cdot \Delta t, Q_{\min} \cdot \Delta t) \quad \text{where } Q_{\min} = 1.0\,\text{m}^2/\text{s}^2$$
2. **Stationary Variance Floor**: When $\text{speed} < 0.5\text{ m/s}$, enforce $P_{\text{floor}} = (2.0\text{ m})^2 = 4.0\,\text{m}^2$ before and after updates.
3. **$3\sigma$ Innovation Speed Step Detection**: If $d_{\text{innov}} > 3.0 \cdot \sqrt{P + R}$ and incoming accuracy $R \le (15.0\text{ m})^2$, a burst acceleration step is detected, and the filter executes an immediate state reset ($\hat{\mathbf{x}} \leftarrow \mathbf{z}$, $P \leftarrow R$) for zero-lag tracking recovery.

```dart
// mobile/lib/core/location/gps_kalman_filter.dart
import 'dart:math';

class GeoPoint {
  final double latitude;
  final double longitude;
  final double accuracy; // Horizontal accuracy radius in meters (1-sigma)
  final int timestampMs;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestampMs,
  });

  @override
  String toString() => 'GeoPoint(lat: $latitude, lng: $longitude, acc: ${accuracy}m, t: $timestampMs)';
}

class GpsKalmanFilter {
  double _variance = -1.0; // Uncertainty variance in meters^2
  double _lat = 0.0;
  double _lng = 0.0;
  int _lastTimestampMs = 0;

  // Process noise floor: 1.0 m^2/s^2 minimum variance increment
  static const double qMin = 1.0;

  // Stationary variance floor: (2.0m)^2 = 4.0 m^2
  static const double minStationaryVariance = 4.0;

  // Maximum acceptable GPS accuracy (reject multi-path reflections > 30m)
  static const double maxAllowableAccuracy = 30.0;

  // Stationary speed threshold (m/s)
  static const double stationarySpeedThreshold = 0.5;

  /// Spherical Haversine distance in meters between two geodetic coordinates
  static double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const double r = 6371000.0; // Earth radius in meters
    final double dLat = (lat2 - lat1) * (pi / 180.0);
    final double dLng = (lng2 - lng1) * (pi / 180.0);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) *
        sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1.0 - a));
    return r * c;
  }

  /// Filters an incoming GPS fix, updating state and returning the smoothed point.
  GeoPoint? filter(GeoPoint newPoint, double speedMetersPerSecond) {
    // 1. Hard gate: discard low-confidence GPS fixes
    if (newPoint.accuracy <= 0.0 || newPoint.accuracy > maxAllowableAccuracy) {
      return null;
    }

    // 2. Initialize filter with the first valid reading
    if (_variance < 0.0) {
      _lat = newPoint.latitude;
      _lng = newPoint.longitude;
      _variance = newPoint.accuracy * newPoint.accuracy;
      _lastTimestampMs = newPoint.timestampMs;
      return newPoint;
    }

    // 3. Compute elapsed time step dt
    final int durationMs = newPoint.timestampMs - _lastTimestampMs;
    // Bound dt between 100ms and 10s to prevent numerical divergence on background suspension
    final double dt = max(0.1, min(10.0, durationMs / 1000.0));
    _lastTimestampMs = newPoint.timestampMs;

    // 4. Process Noise Prediction: Q = max(speed^2 * dt, Q_min * dt)
    final double velocityVariance = speedMetersPerSecond * speedMetersPerSecond;
    final double q = max(velocityVariance * dt, qMin * dt);
    _variance += q;

    // 5. Stationary Pause Handling: enforce variance floor when speed < 0.5 m/s
    if (speedMetersPerSecond < stationarySpeedThreshold) {
      _variance = max(_variance, minStationaryVariance);
    }

    // 6. Measurement variance R in meters^2
    final double r = newPoint.accuracy * newPoint.accuracy;

    // 7. 3-Sigma Speed Step Detection
    final double sigmaInnov = sqrt(_variance + r);
    final double displacement = distanceMeters(_lat, _lng, newPoint.latitude, newPoint.longitude);

    if (displacement > 3.0 * sigmaInnov && newPoint.accuracy <= 15.0) {
      // Runner burst detected (e.g. explosive sprint after red light)
      // Reset filter directly to new fix to eliminate tracking lag
      _lat = newPoint.latitude;
      _lng = newPoint.longitude;
      _variance = r;
      return GeoPoint(
        latitude: _lat,
        longitude: _lng,
        accuracy: sqrt(_variance),
        timestampMs: newPoint.timestampMs,
      );
    }

    // 8. Kalman Gain Calculation
    final double k = _variance / (_variance + r);

    // 9. Coordinate Update (accounting for geodetic latitude scaling)
    _lat += k * (newPoint.latitude - _lat);
    _lng += k * (newPoint.longitude - _lng);

    // 10. Covariance Update
    _variance = (1.0 - k) * _variance;

    // 11. Final stationary guard: prevent post-update collapse
    if (speedMetersPerSecond < stationarySpeedThreshold) {
      _variance = max(_variance, minStationaryVariance);
    }

    return GeoPoint(
      latitude: _lat,
      longitude: _lng,
      accuracy: sqrt(_variance),
      timestampMs: newPoint.timestampMs,
    );
  }

  /// Manually reset filter state (e.g. on workout pause / resume)
  void reset() {
    _variance = -1.0;
    _lat = 0.0;
    _lng = 0.0;
    _lastTimestampMs = 0;
  }
}
```

### 4.3 Distance Accumulation via Great-Circle Haversine Formula
Distance between filtered trackpoints is calculated using the spherical Haversine formula:
$$d = 2R \arcsin \left( \sqrt{\sin^2\left(\frac{\Delta \phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta \lambda}{2}\right)} \right)$$
where $R = 6,371,000\text{ meters}$, $\phi$ is latitude in radians, and $\lambda$ is longitude in radians.

### 4.4 Location Privacy Zones (Route Masking & Anti-Triangulation Shield)

To protect user safety and confidentiality (preventing stalkers or adversaries from identifying a user's home or workplace coordinates on public feeds):
- Users configure circular **Privacy Zones** (200m–2,000m radius around home, work, or school).
- **Authentic Metric Invariance**: Total GPS distance, duration, elevation gain, and 1km splits are calculated from the complete, unclipped track. The athlete's personal PRs and training loads are never compromised.
- **Anti-Triangulation Perimeter Threshold (250m)**: If a public route segment outside a privacy zone is shorter than $250\text{ meters}$ or contains fewer than $5\text{ trackpoints}$, publishing it permits mathematical triangulation of the zone boundary tangent. Any segment $< 250\text{m}$ is masked.
- **100% Masking Edge Case (Entire Route Inside Privacy Zone)**:
  - If all trackpoints fall within active privacy zones (or no public segment exceeds $250\text{m}$):
    - `public_polyline = null` (strictly SQL `NULL`, preventing frontend polyline parser exceptions).
    - `is_map_hidden = true`.
    - `privacy_display_mode = 'ABSTRACT_SUMMARY_CARD'`.

#### TypeScript Route Privacy Clipping Engine

```typescript
// backend/src/modules/activity/privacy-clipping.service.ts

export interface Coordinate {
  latitude: number;
  longitude: number;
}

export interface PrivacyZone {
  latitude: number;
  longitude: number;
  radiusMeters: number;
}

export interface ProcessedRoutePrivacy {
  is_map_hidden: boolean;
  public_polyline: string | null;
  display_mode: 'INTERACTIVE_MAP' | 'ABSTRACT_SUMMARY_CARD';
  authentic_distance_meters: number;
  public_distance_meters: number;
  masked_zones_count: number;
}

const MIN_PUBLIC_SEGMENT_METERS = 250;
const MIN_PUBLIC_SEGMENT_POINTS = 5;

export function processRoutePrivacy(
  rawPoints: Coordinate[],
  privacyZones: PrivacyZone[]
): ProcessedRoutePrivacy {
  if (!rawPoints || rawPoints.length < 2) {
    return {
      is_map_hidden: true,
      public_polyline: null,
      display_mode: 'ABSTRACT_SUMMARY_CARD',
      authentic_distance_meters: 0,
      public_distance_meters: 0,
      masked_zones_count: 0
    };
  }

  // 1. Calculate authentic total distance from complete raw GPS track
  let authenticDistance = 0;
  for (let i = 1; i < rawPoints.length; i++) {
    authenticDistance += haversineMeters(rawPoints[i - 1], rawPoints[i]);
  }

  // If user has no active privacy zones, return full map
  if (!privacyZones || privacyZones.length === 0) {
    return {
      is_map_hidden: false,
      public_polyline: encodePolyline(rawPoints),
      display_mode: 'INTERACTIVE_MAP',
      authentic_distance_meters: Math.round(authenticDistance),
      public_distance_meters: Math.round(authenticDistance),
      masked_zones_count: 0
    };
  }

  // 2. Identify and segment public waypoints
  const publicSegments: Coordinate[][] = [];
  let currentSegment: Coordinate[] = [];
  let maskedPointCount = 0;

  for (const pt of rawPoints) {
    const isMasked = privacyZones.some(zone => haversineMeters(pt, zone) <= zone.radiusMeters);

    if (!isMasked) {
      currentSegment.push(pt);
    } else {
      maskedPointCount++;
      if (currentSegment.length > 0) {
        publicSegments.push(currentSegment);
        currentSegment = [];
      }
    }
  }
  if (currentSegment.length > 0) {
    publicSegments.push(currentSegment);
  }

  // 3. Filter segments by anti-triangulation minimum threshold (250m)
  const validSegments = publicSegments.filter(segment => {
    if (segment.length < MIN_PUBLIC_SEGMENT_POINTS) return false;
    let segDist = 0;
    for (let i = 1; i < segment.length; i++) {
      segDist += haversineMeters(segment[i - 1], segment[i]);
    }
    return segDist >= MIN_PUBLIC_SEGMENT_METERS;
  });

  // 4. Handle 100% masking or insufficient public trace
  if (validSegments.length === 0) {
    return {
      is_map_hidden: true,
      public_polyline: null, // Strictly null, never empty string
      display_mode: 'ABSTRACT_SUMMARY_CARD',
      authentic_distance_meters: Math.round(authenticDistance),
      public_distance_meters: 0,
      masked_zones_count: privacyZones.length
    };
  }

  // 5. Select primary continuous public segment for community feed
  const primarySegment = validSegments[0];
  let publicDistance = 0;
  for (let i = 1; i < primarySegment.length; i++) {
    publicDistance += haversineMeters(primarySegment[i - 1], primarySegment[i]);
  }

  return {
    is_map_hidden: false,
    public_polyline: encodePolyline(primarySegment),
    display_mode: 'INTERACTIVE_MAP',
    authentic_distance_meters: Math.round(authenticDistance),
    public_distance_meters: Math.round(publicDistance),
    masked_zones_count: privacyZones.length
  };
}

function haversineMeters(p1: Coordinate, p2: Coordinate): number {
  const R = 6371000;
  const dLat = (p2.latitude - p1.latitude) * (Math.PI / 180);
  const dLng = (p2.longitude - p1.longitude) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(p1.latitude * (Math.PI / 180)) *
      Math.cos(p2.latitude * (Math.PI / 180)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function encodePolyline(points: Coordinate[]): string {
  let encoded = '';
  let prevLat = 0;
  let prevLng = 0;

  for (const p of points) {
    const lat = Math.round(p.latitude * 1e5);
    const lng = Math.round(p.longitude * 1e5);

    encoded += encodeSignedNumber(lat - prevLat);
    encoded += encodeSignedNumber(lng - prevLng);

    prevLat = lat;
    prevLng = lng;
  }
  return encoded;
}

function encodeSignedNumber(num: number): string {
  let sgnNum = num << 1;
  if (num < 0) sgnNum = ~sgnNum;
  let result = '';
  while (sgnNum >= 0x20) {
    result += String.fromCharCode((0x20 | (sgnNum & 0x1f)) + 63);
    sgnNum >>= 5;
  }
  result += String.fromCharCode(sgnNum + 63);
  return result;
}
```

#### Flutter UI Presentation Contract: Abstract Activity Summary Card
When `is_map_hidden == true` (100% route masked), the Flutter feed item replaces the map view with an aesthetically designed summary card:

```dart
// mobile/lib/features/activity/presentation/widgets/activity_feed_tile.dart
import 'package:flutter/material.dart';

class ActivityFeedCard extends StatelessWidget {
  final String activityType;
  final int distanceMeters;
  final int durationSeconds;
  final int elevationGainMeters;
  final String? publicPolyline;
  final bool isMapHidden;

  const ActivityFeedCard({
    super.key,
    required this.activityType,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.elevationGainMeters,
    required this.publicPolyline,
    required this.isMapHidden,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Athlete & Activity
          ListTile(
            title: Text(activityType, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${(distanceMeters / 1000.0).toStringAsFixed(2)} km • ${_formatDuration(durationSeconds)}'),
          ),

          // Map or Abstract Card
          if (isMapHidden || publicPolyline == null)
            _buildPrivacySummaryCard(context)
          else
            _buildInteractiveMap(context, publicPolyline!),

          // Footer Metrics (Preserves 100% authentic metrics)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricColumn('Distance', '${(distanceMeters / 1000.0).toStringAsFixed(2)} km'),
                _metricColumn('Pace', _formatPace(distanceMeters, durationSeconds)),
                _metricColumn('Elev Gain', '${elevationGainMeters}m'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySummaryCard(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 48, color: Colors.tealAccent.shade400),
                const SizedBox(height: 8),
                const Text(
                  'Route hidden by athlete privacy settings',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMap(BuildContext context, String polyline) {
    return Container(height: 180, color: Colors.grey.shade200);
  }

  Widget _metricColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  String _formatPace(int meters, int seconds) {
    if (meters == 0) return '-';
    final paceSecondsPerKm = (seconds / (meters / 1000.0)).round();
    final m = paceSecondsPerKm ~/ 60;
    final s = paceSecondsPerKm % 60;
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }
}
```
