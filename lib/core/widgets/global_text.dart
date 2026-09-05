import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum GlobalTextVariant {
  h1,
  h2,
  h3,
  bodyLarge,
  bodyMedium,
  bodySmall,
  caption,
  button,
}

class GlobalText extends StatelessWidget {
  final String text;
  final GlobalTextVariant variant;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const GlobalText(
    this.text, {
    super.key,
    this.variant = GlobalTextVariant.bodyMedium,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle style;
    switch (variant) {
      case GlobalTextVariant.h1:
        style = const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
        break;
      case GlobalTextVariant.h2:
        style = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
        break;
      case GlobalTextVariant.h3:
        style = const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
        break;
      case GlobalTextVariant.bodyLarge:
        style = const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textPrimary);
        break;
      case GlobalTextVariant.bodyMedium:
        style = const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textSecondary);
        break;
      case GlobalTextVariant.bodySmall:
        style = const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary);
        break;
      case GlobalTextVariant.caption:
        style = const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: AppColors.textMuted);
        break;
      case GlobalTextVariant.button:
        style = const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white);
        break;
    }

    if (color != null) style = style.copyWith(color: color);
    if (fontWeight != null) style = style.copyWith(fontWeight: fontWeight);

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: style,
    );
  }
}
