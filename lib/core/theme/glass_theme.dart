import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlassBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? surfaceColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassBox({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.blurSigma = 16.0,
    this.surfaceColor,
    this.borderColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: surfaceColor ?? AppColors.cardDark,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.iosDivider,
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}
