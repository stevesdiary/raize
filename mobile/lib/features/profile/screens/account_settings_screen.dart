import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/credential_cache_service.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/onboarding_screen.dart';
import '../../billing/providers/billing_provider.dart';

/// Screen providing comprehensive account management, subscription cancellation,
/// NDPA 2023 Section 24 privacy data control, and permanent account deletion.
class AccountSettingsScreen extends ConsumerStatefulWidget {
  final bool syncBackend;

  const AccountSettingsScreen({
    super.key,
    this.syncBackend = false,
  });

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  bool _isCancelling = false;
  bool _isDeleting = false;
  String? _statusBannerMessage;
  bool _isSuccessBanner = true;

  Future<void> _handleCancelSubscription() async {
    final colors = context.colors;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('cancel_subscription_dialog'),
        backgroundColor: colors.cardElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.border),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(
              'Cancel Subscription?',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your membership auto-renewal?',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '• Your access will remain active until the end of your current billing period.\n'
              '• You will retain full workout history and personal telemetry.\n'
              '• Automatic AI progressive overload calibrations and 4K biomechanical 3D animations will pause after expiration.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('keep_subscription_button'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Keep Membership',
              style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            key: const Key('confirm_cancel_subscription_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.destructive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Cancellation', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isCancelling = true);
      final success = await ref
          .read(billingProvider.notifier)
          .cancelSubscription(syncBackend: widget.syncBackend);

      if (mounted) {
        setState(() {
          _isCancelling = false;
          if (success) {
            _statusBannerMessage =
                'Subscription auto-renewal has been cancelled. Your access remains active until the end of the billing period.';
            _isSuccessBanner = true;
          } else {
            _statusBannerMessage = 'Failed to cancel subscription. Please check your network.';
            _isSuccessBanner = false;
          }
        });
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final colors = context.colors;
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          key: const Key('delete_account_dialog'),
          backgroundColor: colors.cardElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.destructive.withAlpha(80)),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: colors.destructive, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    color: colors.destructive,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.destructive.withAlpha(colors.isDark ? 25 : 15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.destructive.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: colors.destructive, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'IRREVERSIBLE ACTION • NDPA SEC. 24',
                        style: TextStyle(
                          color: colors.destructive,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will permanently erase your profile, workout logs, GPS telemetry, and biometric data in compliance with the Nigeria Data Protection Act 2023.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Type DELETE to confirm permanent erasure:',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('delete_account_confirm_input'),
                controller: confirmController,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  hintStyle: TextStyle(color: colors.textMuted),
                  filled: true,
                  fillColor: colors.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.destructive, width: 1.5),
                  ),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const Key('cancel_delete_account_button'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Keep Account',
                style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              key: const Key('confirm_delete_account_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.destructive,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: confirmController.text.trim().toUpperCase() == 'DELETE'
                  ? () => Navigator.of(ctx).pop(true)
                  : null,
              child: const Text(
                'Permanently Delete',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);

      // 1. Clear saved credentials from cache
      await CredentialCacheService.clearCredentials();

      // 2. Perform account deletion in Auth Provider (cascading erasure)
      await ref.read(authProvider.notifier).deleteAccount(syncBackend: widget.syncBackend);

      if (mounted) {
        // 3. Return to Onboarding Screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authState = ref.watch(authProvider);
    final billingState = ref.watch(billingProvider);
    final user = authState.user;

    final athleteHandle = user?.displayHandle ?? '@athlete';
    final athleteEmail = user?.email ?? 'athlete@raize.fit';
    final athleteName = user?.fullName.isNotEmpty == true ? user!.fullName : 'Raize Athlete';

    final isSubscribed = billingState.isSubscribed;
    final planName = billingState.selectedPlan.name;
    final planPrice = billingState.selectedPlan.priceFormatted;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          key: const Key('account_settings_back_button'),
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Account Settings',
          style: GoogleFonts.spaceGrotesk(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.neonEmerald.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.neonEmerald.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 12, color: colors.neonEmerald),
                const SizedBox(width: 4),
                Text(
                  'NDPA 2023 SEC. 24',
                  style: TextStyle(
                    color: colors.neonEmerald,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Notification Banner
            if (_statusBannerMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isSuccessBanner ? colors.neonEmerald : colors.destructive).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_isSuccessBanner ? colors.neonEmerald : colors.destructive).withAlpha(80),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccessBanner ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      color: _isSuccessBanner ? colors.neonEmerald : colors.destructive,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusBannerMessage!,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 16, color: colors.textMuted),
                      onPressed: () => setState(() => _statusBannerMessage = null),
                    ),
                  ],
                ),
              ),
            ],

            // 1. Athlete Identity Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
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
                          fontSize: 22,
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
                        Text(
                          athleteName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          athleteHandle,
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          athleteEmail,
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
            const SizedBox(height: 20),

            // 2. Subscription & Membership Management Card
            Text(
              'MEMBERSHIP & SUBSCRIPTION',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isSubscribed ? planName : 'Active 7-Day Free Trial',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isSubscribed ? colors.neonEmerald : colors.amber).withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (isSubscribed ? colors.neonEmerald : colors.amber).withAlpha(70),
                          ),
                        ),
                        child: Text(
                          isSubscribed ? 'ACTIVE' : 'TRIAL',
                          style: TextStyle(
                            color: isSubscribed ? colors.neonEmerald : colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSubscribed
                        ? 'Billed through Paystack Africa ($planPrice). Auto-renews next cycle.'
                        : 'Your 7-day complimentary pass auto-renews at $planPrice unless cancelled.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Cancel Subscription Action Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('cancel_subscription_button'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colors.destructive.withAlpha(80)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isCancelling ? null : _handleCancelSubscription,
                      icon: _isCancelling
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.destructive,
                              ),
                            )
                          : Icon(Icons.cancel_outlined, color: colors.destructive, size: 18),
                      label: Text(
                        'Cancel Subscription',
                        style: TextStyle(
                          color: colors.destructive,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. App Appearance & Preferences
            Text(
              'APP PREFERENCES & THEME',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance Theme',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const ThemeModeSegmentedSelector(),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 4. Danger Zone (NDPA 2023 Section 24 & Account Erasure)
            Text(
              'DANGER ZONE',
              style: TextStyle(
                color: colors.destructive,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.destructive.withAlpha(colors.isDark ? 15 : 10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.destructive.withAlpha(70)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: colors.destructive, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Permanent Account Erasure',
                        style: TextStyle(
                          color: colors.destructive,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permanently delete your Raize athlete account, personal fitness profile, biometric telemetry, workout volume logs, and nutrition records. Under NDPA 2023 Section 24 (Right to Erasure), this action cannot be undone.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('delete_account_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.destructive,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isDeleting ? null : _handleDeleteAccount,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.delete_forever_rounded, size: 18),
                      label: Text(
                        _isDeleting ? 'Erasing Account...' : 'Delete Account',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
