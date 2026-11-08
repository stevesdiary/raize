import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({super.key, required this.password});

  int get strength {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score++;
    }
    return score; // 0 to 4
  }

  Color get strengthColor {
    switch (strength) {
      case 1:
        return AppColors.destructive;
      case 2:
        return AppColors.amber;
      case 3:
        return const Color(0xFF38BDF8); // Sky blue
      case 4:
        return AppColors.emerald;
      default:
        return AppColors.border;
    }
  }

  String get strengthLabel {
    switch (strength) {
      case 1:
        return 'Weak';
      case 2:
        return 'Moderate';
      case 3:
        return 'Strong';
      case 4:
        return 'Argon2id Elite (RFC 9106)';
      default:
        return 'Enter at least 8 characters';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            final isActive = index < strength;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 4),
                decoration: BoxDecoration(
                  color: isActive ? strengthColor : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strengthLabel,
              style: TextStyle(
                color: strengthColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'Argon2id Encrypted',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

