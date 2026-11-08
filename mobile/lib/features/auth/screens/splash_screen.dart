import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/athletic_button.dart';
import '../../dashboard/screens/home_dashboard_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Check authentication and navigate
    _navTimer = Timer(const Duration(milliseconds: 2400), () async {
      await ref.read(authProvider.notifier).checkAuth();
      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        // User logged in, navigate to Home Dashboard
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (ctx, anim1, anim2) => const HomeDashboardScreen(),
            transitionsBuilder: (ctx, anim, secAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      } else {
        // User not logged in, navigate to Onboarding
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (ctx, anim1, anim2) => const OnboardingScreen(),
            transitionsBuilder: (ctx, anim, secAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGetStarted() async {
    _navTimer?.cancel();
    await ref.read(authProvider.notifier).checkAuth();
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, anim1, anim2) => const HomeDashboardScreen(),
          transitionsBuilder: (ctx, anim, secAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, anim1, anim2) => const OnboardingScreen(),
          transitionsBuilder: (ctx, anim, secAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _opacityAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Glowing Athletic Emblem
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.emerald,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(100),
                              blurRadius: 36,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: AppColors.emerald.withAlpha(80),
                              blurRadius: 48,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.backgroundDeep,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.bolt_rounded,
                                size: 52,
                                color: AppColors.emerald,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Brand Title
                      Text(
                        'RAIZE',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 8,
                              color: Colors.white,
                            ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'UNIFIED ATHLETIC OS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.5,
                              color: AppColors.textSecondary,
                            ),
                      ),

                      const Spacer(),

                      // Indeterminate Loading Bar
                      Container(
                        width: 140,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: const LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Telemetry micro-pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.emerald,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'MIFFLIN-ST JEOR & KALMAN TELEMETRY',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick Action CTA
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AthleticButton(
                          text: 'Get Started',
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          onPressed: _handleGetStarted,
                          variant: AthleticButtonVariant.primary,
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
