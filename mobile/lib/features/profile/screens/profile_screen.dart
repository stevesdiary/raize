import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/onboarding_screen.dart';
import '../../billing/screens/paywall_screen.dart';
import 'account_settings_screen.dart';

/// Athlete Profile Hub screen allowing users to view telemetry statistics,
/// manage membership tiers, customize themes, and access Account Settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final handle = user?.displayHandle ?? '@athlete';
    final userEmail = user?.email ?? 'athlete@raize.fit';
    final athleteName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Raize Athlete';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Athlete Profile',
          style: GoogleFonts.spaceGrotesk(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ThemeToggleButton(size: 36),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Athlete Hero Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withAlpha(colors.isDark ? 20 : 10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.kineticIndigo],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        athleteName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                athleteName,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.verified_rounded, size: 16, color: colors.neonEmerald),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          handle,
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. High-Performance Telemetry Strip
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    colors,
                    '14 DAYS',
                    'STREAK',
                    Icons.local_fire_department_rounded,
                    colors.neonEmerald,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    colors,
                    '38.5 T',
                    'VOLUME',
                    Icons.fitness_center_rounded,
                    colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    colors,
                    '48 SESS',
                    'WORKOUTS',
                    Icons.timer_outlined,
                    colors.kineticIndigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Settings Navigation Menu
            Text(
              'ACCOUNT & MEMBERSHIP',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Account Settings Tile (Cancel subscription, delete account)
                  ListTile(
                    key: const Key('profile_account_settings_tile'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.manage_accounts_rounded, color: colors.primary, size: 20),
                    ),
                    title: Text(
                      'Account Settings',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Subscription cancellation, NDPA privacy, delete account',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AccountSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 60, color: colors.borderSubtle),

                  // Membership & Billing Tile
                  ListTile(
                    key: const Key('profile_membership_tile'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.amber.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.workspace_premium_rounded, color: colors.amber, size: 20),
                    ),
                    title: Text(
                      'Membership & Paywall',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Upgrade to Annual Athletic Pass or 1-on-1 Coach Tier',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PaywallScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Preferences & Appearance
            Text(
              'APPEARANCE & THEME',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: const ThemeModeSegmentedSelector(),
            ),
            const SizedBox(height: 28),

            // 5. Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('profile_sign_out_button'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: Icon(Icons.logout_rounded, color: colors.textPrimary, size: 18),
                label: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    dynamic colors,
    String value,
    String label,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
