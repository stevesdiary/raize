import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

enum AthleticButtonVariant { primary, secondary, outline, destructive }

class AthleticButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AthleticButtonVariant variant;
  final Widget? icon;
  final double height;

  const AthleticButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AthleticButtonVariant.primary,
    this.icon,
    this.height = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AthleticButtonVariant.primary:
        backgroundColor = colors.primary;
        textColor = Colors.white;
        break;
      case AthleticButtonVariant.secondary:
        backgroundColor = colors.cardElevated;
        textColor = colors.textPrimary;
        borderSide = BorderSide(color: colors.border, width: 1);
        break;
      case AthleticButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = colors.textPrimary;
        borderSide = BorderSide(color: colors.border, width: 1.5);
        break;
      case AthleticButtonVariant.destructive:
        backgroundColor = colors.destructive;
        textColor = Colors.white;
        break;
    }

    final isEnabled = onPressed != null && !isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: variant == AthleticButtonVariant.primary && isEnabled
            ? [
                BoxShadow(
                  color: colors.primaryGlow,
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isEnabled
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withAlpha(128),
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: borderSide,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 10),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: isEnabled ? textColor : textColor.withAlpha(128),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

