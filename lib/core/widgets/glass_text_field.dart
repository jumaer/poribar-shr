import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../theme/glass_theme.dart';

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.readOnly = false,
    this.obscureText = false,
    this.autofillHints,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      borderRadius: 14,
      blurSigma: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      surfaceColor: AppColors.cardDark,
      borderColor: AppColors.iosDivider,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        buildCounter: maxLength != null
            ? (context, {required currentLength, required isFocused, maxLength}) => null
            : null,
        readOnly: readOnly,
        obscureText: obscureText,
        autofillHints: autofillHints,
        onTap: onTap,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 13),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.accentGreen, size: 20) : null,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
