import { describe, it, expect } from 'vitest';
import {
  calculateAge,
  calculateBMR,
  calculateTDEE,
  calculateTargetCalories,
  scoreActivitySuitability,
  generateWeeklySchedule,
  haversineDistanceMeters,
  maskPrivacyZones,
  UserAssessmentInput,
} from '../utils/calculator.js';

describe('Biometric & Energy Calculations (Mifflin-St Jeor)', () => {
  it('accurately calculates user age from DOB', () => {
    const age = calculateAge('2000-01-15');
    expect(age).toBeGreaterThanOrEqual(25);
  });

  it('calculates male BMR accurately', () => {
    // 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
    const bmr = calculateBMR(80, 180, 30, 'male');
    expect(bmr).toBe(1780);
  });

  it('calculates female BMR accurately', () => {
    // 10*60 + 6.25*165 - 5*25 - 161 = 600 + 1031.25 - 125 - 161 = 1345.25 -> 1345
    const bmr = calculateBMR(60, 165, 25, 'female');
    expect(bmr).toBe(1345);
  });

  it('scales TDEE by physical activity level', () => {
    const bmr = 1500;
    expect(calculateTDEE(bmr, 'sitting')).toBe(1800); // 1.2
    expect(calculateTDEE(bmr, 'some_movement')).toBe(2063); // 1.375
    expect(calculateTDEE(bmr, 'frequently_standing')).toBe(2325); // 1.55
  });

  it('protects minors from automated caloric deficit prescriptions', () => {
    const tdee = 2200;
    // Under 18: no deficit allowed
    const minorTarget = calculateTargetCalories(tdee, 'weight_loss', 16, 'male');
    expect(minorTarget).toBe(2200);

    // 18+: standard 500 kcal deficit
    const adultTarget = calculateTargetCalories(tdee, 'weight_loss', 25, 'male');
    expect(adultTarget).toBe(1700);
  });

  it('respects safety caloric floor for adults', () => {
    const lowTdee = 1400;
    // Female floor is 1200 kcal even if deficit would suggest 900
    const femaleTarget = calculateTargetCalories(lowTdee, 'weight_loss', 28, 'female');
    expect(femaleTarget).toBe(1200);
  });
});

describe('7-Factor Activity Suitability Scorer S(a,u)', () => {
  const baseUser: UserAssessmentInput = {
    age: 26,
    primaryGoal: 'weight_management',
    fitnessLevel: 'beginner',
    frequency: '1_2_times',
    typicalDay: 'some_movement',
    weeklyDays: 3,
    sessionMinutes: 30,
    environment: 'outdoor',
    equipment: ['none'],
    enjoyedActivities: ['walking', 'cardio'],
  };

  it('gives high score to matching beginner outdoor walking', () => {
    const activity = {
      category: 'cardio',
      primaryGoal: 'weight_management',
      difficultyLevel: 'beginner',
      equipmentRequired: ['none'],
      defaultDurationMinutes: 30,
      environment: 'outdoor',
      contraindications: [],
    };

    const result = scoreActivitySuitability(activity, baseUser);
    expect(result.isContraindicated).toBe(false);
    expect(result.score).toBeGreaterThanOrEqual(90);
    expect(result.breakdown.primaryGoal).toBe(30);
  });

  it('HARD LOCK: Immediately blocks recommendations if critical cardiac symptom (E05) is present', () => {
    const userWithCardiac: UserAssessmentInput = {
      ...baseUser,
      criticalCardiacSymptom: true,
    };

    const activity = {
      category: 'cardio',
      primaryGoal: 'weight_management',
      difficultyLevel: 'beginner',
      equipmentRequired: ['none'],
      defaultDurationMinutes: 30,
      environment: 'outdoor',
      contraindications: [],
    };

    const result = scoreActivitySuitability(activity, userWithCardiac);
    expect(result.isContraindicated).toBe(true);
    expect(result.score).toBe(0);
  });

  it('HARD FILTER: Excludes activity if user has matching musculoskeletal injury', () => {
    const injuredUser: UserAssessmentInput = {
      ...baseUser,
      hasInjury: true,
      affectedBodyParts: ['knee_joint'],
    };

    const running = {
      category: 'cardio',
      primaryGoal: 'weight_management',
      difficultyLevel: 'intermediate',
      equipmentRequired: ['none'],
      defaultDurationMinutes: 30,
      environment: 'outdoor',
      contraindications: ['knee_joint'],
    };

    const result = scoreActivitySuitability(running, injuredUser);
    expect(result.isContraindicated).toBe(true);
    expect(result.score).toBe(0);
  });
});

describe('Weekly Plan Generator & Recovery Intervals', () => {
  it('allocates workouts and rest days without back-to-back heavy days for 3-day split', () => {
    const schedule = generateWeeklySchedule('Bodyweight Strength', 'Brisk Walking', 3, 30);
    expect(schedule).toHaveLength(7);

    const workoutDays = schedule.filter((s) => s.type === 'workout');
    expect(workoutDays).toHaveLength(3);
    // Mon, Wed, Fri
    expect(schedule[0].type).toBe('workout');
    expect(schedule[1].type).toBe('rest');
    expect(schedule[2].type).toBe('workout');
    expect(schedule[3].type).toBe('rest');
    expect(schedule[4].type).toBe('workout');
  });
});

describe('Geospatial Telemetry & Privacy Masking', () => {
  it('calculates Haversine distance between two coordinates accurately', () => {
    // Victoria Island to Lekki Phase 1, Lagos (~4.5km)
    const lat1 = 6.4281, lon1 = 3.4219;
    const lat2 = 6.4474, lon2 = 3.4723;
    const dist = haversineDistanceMeters(lat1, lon1, lat2, lon2);
    expect(dist).toBeGreaterThan(4000);
    expect(dist).toBeLessThan(7000);
  });

  it('masks and clips points within 250m privacy buffer of Home/Office', () => {
    const privacyZone = {
      centerLatitude: 6.4281,
      centerLongitude: 3.4219,
      radiusMeters: 250,
    };

    const points = [
      { lat: 6.42812, lng: 3.42191 }, // Inside Home (within ~15m) -> should be clipped
      { lat: 6.43500, lng: 3.43000 }, // Far outside (~1.2km) -> should be kept
    ];

    const filtered = maskPrivacyZones(points, [privacyZone]);
    expect(filtered).toHaveLength(1);
    expect(filtered[0].lat).toBe(6.43500);
  });
});

