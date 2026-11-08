# raize

> **Raize: Unified Athletic Conditioning, Biomechanics & Localized Nutrition Platform**
> Built for iOS & Android with Flutter (Riverpod, Material 3, AMOLED & Sleek Light themes) and backed by Node.js Fastify, Drizzle ORM, PostgreSQL, Redis, Argon2id security, and NDPA 2023 compliance.

---

## 🌟 Key Features

### 1. 🛡️ Authentication & NDPA 2023 Compliance
- **Credential & Session Caching**: "Remember Me" credential caching with biometric Face ID / Touch ID standby.
- **Username & Handle Login**: First-class support for `@username` handles and email authentication.
- **Statutory Privacy**: Full compliance with the Nigeria Data Protection Act (NDPA) 2023, including Section 24 Right to Erasure ("Type DELETE to confirm") and automated audit logging.

### 2. ⚡ Athlete Dashboard & Desktop Widgets
- **Daily Step Telemetry**: Real-time step progress against dynamic user targets (default 10,000 steps), distance, active burn kcal, and streak tracking.
- **Interactive Home Screen Widgets**: 2×2 Compact and 4×2 Panoramic desktop widgets with glassmorphic cards and dynamic live updates.
- **Adaptive Dual-Theme System**: Instant toggling between AMOLED Dark mode (`#0B0F17`) and Sleek Light mode (`#F8FAFC`).

### 3. 🗺️ Precision GPS Telemetry & Strava-Level Running
- **Light & Dark Vector Map Canvas**: Real-time route painter with split markers, road casings, botanical green spaces, and high-contrast pace gradients.
- **Privacy Zone Protection**: Configurable 250m circular safe zones around athlete residences to protect privacy on public leaderboards.
- **Kalman Filtering**: Speed-adaptive location smoothing, active pace surge detection, elevation tracking, and heart-rate telemetry.

### 4. 🏋️ Structured Workouts & 3D Human Rig Kinematics
- **One-Tap Session Execution**: "Start Activity" flow initiates real-time session tracking, elapsed timers, and active volume calculations.
- **3D Biomechanical Rig Demonstration**: Real-time 3D skeleton animation displaying joint angles (e.g., Elbow 119°), 3-plane camera angles (45° oblique, frontal, lateral), tempo metronomes (3-1-1-0), Valsalva breathing cues, and Cloudflare R2 video streaming toggle.
- **Set Logging & Rest Interval HUD**: Instant set completion with green checkmark confirmation, estimated 1RM calculations, and live rest interval countdowns with `+30s` extension and skip triggers.

### 5. 🥗 Nutrition OS & Localized African Diet Tracking
- **Mifflin-St Jeor TDEE Equation**: Dynamic daily calorie deficit / surplus budget with real-time balance calculations (`Target - Consumed + Exercise Burned = Remaining`).
- **Nigerian Food Database (v2.4)**: Calibrated macros for staple African meals (Pounded Yam with Lagos tuber density, Egusi Soup, Beef Suya) with colloquial portion measures (derica, mudu, wraps, sticks, parcel).
- **Macro Progress Telemetry**: Dedicated real-time indicators for Protein, Carbohydrates, and Fats.

### 6. 💳 Billing, Paywall & Account Settings
- **Multi-Tier Protocols**: Free 7-Day Trial, Annual Athletic Pass (₦45,000/yr), Monthly Flexible (₦5,000/mo), and 1-on-1 Certified Coach Tier (₦25,000/mo).
- **Paystack Payment Integration**: Local NGN payment channels with statutory CAMA 2020 receipts and 256-bit bank encryption.
- **Account Settings**: Self-service subscription cancellation and irreversible account deletion modal.

---

## 🏛️ Project Architecture

```
raize/
├── backend/                  # Fastify REST API Server
│   ├── src/
│   │   ├── db/              # Drizzle ORM schema & Postgres migrations
│   │   ├── modules/         # Auth, Assessment, Dashboard, Workouts, Nutrition, Billing
│   │   ├── services/        # Email (SendByte), Cache (Redis), Crypto (Argon2id)
│   │   └── tests/           # Vitest integration test suite (38 tests)
│   ├── drizzle.config.ts    # Drizzle ORM configuration
│   └── package.json
│
├── mobile/                   # Flutter Mobile Client (iOS & Android)
│   ├── lib/
│   │   ├── core/            # Theme, constants, network client, local storage
│   │   └── features/        # Auth, Dashboard, Activities (GPS), Workouts, Nutrition, Profile, Billing
│   ├── test/                # Flutter unit & widget test suite (63 tests)
│   └── pubspec.yaml
│
└── docs/                     # Design specs, schema documentation, and API guides
```

---

## 🚀 Getting Started

### Backend Setup
```bash
cd backend
pnpm install
pnpm db:migrate
pnpm dev
```

### Mobile Setup
```bash
cd mobile
flutter pub get
flutter run
```

---

## 🧪 Testing

```bash
# Run backend test suite (38 passing tests)
cd backend && pnpm test

# Run mobile test suite (63 passing tests)
cd mobile && flutter test
```

---

## 📜 License
Proprietary & Confidential • All Rights Reserved.
