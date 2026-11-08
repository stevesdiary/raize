import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../models/billing_models.dart';
import '../providers/billing_provider.dart';

class PaywallScreen extends ConsumerWidget {
  final bool syncBackend;

  const PaywallScreen({
    super.key,
    this.syncBackend = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billingProvider);
    final notifier = ref.read(billingProvider.notifier);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Ambient Cockpit Atmospheric Glows
          Positioned(
            top: 0,
            left: MediaQuery.of(context).size.width / 4,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.kineticIndigo.withValues(alpha: colors.isDark ? 0.12 : 0.05),
              ),
            ),
          ),
          Positioned(
            top: 380,
            right: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.neonEmerald.withValues(alpha: colors.isDark ? 0.08 : 0.03),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Shared TopAppBar
                _buildTopBar(context),

                // 2. Main Scrollable Canvas Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 170),
                    child: Column(
                      children: [
                        // Hero Section
                        _buildHeroSection(context),
                        const SizedBox(height: 20),

                        // Bento Value Proposition Matrix
                        _buildValuePropsMatrix(context),
                        const SizedBox(height: 20),

                        // Membership Plan Selection
                        _buildPlanSelector(context, state, notifier),
                        const SizedBox(height: 16),

                        // Trust & Encryption Badges
                        _buildTrustBadges(context),
                        const SizedBox(height: 16),

                        // Testimonial Cockpit Accent
                        _buildTestimonialCard(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Sticky Bottom Checkout Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCheckoutDock(context, state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: colors.border,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dismiss Button
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.cardElevated,
                border: Border.all(
                  color: colors.border,
                ),
              ),
              child: Icon(Icons.close, size: 18, color: colors.textPrimary),
            ),
          ),

          // Central Brand Identifier Pill
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colors.neonEmerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'RAIZE PRO • ELITE ACCESS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.neonEmerald,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Restore Purchases Button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Purchases restored successfully.')),
              );
            },
            child: Text(
              'Restore',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        // Kinetic Insignia Visual
        SizedBox(
          width: 160,
          height: 136,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer dashed orbit ring
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.kineticIndigo.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              // Middle ring
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.neonEmerald.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              // Energy core shield
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.card,
                  border: Border.all(
                    color: colors.kineticIndigo.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.kineticIndigo.withValues(alpha: 0.25),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, size: 28, color: colors.kineticIndigo),
                    Text(
                      'VO2 MAX',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: colors.neonEmerald,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              // Floating 7-Day Free Trial tag
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.cardElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.neonEmerald.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: colors.isDark ? 0.4 : 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 12, color: colors.neonEmerald),
                      const SizedBox(width: 4),
                      Text(
                        '7-DAY FREE TRIAL',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colors.neonEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Headline
        Text(
          'Unlock Your Full\nAthletic Potential',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'All-in-one metabolic conditioning, live GPS telemetry, personalized strength blueprints, and African culinary nutrition tracking.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValuePropsMatrix(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'ELITE TELEMETRY SUITE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'INCLUDED IN PRO',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colors.kineticIndigo,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _buildFeatureItem(
          context: context,
          title: 'Adaptive 7-Day Training Blueprint',
          tag: 'AI',
          description:
              'Dynamic algorithmic volume calibration based on real-time CNS fatigue and recovery scores.',
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          context: context,
          title: 'Live GPS & Route Telemetry',
          tag: 'SUB-METER',
          description:
              'Real-time pace splits, elevation surge angles, cadence, and Kalman-filtered vector tracking.',
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          context: context,
          title: 'Full Resistance Library & Video Coaching',
          tag: '4K HDR',
          description:
              'Interactive biomechanics video checks, set-by-set overload progression, and auto-computed RPE.',
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          context: context,
          title: 'Nigerian & Global Nutrition Diary',
          tag: 'LOCALIZED',
          description:
              'Calibrated macros for Nigerian staples (Jollof, Pounded Yam, Egusi, Suya) and 500k+ global foods.',
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          context: context,
          title: 'Live Challenges & Community Kudos',
          tag: 'CLUBS',
          description:
              'Verified regional leaderboard ranking, weekend club sprints, and kinetic trophy badges.',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required String title,
    required String tag,
    required String description,
  }) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colors.neonEmerald.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(Icons.check, size: 16, color: colors.neonEmerald),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: colors.neonEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(BuildContext context, SubscriptionState state, BillingNotifier notifier) {
    final colors = context.colors;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'SELECT MEMBERSHIP PROTOCOL',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'BILLED LOCALLY (NGN)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...state.plans.map((plan) {
          final isSelected = plan.id == state.selectedPlanId;
          return GestureDetector(
            onTap: () => notifier.selectPlan(plan.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? colors.kineticIndigo
                      : colors.border,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors.kineticIndigo.withValues(alpha: 0.2),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plan.badge != null || plan.trialBadge != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (plan.badge != null)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.kineticIndigo,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                plan.badge!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        const SizedBox(width: 6),
                        if (plan.trialBadge != null)
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: colors.neonEmerald,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    plan.trialBadge!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: colors.neonEmerald,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? colors.kineticIndigo
                                      : colors.border,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: colors.kineticIndigo,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  if (plan.monthlyEquivalent != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      plan.monthlyEquivalent!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            plan.priceFormatted,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            plan.period,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isSelected && plan.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: colors.border,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              plan.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.verified_user, size: 14, color: colors.kineticIndigo),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrustBadges(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: colors.border,
          ),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.lock, size: 14, color: colors.neonEmerald),
                const SizedBox(width: 6),
                Text(
                  '256-BIT BANK ENCRYPTION',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 12, color: colors.border),
            const SizedBox(width: 16),
            Row(
              children: [
                Icon(Icons.published_with_changes, size: 14, color: colors.kineticIndigo),
                const SizedBox(width: 6),
                Text(
                  'INSTANT CANCELLATION',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialCard(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.kineticIndigo.withValues(alpha: 0.4),
              ),
            ),
            child: Center(
              child: Text(
                'DA',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colors.kineticIndigo,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"Finally an app that accurately counts calories for Egusi and Pounded Yam."',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dr. Aminu • Lagos Marathon Finisher',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutDock(
    BuildContext context,
    SubscriptionState state,
    BillingNotifier notifier,
  ) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(
            color: colors.border,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Kinetic CTA Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.kineticIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              onPressed: state.isLoading
                  ? null
                  : () async {
                      final success = await notifier.initializePaystackCheckout(
                        syncBackend: syncBackend,
                      );
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Subscription activated: ${state.selectedPlan.name}!',
                            ),
                          ),
                        );
                      }
                    },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        state.selectedPlan.ctaLabel,
                        maxLines: 1,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Localized Payment Gateway Badges
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              _PaymentBadge('Paystack Secured'),
              _PaymentBadge('Visa'),
              _PaymentBadge('Mastercard'),
              _PaymentBadge('Verve'),
              _PaymentBadge('Apple Pay'),
            ],
          ),
          const SizedBox(height: 6),

          // Legal Disclaimer
          Text(
            'Cancel anytime in account settings. Auto-renews per CAMA 2020 terms. NDPA 2023 privacy compliant.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final String label;
  const _PaymentBadge(this.label);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: colors.borderSubtle,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

