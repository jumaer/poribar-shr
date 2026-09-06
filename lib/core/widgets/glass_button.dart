import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isRed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isRed = false,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;
    final baseColor = isDisabled
        ? Colors.white.withValues(alpha: 0.08)
        : (isRed ? AppColors.primaryRed : AppColors.primaryGreen);

    return SizedBox(
      width: width,
      child: Material(
        color: baseColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: (isLoading || isDisabled) ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
