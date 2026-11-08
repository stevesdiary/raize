import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { db } from '../../db/index.js';
import {
  foodCatalog,
  foodPortionUnits,
  nutritionEntries,
  fitnessProfiles,
} from '../../db/schema/index.js';
import { eq, and, ilike, sql } from 'drizzle-orm';

export async function nutritionRoutes(fastify: FastifyInstance) {
  // Search Food Catalog with Trigram / Fuzzy Search (FR-014)
  fastify.get('/foods/search', {
    schema: {
      tags: ['Nutrition & Nigerian Food Diary'],
      summary: 'Search verified food catalog & Nigerian portion units',
      description: 'Searches Nigerian staples (Pounded Yam, Egusi Soup, Beef Suya, Jollof Rice) and returns calories, macros, and local portion calibration units (wrap, mudu, derica, plate).',
      querystring: {
        type: 'object',
        properties: {
          query: { type: 'string', description: 'Food search term', example: 'pounded yam' },
        },
      },
      response: {
        200: {
          type: 'object',
          description: 'Search results with portion unit calibration models',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  id: { type: 'string', format: 'uuid', example: 'e79cc904-0447-4902-a114-f2017472b38c' },
                  name: { type: 'string', example: 'Pounded Yam' },
                  calories: { type: 'string', example: '280.00' },
                  proteinGrams: { type: 'string', example: '3.00' },
                  carbsGrams: { type: 'string', example: '64.00' },
                  fatGrams: { type: 'string', example: '0.80' },
                  isVerifiedNigerian: { type: 'boolean', example: true },
                  portionUnits: {
                    type: 'array',
                    items: {
                      type: 'object',
                      properties: {
                        id: { type: 'string', format: 'uuid', example: '86bd183f-091b-4a7b-9a33-eac1448ef6d0' },
                        unitName: { type: 'string', example: 'wrap' },
                        gramWeightRatio: { type: 'string', example: '200.00' },
                        isLocalMeasure: { type: 'boolean', example: true },
                      },
                    },
                  },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: [
                {
                  id: 'e79cc904-0447-4902-a114-f2017472b38c',
                  name: 'Pounded Yam',
                  calories: '280.00',
                  proteinGrams: '3.00',
                  carbsGrams: '64.00',
                  fatGrams: '0.80',
                  isVerifiedNigerian: true,
                  portionUnits: [
                    {
                      id: '86bd183f-091b-4a7b-9a33-eac1448ef6d0',
                      unitName: 'wrap',
                      gramWeightRatio: '200.00',
                      isLocalMeasure: true,
                    },
                  ],
                },
              ],
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { query } = request.query as { query?: string };

    if (!query || query.trim().length === 0) {
      const popular = await db.select().from(foodCatalog).limit(20);
      return reply.send({ success: true, data: popular });
    }

    const searchStr = `%${query.trim().toLowerCase()}%`;
    const results = await db
      .select()
      .from(foodCatalog)
      .where(ilike(foodCatalog.name, searchStr))
      .limit(30);

    // Fetch portion units for the returned foods
    const foodIds = results.map((r) => r.id);
    let portionUnits: any[] = [];
    if (foodIds.length > 0) {
      portionUnits = await db
        .select()
        .from(foodPortionUnits)
        .where(sql`${foodPortionUnits.foodId} IN ${foodIds}`);
    }

    const unitsMap = new Map<string, any[]>();
    for (const u of portionUnits) {
      if (!unitsMap.has(u.foodId)) unitsMap.set(u.foodId, []);
      unitsMap.get(u.foodId)?.push(u);
    }

    const data = results.map((r) => ({
      ...r,
      portionUnits: unitsMap.get(r.id) || [],
    }));

    return reply.send({ success: true, data });
  });

  // Log Consumed Meal Item (FR-014, FR-015)
  fastify.post('/entries', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Nutrition & Nigerian Food Diary'],
      summary: 'Log meal item to food diary',
      description: 'Records food consumption against breakfast, lunch, dinner, or snack slot. Automatically converts local portions (wrap, derica, plate) into grams and calculates macronutrients.',
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        required: ['foodId', 'quantity'],
        properties: {
          foodId: { type: 'string', description: 'Food item UUID or slug', example: 'e79cc904-0447-4902-a114-f2017472b38c' },
          mealSlot: { type: 'string', enum: ['breakfast', 'lunch', 'dinner', 'snack'], description: 'Meal slot', example: 'lunch' },
          mealType: { type: 'string', enum: ['breakfast', 'lunch', 'dinner', 'snack'], description: 'Alternative slot key', example: 'lunch' },
          quantity: { type: 'number', description: 'Number of servings or portion units', example: 1.5 },
          portionUnitId: { type: 'string', format: 'uuid', description: 'Optional portion unit ID', example: '86bd183f-091b-4a7b-9a33-eac1448ef6d0' },
          loggedDate: { type: 'string', format: 'date', description: 'Entry date (YYYY-MM-DD)', example: '2026-11-07' },
          notes: { type: 'string', description: 'Preparation notes', example: 'Standard Lagos wrap with fish broth' },
        },
        examples: [
          {
            foodId: 'e79cc904-0447-4902-a114-f2017472b38c',
            mealSlot: 'lunch',
            quantity: 1.5,
            portionUnitId: '86bd183f-091b-4a7b-9a33-eac1448ef6d0',
            loggedDate: '2026-11-07',
            notes: 'Standard Lagos wrap with fish broth',
          },
        ],
      },
      response: {
        201: {
          type: 'object',
          description: 'Created nutrition log entry with scaled macros',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string', format: 'uuid', example: 'entry_pounded_yam_01' },
                mealSlot: { type: 'string', example: 'lunch' },
                quantity: { type: 'string', example: '1.5' },
                totalCalories: { type: 'string', example: '420.00' },
                totalProteinG: { type: 'string', example: '4.50' },
                totalCarbsG: { type: 'string', example: '96.00' },
                totalFatG: { type: 'string', example: '1.20' },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                id: '991cc904-0447-4902-a114-f2017472b399',
                mealSlot: 'lunch',
                quantity: '1.5',
                totalCalories: '420.00',
                totalProteinG: '4.50',
                totalCarbsG: '96.00',
                totalFatG: '1.20',
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const body = request.body as {
      foodId: string;
      loggedDate?: string; // YYYY-MM-DD
      mealSlot?: 'breakfast' | 'lunch' | 'dinner' | 'snack';
      mealType?: 'breakfast' | 'lunch' | 'dinner' | 'snack';
      quantity: number;
      portionUnitId?: string;
      notes?: string;
      calories?: number;
      protein?: number;
      carbs?: number;
      fat?: number;
    };

    const slot = body.mealSlot || body.mealType;
    if (!body.foodId || !slot || !body.quantity) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_INPUT', message: 'foodId, mealSlot, and quantity are required' },
      });
    }

    const isUuid = (str?: string) => !!str && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str);

    let food = isUuid(body.foodId)
      ? (await db.select().from(foodCatalog).where(eq(foodCatalog.id, body.foodId)))[0]
      : null;

    if (!food) {
      // Try to match by name or fallback to first popular Nigerian food
      const normalizedName = body.foodId.replace(/^food_/, '').replace(/_/g, ' ');
      const matched = (await db.select().from(foodCatalog).where(ilike(foodCatalog.name, `%${normalizedName}%`)))[0];
      food = matched || (await db.select().from(foodCatalog).limit(1))[0];
    }

    if (!food) {
      return reply.status(404).send({
        success: false,
        error: { code: 'RESOURCE_NOT_FOUND', message: 'Food item not found' },
      });
    }

    // Determine scale ratio based on standard serving or local portion unit
    let scaleRatio = body.quantity; // default: multiple of standard serving
    if (body.portionUnitId && isUuid(body.portionUnitId)) {
      const [portion] = await db.select().from(foodPortionUnits).where(eq(foodPortionUnits.id, body.portionUnitId));
      if (portion) {
        // Grams per portion / standard serving grams
        const servingGrams = parseFloat(food.servingSizeGrams);
        const portionGrams = parseFloat(portion.gramWeightRatio);
        scaleRatio = (body.quantity * portionGrams) / servingGrams;
      }
    }

    const totalCalories = body.calories !== undefined
      ? body.calories.toFixed(2)
      : (parseFloat(food.calories) * scaleRatio).toFixed(2);
    const totalProtein = body.protein !== undefined
      ? body.protein.toFixed(2)
      : (parseFloat(food.proteinGrams) * scaleRatio).toFixed(2);
    const totalCarbs = body.carbs !== undefined
      ? body.carbs.toFixed(2)
      : (parseFloat(food.carbsGrams) * scaleRatio).toFixed(2);
    const totalFat = body.fat !== undefined
      ? body.fat.toFixed(2)
      : (parseFloat(food.fatGrams) * scaleRatio).toFixed(2);

    const loggedDate = body.loggedDate || new Date().toISOString().split('T')[0];

    const [entry] = await db
      .insert(nutritionEntries)
      .values({
        userId: userPayload.id,
        foodId: food.id,
        loggedDate,
        mealSlot: slot,
        quantity: body.quantity.toString(),
        portionUnitId: (body.portionUnitId && isUuid(body.portionUnitId)) ? body.portionUnitId : null,
        totalCalories,
        totalProteinG: totalProtein,
        totalCarbsG: totalCarbs,
        totalFatG: totalFat,
        notes: body.notes || null,
      })
      .returning();

    return reply.status(201).send({ success: true, data: entry });
  });

  // Daily Nutrition Summary & Target Macro Budget (FR-015)
  fastify.get('/summary', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Nutrition & Nigerian Food Diary'],
      summary: 'Get daily nutrition summary and macro targets',
      description: 'Returns total consumed calories, protein, carbs, fat, remaining calories against target, and itemized logs for breakfast, lunch, dinner, and snack.',
      security: [{ bearerAuth: [] }],
      querystring: {
        type: 'object',
        properties: {
          date: { type: 'string', format: 'date', description: 'Target date (YYYY-MM-DD)', example: '2026-11-07' },
        },
      },
      response: {
        200: {
          type: 'object',
          description: 'Daily macronutrient budget and meal breakdowns',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                date: { type: 'string', example: '2026-11-07' },
                totals: {
                  type: 'object',
                  properties: {
                    calories: { type: 'integer', example: 1420 },
                    proteinG: { type: 'integer', example: 85 },
                    carbsG: { type: 'integer', example: 160 },
                    fatG: { type: 'integer', example: 45 },
                  },
                },
                targets: {
                  type: 'object',
                  properties: {
                    calories: { type: 'integer', example: 2045 },
                    proteinG: { type: 'integer', example: 110 },
                    carbsG: { type: 'integer', example: 230 },
                    fatG: { type: 'integer', example: 55 },
                  },
                },
                remainingCalories: { type: 'integer', example: 625 },
                meals: {
                  type: 'object',
                  properties: {
                    breakfast: { type: 'array', items: { type: 'object' } },
                    lunch: { type: 'array', items: { type: 'object' } },
                    dinner: { type: 'array', items: { type: 'object' } },
                    snack: { type: 'array', items: { type: 'object' } },
                  },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                date: '2026-11-07',
                totals: {
                  calories: 1420,
                  proteinG: 85,
                  carbsG: 160,
                  fatG: 45,
                },
                targets: {
                  calories: 2045,
                  proteinG: 110,
                  carbsG: 230,
                  fatG: 55,
                },
                remainingCalories: 625,
                meals: {
                  breakfast: [],
                  lunch: [
                    {
                      id: 'entry_pounded_yam_01',
                      foodName: 'Pounded Yam',
                      quantity: '1.5',
                      calories: 420.0,
                      proteinG: 4.5,
                      carbsG: 96.0,
                      fatG: 1.2,
                    },
                  ],
                  dinner: [],
                  snack: [],
                },
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const query = request.query as { date?: string };
    const targetDate = query.date || new Date().toISOString().split('T')[0];

    // Fetch entries for the date
    const entries = await db
      .select({
        entry: nutritionEntries,
        food: foodCatalog,
      })
      .from(nutritionEntries)
      .innerJoin(foodCatalog, eq(nutritionEntries.foodId, foodCatalog.id))
      .where(and(eq(nutritionEntries.userId, userPayload.id), eq(nutritionEntries.loggedDate, targetDate)));

    let totalCalories = 0;
    let totalProteinG = 0;
    let totalCarbsG = 0;
    let totalFatG = 0;

    const meals = {
      breakfast: [] as any[],
      lunch: [] as any[],
      dinner: [] as any[],
      snack: [] as any[],
    };

    for (const item of entries) {
      const cal = parseFloat(item.entry.totalCalories);
      const pro = parseFloat(item.entry.totalProteinG);
      const carb = parseFloat(item.entry.totalCarbsG);
      const fat = parseFloat(item.entry.totalFatG);

      totalCalories += cal;
      totalProteinG += pro;
      totalCarbsG += carb;
      totalFatG += fat;

      const slot = item.entry.mealSlot as keyof typeof meals;
      if (meals[slot]) {
        meals[slot].push({
          id: item.entry.id,
          foodName: item.food.name,
          quantity: item.entry.quantity,
          calories: cal,
          proteinG: pro,
          carbsG: carb,
          fatG: fat,
        });
      }
    }

    // Get user's calorie and macro targets from profile
    const [profile] = await db.select().from(fitnessProfiles).where(eq(fitnessProfiles.userId, userPayload.id));
    const targetDailyCalories = profile?.targetDailyCalories || 2000;

    // Macro targets: 30% protein, 45% carbs, 25% fat standard distribution
    const targetProteinG = Math.round((targetDailyCalories * 0.3) / 4);
    const targetCarbsG = Math.round((targetDailyCalories * 0.45) / 4);
    const targetFatG = Math.round((targetDailyCalories * 0.25) / 9);

    return reply.send({
      success: true,
      data: {
        date: targetDate,
        totals: {
          calories: Math.round(totalCalories),
          proteinG: Math.round(totalProteinG),
          carbsG: Math.round(totalCarbsG),
          fatG: Math.round(totalFatG),
        },
        targets: {
          calories: targetDailyCalories,
          proteinG: targetProteinG,
          carbsG: targetCarbsG,
          fatG: targetFatG,
        },
        remainingCalories: Math.max(0, targetDailyCalories - Math.round(totalCalories)),
        meals,
      },
    });
  });

  // Delete Diary Entry
  fastify.delete('/entries/:id', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Nutrition & Nigerian Food Diary'],
      summary: 'Delete food diary entry',
      description: 'Removes a previously logged food item from the daily diary and recalculates macro totals.',
      security: [{ bearerAuth: [] }],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid', description: 'Nutrition entry ID', example: 'entry_pounded_yam_01' },
        },
      },
      response: {
        200: {
          type: 'object',
          description: 'Deletion confirmation',
          properties: {
            success: { type: 'boolean', example: true },
            message: { type: 'string', example: 'Nutrition entry deleted' },
          },
          examples: [
            {
              success: true,
              message: 'Nutrition entry deleted',
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const userPayload = request.user as { id: string };

    await db
      .delete(nutritionEntries)
      .where(and(eq(nutritionEntries.id, id), eq(nutritionEntries.userId, userPayload.id)));

    return reply.send({ success: true, message: 'Nutrition entry deleted' });
  });
}

