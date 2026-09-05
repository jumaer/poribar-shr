import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlobalCircleImageLoader extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackInitials;

  const GlobalCircleImageLoader({
    super.key,
    this.imageUrl,
    this.radius = 24.0,
    this.fallbackInitials,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.cardDark,
        child: ClipOval(
          child: Image.network(
            imageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallbackView(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accentGreen),
                ),
              );
            },
          ),
        ),
      );
    }
    return _fallbackView();
  }

  Widget _fallbackView() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accentGreen.withValues(alpha: 0.2),
      child: Text(
        fallbackInitials ?? 'প',
        style: TextStyle(
          color: AppColors.accentGreen,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class GlobalPngLoader extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const GlobalPngLoader({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => GlobalErrorImageView(
        width: width,
        height: height,
      ),
    );
  }
}

class GlobalSvgLoader extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const GlobalSvgLoader({
    super.key,
    required this.icon,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color ?? AppColors.accentGreen,
    );
  }
}

class GlobalErrorImageView extends StatelessWidget {
  final double? width;
  final double? height;
  final String? message;

  const GlobalErrorImageView({
    super.key,
    this.width,
    this.height,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined, color: AppColors.accentRed, size: 28),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
