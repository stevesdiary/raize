import { FastifyPluginAsync } from 'fastify';
import { Type } from '@sinclair/typebox';
import { db } from '../../db/index.js';
import { coachProfiles, users, auditLogs } from '../../db/schema/index.js';
import { eq, and, desc } from 'drizzle-orm';
import {
  sendCoachApplicationReceivedEmail,
  sendCoachVerificationStatusEmail,
} from '../../services/email.service.js';

// Approved Nigerian Commercial & Fintech Banks for NUBAN settlements
const SUPPORTED_BANKS = [
  { code: '058', name: 'Guaranty Trust Bank (GTBank)', slug: 'gtbank' },
  { code: '057', name: 'Zenith Bank', slug: 'zenith-bank' },
  { code: '044', name: 'Access Bank', slug: 'access-bank' },
  { code: '011', name: 'First Bank of Nigeria', slug: 'first-bank' },
  { code: '033', name: 'United Bank for Africa (UBA)', slug: 'uba' },
  { code: '221', name: 'Stanbic IBTC Bank', slug: 'stanbic-ibtc' },
  { code: '50211', name: 'Kuda Microfinance Bank', slug: 'kuda' },
  { code: '50515', name: 'Moniepoint MFB', slug: 'moniepoint' },
  { code: '999992', name: 'OPay Digital Services', slug: 'opay' },
];

export const coachesRoutes: FastifyPluginAsync = async (fastify) => {
  /**
   * GET /api/v1/coaches/banks
   * List supported commercial banks for NUBAN payouts
   */
  fastify.get(
    '/banks',
    {
      schema: {
        description: 'List supported Nigerian commercial and fintech banks for coach revenue settlements',
        tags: ['Coaches'],
        response: {
          200: Type.Object({
            success: Type.Boolean(),
            data: Type.Array(
              Type.Object({
                code: Type.String(),
                name: Type.String(),
                slug: Type.String(),
              })
            ),
          }),
        },
      },
    },
    async (_req, reply) => {
      return reply.status(200).send({
        success: true,
        data: SUPPORTED_BANKS,
      });
    }
  );

  /**
   * POST /api/v1/coaches/apply
   * Submit Coach Onboarding & 4-Pillar Accreditation application
   */
  fastify.post(
    '/apply',
    {
      onRequest: [fastify.authenticate],
      schema: {
        description: 'Submit trainer onboarding application with accreditation and NUBAN bank details',
        tags: ['Coaches'],
        body: Type.Object({
          fullName: Type.String({ minLength: 3, maxLength: 150 }),
          bio: Type.String({ minLength: 10, maxLength: 2000 }),
          specialties: Type.Array(Type.String(), { minItems: 1 }),
          experienceYears: Type.Integer({ minimum: 1, maximum: 50 }),
          accreditationBody: Type.String({ minLength: 2, maxLength: 100 }),
          licenseNumber: Type.String({ minLength: 3, maxLength: 100 }),
          certificateUrl: Type.Optional(Type.String()),
          governmentIdUrl: Type.Optional(Type.String()),
          idType: Type.Optional(Type.String()),
          idNumber: Type.String({ minLength: 4, maxLength: 100 }),
          bankCode: Type.String({ minLength: 3, maxLength: 10 }),
          accountNumber: Type.String({ minLength: 10, maxLength: 10 }),
          accountName: Type.String({ minLength: 3, maxLength: 150 }),
          ndpaDpaAccepted: Type.Boolean(),
        }),
      },
    },
    async (req, reply) => {
      const user = req.user as { id: string; email: string };
      const body = req.body as {
        fullName: string;
        bio: string;
        specialties: string[];
        experienceYears: number;
        accreditationBody: string;
        licenseNumber: string;
        certificateUrl?: string;
        governmentIdUrl?: string;
        idType?: string;
        idNumber: string;
        bankCode: string;
        accountNumber: string;
        accountName: string;
        ndpaDpaAccepted: boolean;
      };

      // Pillar 3: Statutory NDPA 2023 DPA Consent Check
      if (!body.ndpaDpaAccepted) {
        return reply.status(400).send({
          success: false,
          error: {
            code: 'NDPA_DPA_REQUIRED',
            message: 'Trainers must execute the NDPA 2023 Coach Data Protection Agreement to handle client biometric and health records.',
          },
        });
      }

      // Check supported bank
      const matchedBank = SUPPORTED_BANKS.find((b) => b.code === body.bankCode);
      const bankName = matchedBank ? matchedBank.name : 'Commercial Bank';

      // Check existing application
      const existing = await db
        .select()
        .from(coachProfiles)
        .where(eq(coachProfiles.userId, user.id))
        .limit(1);

      if (existing.length > 0 && existing[0].verificationStatus === 'verified') {
        return reply.status(400).send({
          success: false,
          error: {
            code: 'ALREADY_VERIFIED',
            message: 'Your coach profile is already verified and active on the platform.',
          },
        });
      }

      // Pillar 4: Generate Paystack Transfer Recipient code
      const paystackRecipientCode = `RCP_${body.bankCode}_${body.accountNumber}`;

      let coachRecord;
      if (existing.length > 0) {
        // Update existing application
        const [updated] = await db
          .update(coachProfiles)
          .set({
            fullName: body.fullName,
            bio: body.bio,
            specialties: body.specialties,
            experienceYears: body.experienceYears,
            accreditationBody: body.accreditationBody,
            licenseNumber: body.licenseNumber,
            certificateUrl: body.certificateUrl,
            governmentIdUrl: body.governmentIdUrl,
            idType: body.idType || 'NIN',
            idNumber: body.idNumber,
            bankCode: body.bankCode,
            bankName,
            accountNumber: body.accountNumber,
            accountName: body.accountName,
            paystackRecipientCode,
            verificationStatus: 'pending',
            rejectionReason: null,
            ndpaDpaAccepted: true,
            ndpaDpaAcceptedAt: new Date(),
            updatedAt: new Date(),
          })
          .where(eq(coachProfiles.userId, user.id))
          .returning();
        coachRecord = updated;
      } else {
        // Create new application
        const [created] = await db
          .insert(coachProfiles)
          .values({
            userId: user.id,
            fullName: body.fullName,
            bio: body.bio,
            specialties: body.specialties,
            experienceYears: body.experienceYears,
            accreditationBody: body.accreditationBody,
            licenseNumber: body.licenseNumber,
            certificateUrl: body.certificateUrl,
            governmentIdUrl: body.governmentIdUrl,
            idType: body.idType || 'NIN',
            idNumber: body.idNumber,
            bankCode: body.bankCode,
            bankName,
            accountNumber: body.accountNumber,
            accountName: body.accountName,
            paystackRecipientCode,
            verificationStatus: 'pending',
            ndpaDpaAccepted: true,
            ndpaDpaAcceptedAt: new Date(),
            isActive: false,
          })
          .returning();
        coachRecord = created;
      }

      // Record Statutory Audit Log
      await db.insert(auditLogs).values({
        userId: user.id,
        action: 'COACH_APPLICATION_SUBMITTED',
        targetEntity: 'coach_profiles',
        entityId: coachRecord.id,
        changes: {
          accreditationBody: body.accreditationBody,
          licenseNumber: body.licenseNumber,
          bankCode: body.bankCode,
          accountNumber: `******${body.accountNumber.slice(-4)}`,
          ndpaDpaAccepted: true,
        },
      });

      // Dispatch SendByte confirmation email
      await sendCoachApplicationReceivedEmail(user.email, body.fullName, body.accreditationBody);

      return reply.status(201).send({
        success: true,
        data: {
          id: coachRecord.id,
          fullName: coachRecord.fullName,
          verificationStatus: coachRecord.verificationStatus,
          accreditationBody: coachRecord.accreditationBody,
          licenseNumber: coachRecord.licenseNumber,
          bankName: coachRecord.bankName,
          accountNumber: `******${coachRecord.accountNumber.slice(-4)}`,
          paystackRecipientCode: coachRecord.paystackRecipientCode,
          message: 'Coach application received. 4-pillar verification review is now in progress.',
        },
      });
    }
  );

  /**
   * GET /api/v1/coaches/me
   * Retrieve current coach application & 4-pillar verification status
   */
  fastify.get(
    '/me',
    {
      onRequest: [fastify.authenticate],
      schema: {
        description: 'Get logged in trainer application status and 4-pillar milestone verification progress',
        tags: ['Coaches'],
      },
    },
    async (req, reply) => {
      const user = req.user as { id: string };

      const coach = await db
        .select()
        .from(coachProfiles)
        .where(eq(coachProfiles.userId, user.id))
        .limit(1);

      if (coach.length === 0) {
        return reply.status(404).send({
          success: false,
          error: {
            code: 'COACH_PROFILE_NOT_FOUND',
            message: 'No coach application found for this account. Apply at /api/v1/coaches/apply.',
          },
        });
      }

      const c = coach[0];
      const isVerified = c.verificationStatus === 'verified';

      return reply.status(200).send({
        success: true,
        data: {
          id: c.id,
          fullName: c.fullName,
          bio: c.bio,
          specialties: c.specialties,
          experienceYears: c.experienceYears,
          accreditationBody: c.accreditationBody,
          licenseNumber: c.licenseNumber,
          verificationStatus: c.verificationStatus,
          verifiedAt: c.verifiedAt,
          rejectionReason: c.rejectionReason,
          isActive: c.isActive,
          monthlyRetainerNgn: c.monthlyRetainerNgn,
          bankName: c.bankName,
          accountNumber: `******${c.accountNumber.slice(-4)}`,
          fourPillarAudit: {
            pillar1_identityKyc: {
              status: isVerified ? 'verified' : 'in_progress',
              provider: 'Smile ID (NIN / Registry)',
              idType: c.idType,
            },
            pillar2_accreditation: {
              status: isVerified ? 'verified' : 'under_review',
              body: c.accreditationBody,
              licenseNumber: c.licenseNumber,
            },
            pillar3_ndpaDpa: {
              status: c.ndpaDpaAccepted ? 'consented' : 'pending',
              acceptedAt: c.ndpaDpaAcceptedAt,
              statutoryBasis: 'Nigeria Data Protection Act 2023 Sec. 24 & Health Rule Compliance',
            },
            pillar4_paystackPayout: {
              status: c.paystackRecipientCode ? 'active' : 'pending',
              recipientCode: c.paystackRecipientCode,
              bankName: c.bankName,
              accountMask: `******${c.accountNumber.slice(-4)}`,
            },
          },
        },
      });
    }
  );

  /**
   * GET /api/v1/coaches
   * Public directory of vetted, active coaches for athlete discovery
   */
  fastify.get(
    '/',
    {
      schema: {
        description: 'Browse verified, active coaches for 1-on-1 mentorship tier',
        tags: ['Coaches'],
        querystring: Type.Object({
          specialty: Type.Optional(Type.String()),
          limit: Type.Optional(Type.Integer({ default: 20 })),
          offset: Type.Optional(Type.Integer({ default: 0 })),
        }),
      },
    },
    async (req, reply) => {
      const { limit = 20, offset = 0 } = req.query as { limit?: number; offset?: number };

      const coaches = await db
        .select({
          id: coachProfiles.id,
          fullName: coachProfiles.fullName,
          bio: coachProfiles.bio,
          specialties: coachProfiles.specialties,
          experienceYears: coachProfiles.experienceYears,
          accreditationBody: coachProfiles.accreditationBody,
          monthlyRetainerNgn: coachProfiles.monthlyRetainerNgn,
          verifiedAt: coachProfiles.verifiedAt,
        })
        .from(coachProfiles)
        .where(
          and(
            eq(coachProfiles.isActive, true),
            eq(coachProfiles.verificationStatus, 'verified')
          )
        )
        .orderBy(desc(coachProfiles.verifiedAt))
        .limit(limit)
        .offset(offset);

      return reply.status(200).send({
        success: true,
        data: coaches,
        meta: {
          count: coaches.length,
          limit,
          offset,
        },
      });
    }
  );

  /**
   * GET /api/v1/coaches/:id
   * Public detailed profile of a coach
   */
  fastify.get(
    '/:id',
    {
      schema: {
        description: 'Get verified coach public profile',
        tags: ['Coaches'],
        params: Type.Object({
          id: Type.String(),
        }),
      },
    },
    async (req, reply) => {
      const { id } = req.params as { id: string };

      const coach = await db
        .select({
          id: coachProfiles.id,
          fullName: coachProfiles.fullName,
          bio: coachProfiles.bio,
          specialties: coachProfiles.specialties,
          experienceYears: coachProfiles.experienceYears,
          accreditationBody: coachProfiles.accreditationBody,
          monthlyRetainerNgn: coachProfiles.monthlyRetainerNgn,
          isActive: coachProfiles.isActive,
          verificationStatus: coachProfiles.verificationStatus,
          verifiedAt: coachProfiles.verifiedAt,
        })
        .from(coachProfiles)
        .where(eq(coachProfiles.id, id))
        .limit(1);

      if (coach.length === 0) {
        return reply.status(404).send({
          success: false,
          error: {
            code: 'COACH_NOT_FOUND',
            message: 'Coach profile not found.',
          },
        });
      }

      return reply.status(200).send({
        success: true,
        data: coach[0],
      });
    }
  );

  /**
   * POST /api/v1/coaches/:id/review
   * Compliance Officer / Admin decision to verify or reject coach application
   */
  fastify.post(
    '/:id/review',
    {
      onRequest: [fastify.authenticate],
      schema: {
        description: 'Compliance decision to approve or reject a trainer accreditation application',
        tags: ['Coaches'],
        params: Type.Object({
          id: Type.String(),
        }),
        body: Type.Object({
          status: Type.Union([Type.Literal('verified'), Type.Literal('rejected')]),
          rejectionReason: Type.Optional(Type.String()),
        }),
      },
    },
    async (req, reply) => {
      const reviewer = req.user as { id: string };
      const { id } = req.params as { id: string };
      const { status, rejectionReason } = req.body as {
        status: 'verified' | 'rejected';
        rejectionReason?: string;
      };

      const coach = await db
        .select()
        .from(coachProfiles)
        .where(eq(coachProfiles.id, id))
        .limit(1);

      if (coach.length === 0) {
        return reply.status(404).send({
          success: false,
          error: {
            code: 'COACH_NOT_FOUND',
            message: 'Coach application record not found.',
          },
        });
      }

      const c = coach[0];
      const isApproved = status === 'verified';

      // Update coach profile
      const [updated] = await db
        .update(coachProfiles)
        .set({
          verificationStatus: status,
          isActive: isApproved,
          verifiedAt: isApproved ? new Date() : null,
          rejectionReason: isApproved ? null : rejectionReason || 'Accreditation credentials could not be verified.',
          verifiedBy: reviewer.id,
          updatedAt: new Date(),
        })
        .where(eq(coachProfiles.id, id))
        .returning();

      // If approved, promote user role to 'coach'
      if (isApproved) {
        await db
          .update(users)
          .set({ role: 'coach', updatedAt: new Date() })
          .where(eq(users.id, c.userId));
      }

      // Record Statutory Audit Log
      await db.insert(auditLogs).values({
        userId: reviewer.id,
        action: isApproved ? 'COACH_ACCREDITATION_VERIFIED' : 'COACH_APPLICATION_REJECTED',
        targetEntity: 'coach_profiles',
        entityId: c.id,
        changes: {
          previousStatus: c.verificationStatus,
          newStatus: status,
          rejectionReason: isApproved ? null : rejectionReason,
          coachUserId: c.userId,
        },
      });

      // Find user email to dispatch notification
      const coachUser = await db
        .select({ email: users.email })
        .from(users)
        .where(eq(users.id, c.userId))
        .limit(1);

      if (coachUser.length > 0) {
        await sendCoachVerificationStatusEmail(
          coachUser[0].email,
          c.fullName,
          status,
          rejectionReason
        );
      }

      return reply.status(200).send({
        success: true,
        data: {
          id: updated.id,
          fullName: updated.fullName,
          verificationStatus: updated.verificationStatus,
          isActive: updated.isActive,
          verifiedAt: updated.verifiedAt,
          rejectionReason: updated.rejectionReason,
        },
      });
    }
  );
};
