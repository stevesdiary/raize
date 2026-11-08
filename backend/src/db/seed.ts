import { db, client } from './index.js';
import {
  fitnessPathways,
  assessmentQuestions,
  assessmentOptions,
  activityCatalog,
  exercises,
  foodCatalog,
  foodPortionUnits,
  workoutPrograms,
} from './schema/index.js';

async function seed() {
  console.log('Seeding initial platform data...');

  try {
    // 1. Fitness Pathways
    await db.insert(fitnessPathways).values([
      {
        id: 'weight_management',
        name: 'Weight Management',
        description: 'Sustainable energy balance, caloric control, and metabolic resistance training.',
        primaryFocus: 'Walking, steady-state cardio, moderate resistance training, habit formation.',
        nutritionFocus: 'Calorie management, balanced macronutrients, high fiber and protein.',
        progressionRules: { volumeIncreasePct: 5, reviewIntervalWeeks: 2 },
      },
      {
        id: 'muscle_development',
        name: 'Muscle Development',
        description: 'Hypertrophy-focused resistance training with progressive overload.',
        primaryFocus: 'Progressive resistance training, multi-joint compound and isolation lifts.',
        nutritionFocus: 'Hypertrophic caloric surplus or maintenance, 1.6-2.2g/kg protein intake.',
        progressionRules: { volumeIncreasePct: 8, reviewIntervalWeeks: 3 },
      },
      {
        id: 'strength_development',
        name: 'Strength Development',
        description: 'Maximal force production, neural adaptation, and structured periodization.',
        primaryFocus: 'Low-rep, high-load compound lifts (squat, bench, deadlift, overhead press).',
        nutritionFocus: 'Adequate energy availability, high protein, recovery-focused nutrition.',
        progressionRules: { volumeIncreasePct: 5, reviewIntervalWeeks: 4 },
      },
      {
        id: 'endurance_development',
        name: 'Endurance Development',
        description: 'Cardiovascular capacity, VO2 max optimization, and aerobic efficiency.',
        primaryFocus: 'Running, cycling, brisk walking, interval training, aerobic threshold work.',
        nutritionFocus: 'Training-supportive carbohydrate availability, hydration, and electrolytes.',
        progressionRules: { volumeIncreasePct: 10, reviewIntervalWeeks: 2 },
      },
      {
        id: 'mobility_functional',
        name: 'Mobility & Functional Fitness',
        description: 'Joint health, movement quality, balance, and injury prevention.',
        primaryFocus: 'Mobility drills, active stretching, balance, core stability, low-impact exercise.',
        nutritionFocus: 'Balanced healthy lifestyle nutrition, anti-inflammatory whole foods.',
        progressionRules: { volumeIncreasePct: 5, reviewIntervalWeeks: 4 },
      },
      {
        id: 'healthy_lifestyle',
        name: 'Healthy Lifestyle & Habit Formation',
        description: 'Accessible daily physical activity, sustainable habits, and overall wellbeing.',
        primaryFocus: 'Daily step goals, accessible home workouts, recreational activities.',
        nutritionFocus: 'Consistent mindful eating, balanced plates, habit consistency.',
        progressionRules: { volumeIncreasePct: 5, reviewIntervalWeeks: 4 },
      },
    ]).onConflictDoNothing();

    // 2. Assessment Questions (Stages A to F)
    const questions = [
      // Stage A: Personal Profile (DOB and Units pre-filled from registration account)
      { id: 'A01', stage: 'STAGE_A', section: 'Personal Profile', questionText: 'What is your date of birth?', inputType: 'date', displayOrder: 1, isRequired: false },
      { id: 'A02', stage: 'STAGE_A', section: 'Personal Profile', questionText: 'What is your biological sex?', inputType: 'single_choice', displayOrder: 2, isRequired: false },
      { id: 'A03', stage: 'STAGE_A', section: 'Personal Profile', questionText: 'What is your height & weight?', inputType: 'single_choice', displayOrder: 3, isRequired: false },
      { id: 'A04', stage: 'STAGE_A', section: 'Personal Profile', questionText: 'What is your current weight?', inputType: 'numeric', displayOrder: 4, isRequired: false, configuration: { unit: 'kg', imperialUnit: 'lbs' } },
      { id: 'A05', stage: 'STAGE_A', section: 'Personal Profile', questionText: 'What country do you live in?', inputType: 'single_choice', displayOrder: 5, isRequired: false },
      { id: 'A06', stage: 'STAGE_A', section: 'Personal Profile', questionText: 'What measurement system do you prefer?', inputType: 'single_choice', displayOrder: 6, isRequired: false },

      // Stage B: Fitness Goals
      { id: 'B01', stage: 'STAGE_B', section: 'Fitness Goals', questionText: 'What is your primary fitness goal?', inputType: 'single_choice', displayOrder: 7, isRequired: true },
      { id: 'B02', stage: 'STAGE_B', section: 'Fitness Goals', questionText: 'Do you have any secondary fitness goals?', inputType: 'multi_choice', displayOrder: 8, isRequired: false },
      { id: 'B03', stage: 'STAGE_B', section: 'Fitness Goals', questionText: 'What would success look like to you?', inputType: 'text', displayOrder: 9, isRequired: false },
      { id: 'B04', stage: 'STAGE_B', section: 'Fitness Goals', questionText: 'Do you have a target date?', inputType: 'single_choice', displayOrder: 10, isRequired: false },

      // Stage C: Current Fitness Condition
      { id: 'C01', stage: 'STAGE_C', section: 'Current Condition', questionText: 'How would you describe your current fitness level?', inputType: 'single_choice', displayOrder: 11, isRequired: true },
      { id: 'C02', stage: 'STAGE_C', section: 'Current Condition', questionText: 'How frequently do you exercise?', inputType: 'single_choice', displayOrder: 12, isRequired: true },
      { id: 'C03', stage: 'STAGE_C', section: 'Current Condition', questionText: 'How long have you exercised consistently?', inputType: 'single_choice', displayOrder: 13, isRequired: true },
      { id: 'C04', stage: 'STAGE_C', section: 'Current Condition', questionText: 'What activities do you currently engage in?', inputType: 'multi_choice', displayOrder: 14, isRequired: false },
      { id: 'C05', stage: 'STAGE_C', section: 'Current Condition', questionText: 'How active is your typical day?', inputType: 'single_choice', displayOrder: 15, isRequired: true },
      { id: 'C06', stage: 'STAGE_C', section: 'Current Condition', questionText: 'How confident are you about exercising independently?', inputType: 'single_choice', displayOrder: 16, isRequired: true },

      // Stage D: Lifestyle and Training Preferences
      { id: 'D01', stage: 'STAGE_D', section: 'Preferences', questionText: 'How many days can you exercise weekly?', inputType: 'single_choice', displayOrder: 17, isRequired: true },
      { id: 'D02', stage: 'STAGE_D', section: 'Preferences', questionText: 'How much time can you dedicate per session?', inputType: 'single_choice', displayOrder: 18, isRequired: true },
      { id: 'D03', stage: 'STAGE_D', section: 'Preferences', questionText: 'Where do you prefer exercising?', inputType: 'single_choice', displayOrder: 19, isRequired: true },
      { id: 'D04', stage: 'STAGE_D', section: 'Preferences', questionText: 'What equipment can you access?', inputType: 'multi_choice', displayOrder: 20, isRequired: true },
      { id: 'D05', stage: 'STAGE_D', section: 'Preferences', questionText: 'Which activities do you enjoy?', inputType: 'multi_choice', displayOrder: 21, isRequired: false },
      { id: 'D06', stage: 'STAGE_D', section: 'Preferences', questionText: 'Which activities would you rather avoid?', inputType: 'multi_choice', displayOrder: 22, isRequired: false },
      { id: 'D07', stage: 'STAGE_D', section: 'Preferences', questionText: 'Do you prefer exercising alone or with others?', inputType: 'single_choice', displayOrder: 23, isRequired: false },
      { id: 'D08', stage: 'STAGE_D', section: 'Preferences', questionText: 'When do you prefer exercising?', inputType: 'single_choice', displayOrder: 24, isRequired: false },

      // Stage E: Health and Safety Screening
      { id: 'E01', stage: 'STAGE_E', section: 'Health & Safety', questionText: 'Do you have an injury or physical limitation that affects movement?', inputType: 'single_choice', displayOrder: 25, isRequired: true },
      { id: 'E02', stage: 'STAGE_E', section: 'Health & Safety', questionText: 'Do you have a medical condition that could affect exercise?', inputType: 'single_choice', displayOrder: 26, isRequired: true },
      { id: 'E03', stage: 'STAGE_E', section: 'Health & Safety', questionText: 'Have you been advised by a healthcare professional to restrict physical activity?', inputType: 'single_choice', displayOrder: 27, isRequired: true },
      { id: 'E04', stage: 'STAGE_E', section: 'Health & Safety', questionText: 'Are you currently recovering from an illness, injury or surgery?', inputType: 'single_choice', displayOrder: 28, isRequired: true },
      { id: 'E05', stage: 'STAGE_E', section: 'Health & Safety', questionText: 'Do you experience symptoms during exercise that concern you, such as chest pain, fainting or unusual breathlessness?', inputType: 'single_choice', displayOrder: 29, isRequired: true, description: 'Safety-critical screening question.' },
      { id: 'E06', stage: 'STAGE_E', section: 'Health & Safety', questionText: 'Is there anything else you want us to consider when recommending activities?', inputType: 'text', displayOrder: 30, isRequired: false },

      // Stage F: Motivation and Commitment
      { id: 'F01', stage: 'STAGE_F', section: 'Motivation', questionText: 'What motivates you to exercise?', inputType: 'multi_choice', displayOrder: 31, isRequired: true },
      { id: 'F02', stage: 'STAGE_F', section: 'Motivation', questionText: 'What usually prevents you from exercising?', inputType: 'multi_choice', displayOrder: 32, isRequired: true },
      { id: 'F03', stage: 'STAGE_F', section: 'Motivation', questionText: 'How much guidance do you prefer?', inputType: 'single_choice', displayOrder: 33, isRequired: true },
      { id: 'F04', stage: 'STAGE_F', section: 'Motivation', questionText: 'Would you like reminders?', inputType: 'single_choice', displayOrder: 34, isRequired: true },
      { id: 'F05', stage: 'STAGE_F', section: 'Motivation', questionText: 'How would you describe your commitment?', inputType: 'single_choice', displayOrder: 35, isRequired: true },
    ];

    await db.insert(assessmentQuestions).values(questions).onConflictDoNothing();

    // 3. Assessment Options (Selected Key Options)
    const options = [
      // Stage A Options
      { questionId: 'A02', value: 'male', displayText: 'Male', displayOrder: 1, metadata: { sex: 'male' } },
      { questionId: 'A02', value: 'female', displayText: 'Female', displayOrder: 2, metadata: { sex: 'female' } },
      { questionId: 'A02', value: 'prefer_not_to_say', displayText: 'Prefer not to say', displayOrder: 3, metadata: { sex: 'unspecified' } },

      { questionId: 'A03', value: 'standard_metric', displayText: 'Standard Adult Metric (175 cm, 72 kg)', displayOrder: 1, metadata: { height: 175, weight: 72 } },
      { questionId: 'A03', value: 'custom', displayText: 'Custom Biometrics', displayOrder: 2, metadata: { custom: true } },

      { questionId: 'A05', value: 'NG', displayText: 'Nigeria', displayOrder: 1, metadata: { country: 'Nigeria' } },
      { questionId: 'A05', value: 'OTHER', displayText: 'International', displayOrder: 2, metadata: { country: 'Other' } },

      { questionId: 'A06', value: 'metric', displayText: 'Metric (kg, cm, km)', displayOrder: 1, metadata: { unit: 'metric' } },
      { questionId: 'A06', value: 'imperial', displayText: 'Imperial (lbs, ft, mi)', displayOrder: 2, metadata: { unit: 'imperial' } },

      // B01 Primary Goal
      { questionId: 'B01', value: 'weight_management', displayText: 'Weight Management', displayOrder: 1, metadata: { pathway: 'weight_management' } },
      { questionId: 'B01', value: 'build_muscle', displayText: 'Build Muscle', displayOrder: 2, metadata: { pathway: 'muscle_development' } },
      { questionId: 'B01', value: 'build_strength', displayText: 'Build Strength', displayOrder: 3, metadata: { pathway: 'strength_development' } },
      { questionId: 'B01', value: 'improve_endurance', displayText: 'Improve Endurance', displayOrder: 4, metadata: { pathway: 'endurance_development' } },
      { questionId: 'B01', value: 'improve_flexibility', displayText: 'Improve Mobility & Movement', displayOrder: 5, metadata: { pathway: 'mobility_functional' } },
      { questionId: 'B01', value: 'healthy_lifestyle', displayText: 'Maintain a Healthy Lifestyle', displayOrder: 6, metadata: { pathway: 'healthy_lifestyle' } },

      // C01 Fitness Level
      { questionId: 'C01', value: 'beginner', displayText: 'Beginner', displayOrder: 1, metadata: { level: 'beginner' } },
      { questionId: 'C01', value: 'intermediate', displayText: 'Intermediate', displayOrder: 2, metadata: { level: 'intermediate' } },
      { questionId: 'C01', value: 'advanced', displayText: 'Advanced', displayOrder: 3, metadata: { level: 'advanced' } },
      { questionId: 'C01', value: 'not_sure', displayText: 'Not Sure', displayOrder: 4, metadata: { level: 'beginner' } },

      // C02 Frequency
      { questionId: 'C02', value: 'never', displayText: 'Never', displayOrder: 1, metadata: { days: 0 } },
      { questionId: 'C02', value: '1_2_times', displayText: '1–2 times/week', displayOrder: 2, metadata: { days: 2 } },
      { questionId: 'C02', value: '3_4_times', displayText: '3–4 times/week', displayOrder: 3, metadata: { days: 4 } },
      { questionId: 'C02', value: '5_plus_times', displayText: '5+ times/week', displayOrder: 4, metadata: { days: 6 } },

      // D01 Days
      { questionId: 'D01', value: '1_2', displayText: '1–2 days', displayOrder: 1, metadata: { targetDays: 2 } },
      { questionId: 'D01', value: '3', displayText: '3 days', displayOrder: 2, metadata: { targetDays: 3 } },
      { questionId: 'D01', value: '4_5', displayText: '4–5 days', displayOrder: 3, metadata: { targetDays: 4 } },
      { questionId: 'D01', value: '6_7', displayText: '6–7 days', displayOrder: 4, metadata: { targetDays: 6 } },

      // D02 Session Time
      { questionId: 'D02', value: '10_15', displayText: '10–15 minutes', displayOrder: 1, metadata: { minutes: 15 } },
      { questionId: 'D02', value: '15_30', displayText: '15–30 minutes', displayOrder: 2, metadata: { minutes: 30 } },
      { questionId: 'D02', value: '30_45', displayText: '30–45 minutes', displayOrder: 3, metadata: { minutes: 45 } },
      { questionId: 'D02', value: '45_60', displayText: '45–60 minutes', displayOrder: 4, metadata: { minutes: 60 } },
      { questionId: 'D02', value: '60_plus', displayText: '60+ minutes', displayOrder: 5, metadata: { minutes: 75 } },

      // D03 Environment
      { questionId: 'D03', value: 'home', displayText: 'Home', displayOrder: 1, metadata: { env: 'home' } },
      { questionId: 'D03', value: 'gym', displayText: 'Gym', displayOrder: 2, metadata: { env: 'gym' } },
      { questionId: 'D03', value: 'outdoors', displayText: 'Outdoors', displayOrder: 3, metadata: { env: 'outdoor' } },
      { questionId: 'D03', value: 'combination', displayText: 'Combination', displayOrder: 4, metadata: { env: 'any' } },

      // E05 Safety Critical Chest Pain
      { questionId: 'E05', value: 'yes', displayText: 'Yes', displayOrder: 1, metadata: { risk: 'CRITICAL_STOP' } },
      { questionId: 'E05', value: 'no', displayText: 'No', displayOrder: 2, metadata: { risk: 'CLEARED' } },
      { questionId: 'E05', value: 'prefer_not_to_say', displayText: 'Prefer not to say', displayOrder: 3, metadata: { risk: 'CRITICAL_STOP' } },
    ];

    await db.insert(assessmentOptions).values(options).onConflictDoNothing();

    // 4. Activity Catalog
    await db.insert(activityCatalog).values([
      {
        name: 'Brisk Walking',
        code: 'walking',
        category: 'cardio',
        primaryGoal: 'weight_management',
        metScore: '3.8',
        defaultDurationMinutes: 30,
        equipmentRequired: ['none'],
        environment: 'outdoor',
        difficultyLevel: 'beginner',
        description: 'Low-impact cardiovascular conditioning suitable for all fitness levels.',
      },
      {
        name: 'Bodyweight Resistance Circuit',
        code: 'bodyweight_strength',
        category: 'strength',
        primaryGoal: 'build_muscle',
        metScore: '4.5',
        defaultDurationMinutes: 30,
        equipmentRequired: ['none'],
        environment: 'home',
        difficultyLevel: 'beginner',
        description: 'Progressive calisthenics focusing on movement control and foundation strength.',
      },
      {
        name: 'Structured Barbell/Dumbbell Strength',
        code: 'heavy_strength',
        category: 'strength',
        primaryGoal: 'build_strength',
        metScore: '6.0',
        defaultDurationMinutes: 45,
        equipmentRequired: ['barbell', 'dumbbells'],
        environment: 'gym',
        difficultyLevel: 'intermediate',
        description: 'Multi-joint resistance training targeting progressive compound load overload.',
      },
      {
        name: 'Outdoor Running Intervals',
        code: 'running_intervals',
        category: 'cardio',
        primaryGoal: 'improve_endurance',
        metScore: '8.0',
        defaultDurationMinutes: 30,
        equipmentRequired: ['none'],
        environment: 'outdoor',
        difficultyLevel: 'intermediate',
        contraindications: ['acute_knee_injury', 'cardiac_uncontrolled'],
        description: 'Aerobic and anaerobic threshold intervals to boost cardiovascular capacity.',
      },
      {
        name: 'Active Mobility & Stretch',
        code: 'mobility_stretch',
        category: 'recovery',
        primaryGoal: 'improve_flexibility',
        metScore: '2.5',
        defaultDurationMinutes: 20,
        equipmentRequired: ['none'],
        environment: 'home',
        difficultyLevel: 'beginner',
        description: 'Joint decompressions, dynamic range of motion, and tissue recovery.',
      },
    ]).onConflictDoNothing();

    // 5. Exercises Library
    await db.insert(exercises).values([
      {
        name: 'Standard Push-Up',
        category: 'chest',
        primaryMuscle: 'Pectoralis Major',
        secondaryMuscles: ['Triceps Brachii', 'Anterior Deltoid', 'Core'],
        equipment: 'bodyweight',
        instructions: 'Maintain a rigid plank line from heels to head. Lower chest to floor and press back up explosively.',
        videoUrl: 'https://media.raize.fit/exercises/pushup.mp4',
      },
      {
        name: 'Bodyweight Air Squat',
        category: 'legs',
        primaryMuscle: 'Quadriceps',
        secondaryMuscles: ['Gluteus Maximus', 'Hamstrings', 'Calves'],
        equipment: 'bodyweight',
        instructions: 'Stand with feet shoulder-width apart. Sit hips back and down until thighs are parallel to ground.',
        videoUrl: 'https://media.raize.fit/exercises/air-squat.mp4',
      },
      {
        name: 'Dumbbell Goblet Squat',
        category: 'legs',
        primaryMuscle: 'Quadriceps',
        secondaryMuscles: ['Gluteus Maximus', 'Core'],
        equipment: 'dumbbells',
        instructions: 'Hold a dumbbell vertically against chest. Squat with chest upright and knees tracking over toes.',
        videoUrl: 'https://media.raize.fit/exercises/goblet-squat.mp4',
      },
      {
        name: 'Dumbbell Romanian Deadlift',
        category: 'legs',
        primaryMuscle: 'Hamstrings',
        secondaryMuscles: ['Gluteus Maximus', 'Erector Spinae'],
        equipment: 'dumbbells',
        instructions: 'Hinge forward at the hips with slight knee bend and flat back. Lower dumbbells along shins until hamstring stretch.',
        videoUrl: 'https://media.raize.fit/exercises/rdl.mp4',
      },
      {
        name: 'Forearm Plank',
        category: 'core',
        primaryMuscle: 'Rectus Abdominis',
        secondaryMuscles: ['Transverse Abdominis', 'Glutes'],
        equipment: 'bodyweight',
        instructions: 'Rest on elbows directly below shoulders. Squeeze glutes and brace core, preventing lower back sag.',
        videoUrl: 'https://media.raize.fit/exercises/plank.mp4',
      },
    ]).onConflictDoNothing();

    // 6. Food Catalog (Nigerian Staples + Global Baseline)
    const foods = [
      {
        name: 'Jollof Rice (Party Style)',
        brand: 'Authentic Nigerian',
        servingSizeGrams: '250.00',
        servingUnit: 'serving',
        calories: '340.00',
        proteinGrams: '6.50',
        carbsGrams: '58.00',
        fatGrams: '9.50',
        fiberGrams: '2.50',
        isVerifiedNigerian: true,
      },
      {
        name: 'Pounded Yam',
        brand: 'Traditional Staple',
        servingSizeGrams: '200.00',
        servingUnit: 'wrap',
        calories: '280.00',
        proteinGrams: '3.00',
        carbsGrams: '64.00',
        fatGrams: '0.80',
        fiberGrams: '4.00',
        isVerifiedNigerian: true,
      },
      {
        name: 'Egusi Soup (with spinach and fish)',
        brand: 'Traditional Nigerian',
        servingSizeGrams: '180.00',
        servingUnit: 'portion',
        calories: '310.00',
        proteinGrams: '18.00',
        carbsGrams: '8.00',
        fatGrams: '23.00',
        fiberGrams: '3.00',
        isVerifiedNigerian: true,
      },
      {
        name: 'Beef Suya (Grilled Skewered Beef)',
        brand: 'Street Kitchen',
        servingSizeGrams: '150.00',
        servingUnit: 'portion',
        calories: '260.00',
        proteinGrams: '32.00',
        carbsGrams: '4.00',
        fatGrams: '12.00',
        fiberGrams: '1.00',
        isVerifiedNigerian: true,
      },
      {
        name: 'Boiled Ripe Plantain',
        brand: 'Whole Food',
        servingSizeGrams: '150.00',
        servingUnit: 'medium plantain',
        calories: '180.00',
        proteinGrams: '1.50',
        carbsGrams: '45.00',
        fatGrams: '0.30',
        fiberGrams: '3.20',
        isVerifiedNigerian: true,
      },
      {
        name: 'Grilled Skinless Chicken Breast',
        brand: 'Standard Nutrition',
        servingSizeGrams: '100.00',
        servingUnit: 'g',
        calories: '165.00',
        proteinGrams: '31.00',
        carbsGrams: '0.00',
        fatGrams: '3.60',
        fiberGrams: '0.00',
        isVerifiedNigerian: false,
      },
    ];

    for (const food of foods) {
      const [inserted] = await db.insert(foodCatalog).values(food).onConflictDoNothing().returning();
      if (inserted && inserted.isVerifiedNigerian) {
        // Add portion units for Nigerian food
        await db.insert(foodPortionUnits).values([
          { foodId: inserted.id, unitName: 'plate', gramWeightRatio: '300.00', isLocalMeasure: true },
          { foodId: inserted.id, unitName: 'wrap', gramWeightRatio: '200.00', isLocalMeasure: true },
          { foodId: inserted.id, unitName: 'cup', gramWeightRatio: '150.00', isLocalMeasure: true },
        ]).onConflictDoNothing();
      }
    }

    console.log('Seed completed successfully!');
  } catch (err) {
    console.error('Seed failed:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

seed();

