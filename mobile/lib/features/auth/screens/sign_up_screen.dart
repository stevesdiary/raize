import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/athletic_button.dart';
import '../widgets/athletic_text_field.dart';
import '../widgets/password_strength_bar.dart';
import 'sign_in_screen.dart';
import '../../assessment/screens/assessment_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();

  DateTime? _selectedDob;
  String _preferredMeasurement = 'metric';
  bool _obscurePassword = true;
  bool _ndpaConsent = false;
  String? _calculatedAge;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    // 18+ default (e.g. 2005)
    final initial = DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? initial,
      firstDate: DateTime(1930),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.card,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        final age = now.year - picked.year -
            ((now.month < picked.month || (now.month == picked.month && now.day < picked.day)) ? 1 : 0);
        _calculatedAge = '$age years old';
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Date of Birth.')),
      );
      return;
    }

    // Verify 18+ gate
    final now = DateTime.now();
    final age = now.year - _selectedDob!.year -
        ((now.month < _selectedDob!.month ||
                (now.month == _selectedDob!.month && now.day < _selectedDob!.day))
            ? 1
            : 0);

    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.destructive,
          content: Text('You must be 18 or older to register an independent athletic account.'),
        ),
      );
      return;
    }

    if (!_ndpaConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.destructive,
          content: Text('Please accept the NDPA 2023 Consent to proceed.'),
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          email: _emailController.text,
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text,
          dateOfBirth: _dobController.text,
          preferredMeasurement: _preferredMeasurement,
          consentTerms: _ndpaConsent,
          consentHealthData: true,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald,
          content: Text('Account created! Welcome to Raize.'),
        ),
      );
      // Seamlessly transition to Fitness Assessment (Stage A)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AssessmentScreen()),
      );
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.destructive, content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'STEP 1 OF 2 • ATHLETIC ONBOARDING',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  'Start Your Athletic Journey',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join Raize to personalize your training, nutrition, and telemetry.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 28),

                // Full Name
                AthleticTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'e.g. Stephen Oyeyemi',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Full name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Username (Leaderboards & Login)
                AthleticTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'e.g. stephen_fit (used on leaderboards)',
                  prefixIcon: Icons.alternate_email_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Username is required';
                    }
                    final clean = val.trim().replaceFirst(RegExp(r'^@'), '');
                    if (clean.length < 3 || clean.length > 30) {
                      return 'Username must be between 3 and 30 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(clean)) {
                      return 'Username can only contain letters, numbers, _, ., -';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Email
                AthleticTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'athlete@raize.fit',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: (val) {
                    if (val == null || !val.contains('@')) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password
                AthleticTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Min. 8 chars with symbols',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _passwordController,
                  builder: (context, value, child) {
                    return PasswordStrengthBar(password: value.text);
                  },
                ),
                const SizedBox(height: 18),

                // Date of Birth & 18+ Safeguard
                AthleticTextField(
                  controller: _dobController,
                  label: 'Date of Birth',
                  hint: 'YYYY-MM-DD',
                  readOnly: true,
                  prefixIcon: Icons.calendar_today_outlined,
                  suffixIcon: _calculatedAge != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              _calculatedAge!,
                              style: const TextStyle(
                                color: AppColors.emerald,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : null,
                  onTap: _selectDateOfBirth,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Date of Birth is required';
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text(
                      '18+ Adult Training Platform • Minor Safeguards Enforced',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Measurement Preference
                Text(
                  'Measurement Preference',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _preferredMeasurement = 'metric'),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _preferredMeasurement == 'metric'
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Metric (kg, cm, km)',
                              style: TextStyle(
                                color: _preferredMeasurement == 'metric'
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _preferredMeasurement = 'imperial'),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _preferredMeasurement == 'imperial'
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Imperial (lbs, ft, mi)',
                              style: TextStyle(
                                color: _preferredMeasurement == 'imperial'
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // NDPA 2023 Consent Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _ndpaConsent,
                      activeColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => setState(() => _ndpaConsent = val ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _ndpaConsent = !_ndpaConsent),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'I agree to the Terms of Service and NDPA 2023 Data Privacy Policy, including sensitive biometric and GPS telemetry processing.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Submit CTA
                AthleticButton(
                  text: 'Create Account',
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                  variant: AthleticButtonVariant.primary,
                ),
                const SizedBox(height: 20),

                // Social Auth Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: TextStyle(
                          color: AppColors.textMuted.withAlpha(150),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 18),

                // Social Sign-In Buttons (Apple & Google)
                Row(
                  children: [
                    Expanded(
                      child: AthleticButton(
                        text: 'Apple',
                        variant: AthleticButtonVariant.secondary,
                        icon: const Icon(Icons.apple, size: 20, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Apple ID Sign-In initialized')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AthleticButton(
                        text: 'Google',
                        variant: AthleticButtonVariant.secondary,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 26, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Google Sign-In initialized')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Link to Sign In
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        children: [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
