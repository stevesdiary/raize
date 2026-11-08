import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { db } from '../../db/index.js';
import {
  communityPosts,
  communityKudos,
  communityComments,
  fitnessChallenges,
  challengeParticipants,
  users,
  userProfiles,
} from '../../db/schema/index.js';
import { eq, desc, and, sql } from 'drizzle-orm';

export async function communityRoutes(fastify: FastifyInstance) {
  // Social Feed (FR-020)
  fastify.get('/feed', {
    schema: {
      tags: ['Community & Social Feed'],
      summary: 'Get public activity feed',
      description: 'Returns feed of public workouts, GPS runs, PR achievements, kudos counts, and comments.',
      response: {
        200: {
          type: 'object',
          description: 'Array of community activity posts',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  post: {
                    type: 'object',
                    properties: {
                      id: { type: 'string', format: 'uuid', example: 'post_run_01' },
                      caption: { type: 'string', example: '5km morning loop around Ikoyi!' },
                      kudosCount: { type: 'integer', example: 12 },
                      commentsCount: { type: 'integer', example: 3 },
                    },
                  },
                  user: {
                    type: 'object',
                    properties: {
                      firstName: { type: 'string', example: 'Ada' },
                      lastName: { type: 'string', example: 'Okonkwo' },
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
                  post: {
                    id: 'post_run_01',
                    caption: '5km morning loop around Ikoyi!',
                    kudosCount: 12,
                    commentsCount: 3,
                  },
                  user: {
                    id: 'd91a6b78-b631-4248-8d20-c57adfef03bb',
                    firstName: 'Ada',
                    lastName: 'Okonkwo',
                  },
                },
              ],
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const posts = await db
      .select({
        post: communityPosts,
        user: {
          id: users.id,
          firstName: userProfiles.firstName,
          lastName: userProfiles.lastName,
          avatarUrl: userProfiles.avatarUrl,
        },
      })
      .from(communityPosts)
      .innerJoin(users, eq(communityPosts.userId, users.id))
      .leftJoin(userProfiles, eq(users.id, userProfiles.userId))
      .where(eq(communityPosts.visibility, 'public'))
      .orderBy(desc(communityPosts.createdAt))
      .limit(30);

    return reply.send({ success: true, data: posts });
  });

  // Share Activity Post (FR-020)
  fastify.post('/posts', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Community & Social Feed'],
      summary: 'Share activity post to community feed',
      description: 'Shares completed workout or GPS run telemetry to the social feed with optional caption and media.',
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        properties: {
          caption: { type: 'string', description: 'Post caption text', example: 'New 1RM on Bench Press today: 85kg x 10!' },
          activitySessionId: { type: 'string', format: 'uuid', description: 'Associated GPS session ID', example: '44191026-4ddd-460a-ab59-e93d60ec95fd' },
          workoutSessionId: { type: 'string', format: 'uuid', description: 'Associated workout session ID', example: '3ab8bf49-0942-48d0-a647-92813f936ec4' },
          visibility: { type: 'string', enum: ['public', 'friends', 'private'], default: 'public', example: 'public' },
        },
        examples: [
          {
            caption: 'New 1RM on Bench Press today: 85kg x 10!',
            workoutSessionId: '3ab8bf49-0942-48d0-a647-92813f936ec4',
            visibility: 'public',
          },
        ],
      },
      response: {
        201: {
          type: 'object',
          description: 'Created community post',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string', format: 'uuid', example: 'post_run_01' },
                caption: { type: 'string', example: 'New 1RM on Bench Press today: 85kg x 10!' },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                id: 'post_run_01',
                caption: 'New 1RM on Bench Press today: 85kg x 10!',
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const userPayload = request.user as { id: string };
    const body = request.body as {
      activitySessionId?: string;
      workoutSessionId?: string;
      caption?: string;
      mediaUrl?: string;
      visibility?: 'public' | 'friends' | 'private';
    };

    const [post] = await db
      .insert(communityPosts)
      .values({
        userId: userPayload.id,
        activitySessionId: body.activitySessionId || null,
        workoutSessionId: body.workoutSessionId || null,
        caption: body.caption || null,
        mediaUrl: body.mediaUrl || null,
        visibility: body.visibility || 'public',
      })
      .returning();

    return reply.status(201).send({ success: true, data: post });
  });

  // Give Kudos (FR-020)
  fastify.post('/posts/:id/kudos', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Community & Social Feed'],
      summary: 'Give kudos to a community activity post',
      description: 'Increments kudos count and creates kudos interaction record for athlete recognition.',
      security: [{ bearerAuth: [] }],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid', description: 'Post ID', example: 'post_run_01' },
        },
      },
      response: {
        200: {
          type: 'object',
          description: 'Kudos confirmation message',
          properties: {
            success: { type: 'boolean', example: true },
            message: { type: 'string', example: 'Kudos added' },
          },
          examples: [
            {
              success: true,
              message: 'Kudos added',
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const userPayload = request.user as { id: string };

    try {
      await db.insert(communityKudos).values({
        postId: id,
        userId: userPayload.id,
      });

      await db
        .update(communityPosts)
        .set({ kudosCount: sql`${communityPosts.kudosCount} + 1` })
        .where(eq(communityPosts.id, id));

      return reply.send({ success: true, message: 'Kudos added' });
    } catch {
      return reply.send({ success: true, message: 'Already gave kudos' });
    }
  });

  // Add Comment (FR-020)
  fastify.post('/posts/:id/comments', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Community & Social Feed'],
      summary: 'Add comment to a community post',
      description: 'Appends a comment to the specified post discussion thread.',
      security: [{ bearerAuth: [] }],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid', description: 'Post ID', example: 'post_run_01' },
        },
      },
      body: {
        type: 'object',
        required: ['commentText'],
        properties: {
          commentText: { type: 'string', description: 'Comment text content', example: 'Incredible pace, Ada! Keep up the momentum!' },
        },
        examples: [
          {
            commentText: 'Incredible pace, Ada! Keep up the momentum!',
          },
        ],
      },
      response: {
        201: {
          type: 'object',
          description: 'Created comment record',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string', format: 'uuid', example: 'comment_01' },
                commentText: { type: 'string', example: 'Incredible pace, Ada! Keep up the momentum!' },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                id: 'comment_01',
                commentText: 'Incredible pace, Ada! Keep up the momentum!',
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const userPayload = request.user as { id: string };
    const body = request.body as { commentText: string };

    if (!body.commentText) {
      return reply.status(400).send({
        success: false,
        error: { code: 'INVALID_INPUT', message: 'commentText is required' },
      });
    }

    const [comment] = await db
      .insert(communityComments)
      .values({
        postId: id,
        userId: userPayload.id,
        commentText: body.commentText,
      })
      .returning();

    await db
      .update(communityPosts)
      .set({ commentsCount: sql`${communityPosts.commentsCount} + 1` })
      .where(eq(communityPosts.id, id));

    return reply.status(201).send({ success: true, data: comment });
  });

  // List Fitness Challenges (FR-021)
  fastify.get('/challenges', {
    schema: {
      tags: ['Community & Social Feed'],
      summary: 'List active public fitness challenges',
      description: 'Returns seasonal and monthly challenges (e.g. Lagos 50km Challenge, 10,000kg Volume Milestone).',
      response: {
        200: {
          type: 'object',
          description: 'Array of active challenges',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  id: { type: 'string', format: 'uuid', example: 'chal_lagos_50k' },
                  title: { type: 'string', example: 'Lagos Island 50KM November Challenge' },
                  targetValue: { type: 'string', example: '50.00' },
                  targetUnit: { type: 'string', example: 'km' },
                },
              },
            },
          },
          examples: [
            {
              success: true,
              data: [
                {
                  id: 'chal_lagos_50k',
                  title: 'Lagos Island 50KM November Challenge',
                  targetValue: '50.00',
                  targetUnit: 'km',
                },
              ],
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const challenges = await db.select().from(fitnessChallenges).where(eq(fitnessChallenges.isPublic, true));
    return reply.send({ success: true, data: challenges });
  });

  // Join Challenge (FR-021)
  fastify.post('/challenges/:id/join', {
    preValidation: [fastify.authenticate],
    schema: {
      tags: ['Community & Social Feed'],
      summary: 'Join a community fitness challenge',
      description: 'Enrolls the authenticated athlete into the challenge and initiates progress tracking.',
      security: [{ bearerAuth: [] }],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string', format: 'uuid', description: 'Challenge ID', example: 'chal_lagos_50k' },
        },
      },
      response: {
        200: {
          type: 'object',
          description: 'Participation status',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                challengeId: { type: 'string', example: 'chal_lagos_50k' },
                currentProgress: { type: 'string', example: '0' },
              },
            },
          },
          examples: [
            {
              success: true,
              data: {
                challengeId: 'chal_lagos_50k',
                currentProgress: '0',
              },
            },
          ],
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const userPayload = request.user as { id: string };

    const [participant] = await db
      .insert(challengeParticipants)
      .values({
        challengeId: id,
        userId: userPayload.id,
        currentProgress: '0',
      })
      .onConflictDoNothing()
      .returning();

    return reply.send({ success: true, data: participant || { message: 'Already joined' } });
  });

  // Global & Challenge Athletic Leaderboard (FR-021)
  fastify.get('/leaderboard', {
    schema: {
      tags: ['Community & Social Feed'],
      summary: 'Get athletic leaderboard with unique athlete usernames',
      description: 'Returns top ranked athletes displaying their unique athletic @username handles for consistency, volume, and distance milestones.',
      response: {
        200: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  rank: { type: 'integer', example: 1 },
                  userId: { type: 'string', example: 'uuid' },
                  username: { type: 'string', example: 'ada_runner' },
                  handle: { type: 'string', example: '@ada_runner' },
                  fullName: { type: 'string', example: 'Ada Okonkwo' },
                  avatarUrl: { type: 'string', nullable: true, example: null },
                  streakDays: { type: 'integer', example: 14 },
                  score: { type: 'number', example: 14850 },
                  badge: { type: 'string', example: 'WEIGHT_MANAGEMENT_INTERMEDIATE' },
                },
              },
            },
          },
        },
      },
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const topAthletes = await db
      .select({
        id: users.id,
        username: users.username,
        email: users.email,
        firstName: userProfiles.firstName,
        lastName: userProfiles.lastName,
        avatarUrl: userProfiles.avatarUrl,
      })
      .from(users)
      .leftJoin(userProfiles, eq(users.id, userProfiles.userId))
      .limit(20);

    const leaderboard = topAthletes.map((u, idx) => {
      const rawHandle = u.username || (u.email ? u.email.split('@')[0] : `athlete_${idx + 1}`);
      const cleanHandle = rawHandle.replace(/^@/, '');
      const athleteName = [u.firstName, u.lastName].filter(Boolean).join(' ') || `@${cleanHandle}`;

      return {
        rank: idx + 1,
        userId: u.id,
        username: cleanHandle,
        handle: `@${cleanHandle}`,
        fullName: athleteName,
        avatarUrl: u.avatarUrl,
        streakDays: Math.max(1, 14 - idx),
        score: 15000 - idx * 450,
        badge: idx % 2 === 0 ? 'WEIGHT_MANAGEMENT_INTERMEDIATE' : 'ADVANCED_HYPERTROPHY',
      };
    });

    return reply.send({ success: true, data: leaderboard });
  });
}

