/**
 * Energy, Biometrics, and Recommendation Mathematical Utilities
 */

export interface UserAssessmentInput {
  age: number;
  biologicalSex?: 'male' | 'female' | 'prefer_not_to_say';
  heightCm?: number;
  weightKg?: number;
  primaryGoal: string;
  secondaryGoals?: string[];
  fitnessLevel: string; // 'beginner', 'intermediate', 'advanced'
  frequency: string; // 'never', '1_2_times', '3_4_times', '5_plus_times'
  typicalDay: string; // 'sitting', 'some_movement', 'frequently_standing', 'physically_demanding'
  weeklyDays: number; // 2, 3, 4, 5, 6
  sessionMinutes: number; // 15, 30, 45, 60, 75
  environment: string; // 'home', 'gym', 'outdoor', 'any'
  equipment: string[]; // ['none', 'dumbbells', 'full_gym']
  enjoyedActivities?: string[];
  avoidedActivities?: string[];
  hasInjury?: boolean;
  affectedBodyParts?: string[];
  criticalCardiacSymptom?: boolean; // Stage E E05
}

/**
 * Calculate age from date of birth string (YYYY-MM-DD)
 */
export function calculateAge(dobString: string): number {
  const dob = new Date(dobString);
  const now = new Date();
  let age = now.getFullYear() - dob.getFullYear();
  const m = now.getMonth() - dob.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < dob.getDate())) {
    age--;
  }
  return age;
}

/**
 * Mifflin-St Jeor Basal Metabolic Rate (BMR)
 */
export function calculateBMR(weightKg: number, heightCm: number, age: number, sex: string): number {
  const base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  if (sex === 'male') {
    return Math.round(base + 5);
  } else if (sex === 'female') {
    return Math.round(base - 161);
  }
  return Math.round(base - 78); // Neutral midpoint if undisclosed
}

/**
 * Total Daily Energy Expenditure (TDEE) based on Physical Activity Level
 */
export function calculateTDEE(bmr: number, baseline: string): number {
  let palMultiplier = 1.2; // Sedentary / sitting
  if (baseline === 'low_active' || baseline === 'some_movement') palMultiplier = 1.375;
  if (baseline === 'moderately_active' || baseline === 'frequently_standing') palMultiplier = 1.55;
  if (baseline === 'highly_active' || baseline === 'physically_demanding') palMultiplier = 1.725;

  return Math.round(bmr * palMultiplier);
}

/**
 * Goal Caloric Budget with strict safety floor and minor protection
 */
export function calculateTargetCalories(tdee: number, goal: string, age: number, sex: string): number {
  // Minor Safeguard: Minors must not be placed on automated caloric deficit
  if (age < 18) {
    return tdee;
  }

  let target = tdee;
  if (goal === 'weight_management' || goal === 'weight_loss') {
    target = tdee - 500; // Standard 500 kcal deficit
  } else if (goal === 'build_muscle' || goal === 'hypertrophy') {
    target = tdee + 300; // Hypertrophy surplus
  }

  // Safety floor
  const floor = sex === 'male' ? 1500 : 1200;
  return Math.max(target, floor);
}

/**
 * 7-Factor Weighted Activity Suitability Scorer S(a,u)
 * Safety is a HARD filter (S = 0 if contraindicated).
 */
export function scoreActivitySuitability(
  activity: {
    category: string;
    primaryGoal: string;
    difficultyLevel: string;
    equipmentRequired: string[];
    defaultDurationMinutes: number;
    environment: string;
    contraindications: string[];
  },
  user: UserAssessmentInput
): { score: number; breakdown: Record<string, number>; isContraindicated: boolean } {
  // Hard Safety Constraint Check
  if (user.criticalCardiacSymptom) {
    return { score: 0, breakdown: {}, isContraindicated: true };
  }

  if (user.hasInjury && user.affectedBodyParts && user.affectedBodyParts.length > 0) {
    const isContraindicated = activity.contraindications.some((c) =>
      user.affectedBodyParts?.includes(c)
    );
    if (isContraindicated) {
      return { score: 0, breakdown: {}, isContraindicated: true };
    }
  }

  // Dimension 1: Alignment with Primary Goal (30%)
  const rGoal = activity.primaryGoal === user.primaryGoal ? 1.0 : 0.5;

  // Dimension 2: User Preference (20%)
  let rPref = 0.7; // baseline
  const actName = activity.category.toLowerCase();
  if (user.avoidedActivities?.some((a) => a.toLowerCase().includes(actName))) {
    rPref = 0.1;
  } else if (user.enjoyedActivities?.some((a) => a.toLowerCase().includes(actName))) {
    rPref = 1.0;
  }

  // Dimension 3: Fitness Experience Suitability (15%)
  let rExp = 0.7;
  if (activity.difficultyLevel === user.fitnessLevel) {
    rExp = 1.0;
  } else if (user.fitnessLevel === 'beginner' && activity.difficultyLevel === 'advanced') {
    rExp = 0.2; // Steep penalty for beginners assigned advanced work
  } else {
    rExp = 0.8;
  }

  // Dimension 4: Available Equipment (10%)
  const hasEquip = activity.equipmentRequired.every(
    (e) => e === 'none' || user.equipment.includes(e) || user.equipment.includes('full_gym')
  );
  const rEquip = hasEquip ? 1.0 : 0.2;

  // Dimension 5: Available Time (10%)
  const rTime = activity.defaultDurationMinutes <= user.sessionMinutes ? 1.0 : 0.6;

  // Dimension 6: Activity Environment (10%)
  const rEnv =
    activity.environment === 'any' ||
    user.environment === 'any' ||
    user.environment === activity.environment
      ? 1.0
      : 0.4;

  // Dimension 7: Secondary Goal Alignment (5%)
  const rSec = user.secondaryGoals?.includes(activity.primaryGoal) ? 1.0 : 0.5;

  const score = Math.round(
    (rGoal * 0.3 +
      rPref * 0.2 +
      rExp * 0.15 +
      rEquip * 0.1 +
      rTime * 0.1 +
      rEnv * 0.1 +
      rSec * 0.05) *
      100
  );

  return {
    score,
    breakdown: {
      primaryGoal: rGoal * 30,
      userPreference: rPref * 20,
      experienceSuitability: rExp * 15,
      equipmentAvailability: rEquip * 10,
      timeFit: rTime * 10,
      environmentFit: rEnv * 10,
      secondaryGoal: rSec * 5,
    },
    isContraindicated: false,
  };
}

/**
 * 7-Day Weekly Schedule Generator
 * Allocates primary workouts, supporting cardio/mobility, and mandatory recovery days.
 */
export function generateWeeklySchedule(
  primaryActivity: string,
  supportingActivity: string,
  weeklyDays: number,
  sessionMinutes: number
): Array<{ day: string; type: string; activity: string; durationMinutes: number }> {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const schedule: Array<{ day: string; type: string; activity: string; durationMinutes: number }> = [];

  // Determine workout days distribution
  const workoutDayIndices: number[] = [];
  if (weeklyDays <= 2) {
    workoutDayIndices.push(1, 4); // Tue, Fri
  } else if (weeklyDays === 3) {
    workoutDayIndices.push(0, 2, 4); // Mon, Wed, Fri
  } else if (weeklyDays === 4) {
    workoutDayIndices.push(0, 1, 3, 5); // Mon, Tue, Thu, Sat
  } else {
    workoutDayIndices.push(0, 1, 2, 4, 5); // Mon, Tue, Wed, Fri, Sat
  }

  days.forEach((day, index) => {
    if (workoutDayIndices.includes(index)) {
      const isPrimary = index % 2 === 0;
      schedule.push({
        day,
        type: 'workout',
        activity: isPrimary ? primaryActivity : supportingActivity,
        durationMinutes: sessionMinutes,
      });
    } else {
      // Rest or light recovery day
      const isActiveRecovery = index === 6; // Sunday light walk/mobility
      schedule.push({
        day,
        type: isActiveRecovery ? 'recovery' : 'rest',
        activity: isActiveRecovery ? 'Active Recovery / Mobility Walk' : 'Rest Day',
        durationMinutes: isActiveRecovery ? 20 : 0,
      });
    }
  });

  return schedule;
}

/**
 * Haversine formula: Great-circle distance between two GPS coordinates in meters
 */
export function haversineDistanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371e3; // Earth radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

/**
 * Privacy Zone Masking: Clips GPS coordinates within privacy radius (e.g., 250m of Home/Office)
 */
export function maskPrivacyZones(
  points: Array<{ lat: number; lng: number }>,
  privacyZones: Array<{ centerLatitude: number; centerLongitude: number; radiusMeters: number }>
): Array<{ lat: number; lng: number }> {
  return points.filter((point) => {
    return !privacyZones.some((zone) => {
      const dist = haversineDistanceMeters(
        point.lat,
        point.lng,
        zone.centerLatitude,
        zone.centerLongitude
      );
      return dist <= zone.radiusMeters;
    });
  });
}

