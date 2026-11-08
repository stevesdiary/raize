import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/athletic_button.dart';
import 'sign_up_screen.dart';
import 'sign_in_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'tag': 'MYFITNESSPAL CAPABILITY',
      'title': 'Intelligent Nutrition\n& Local Diet Tracking',
      'description':
          'Calculate your Mifflin-St Jeor TDEE, log daily meals, and accurately measure Nigerian staples with colloquial portion units like mudu, derica, and wraps.',
      'icon': Icons.restaurant_menu_rounded,
      'accentColor': AppColors.amber,
      'metric': '1,920 kcal Target',
    },
    {
      'tag': 'STRAVA CAPABILITY',
      'title': 'Precision GPS Telemetry\n& Privacy Protection',
      'description':
          'Track outdoor runs and cycling with speed-adaptive Kalman filtering. Automatically protect your home with 250m circular privacy zones.',
      'icon': Icons.navigation_rounded,
      'accentColor': AppColors.emerald,
      'metric': '250m Safe Zones',
    },
    {
      'tag': 'LADDER CAPABILITY',
      'title': 'Structured Training\n& Progressive Overload',
      'description':
          'Follow structured resistance programs, log sets with real-time rest timers, calculate estimated 1RM, and track total session volume tonnage.',
      'icon': Icons.fitness_center_rounded,
      'accentColor': AppColors.primary,
      'metric': 'Overload Tonnage',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  void _navigateToSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  void _onPrimaryAction() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToSignUp();
    }
  }

  String get _primaryButtonText {
    if (_currentPage == 0) return 'Get Started';
    if (_currentPage < _slides.length - 1) return 'Continue';
    return 'Get Started';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withAlpha(80)),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'RAIZE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _navigateToSignUp,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Carousel Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final Color accent = slide['accentColor'];

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Visual Card Frame
                        Container(
                          width: double.infinity,
                          height: 220,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withAlpha(20),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withAlpha(30),
                                  border: Border.all(color: accent.withAlpha(80), width: 1.5),
                                ),
                                child: Icon(
                                  slide['icon'] as IconData,
                                  size: 36,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.cardElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Text(
                                  slide['metric'] as String,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Capability Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            slide['tag'] as String,
                            style: TextStyle(
                              color: accent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Title
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                        ),

                        const SizedBox(height: 10),

                        // Description
                        Text(
                          slide['description'] as String,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Pagination Dots Indicator (Clickable to jump directly to any onboarding screen)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final isCurrent = index == _currentPage;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isCurrent ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Bottom CTA Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  AthleticButton(
                    text: _primaryButtonText,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: _onPrimaryAction,
                    variant: AthleticButtonVariant.primary,
                  ),
                  const SizedBox(height: 12),
                  AthleticButton(
                    text: 'I already have an account • Log In',
                    onPressed: _navigateToSignIn,
                    variant: AthleticButtonVariant.outline,
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
