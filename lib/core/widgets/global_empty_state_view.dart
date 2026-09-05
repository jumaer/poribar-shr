import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/glass_theme.dart';
import 'glass_button.dart';

enum EmptyStateType { noInternet, noData, accessDenied }

class GlobalEmptyStateView extends StatelessWidget {
  final EmptyStateType type;
  final String? customTitle;
  final String? customSubtitle;
  final VoidCallback? onRetry;

  const GlobalEmptyStateView({
    super.key,
    required this.type,
    this.customTitle,
    this.customSubtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    String title;
    String subtitle;

    switch (type) {
      case EmptyStateType.noInternet:
        icon = CupertinoIcons.wifi_slash;
        iconColor = AppColors.primaryRed;
        title = customTitle ?? 'ইন্টারনেট সংযোগ নেই';
        subtitle = customSubtitle ?? 'অফলাইন ক্যাশ থেকে তথ্য লোড হয়েছে। রিয়েল-টাইম আপডেটের জন্য ইন্টারনেট সংযোগ চালু করুন।';
        break;
      case EmptyStateType.noData:
        icon = CupertinoIcons.tray;
        iconColor = AppColors.accentGreen;
        title = customTitle ?? 'কোনো তথ্য পাওয়া যায়নি';
        subtitle = customSubtitle ?? 'এখনও কোনো লেনদেন বা নোটিফিকেশন এন্ট্রি করা হয়নি। নতুন এন্ট্রি যোগ করতে নিচের (+) বাটনে চাপুন।';
        break;
      case EmptyStateType.accessDenied:
        icon = CupertinoIcons.lock_shield;
        iconColor = Colors.amber;
        title = customTitle ?? 'অ্যাক্সেস সংরক্ষিত';
        subtitle = customSubtitle ?? 'এই সেকশনটি দেখার জন্য পরিবারের এডমিনের নিকট থেকে অনুমোদনের প্রয়োজন।';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassBox(
          borderRadius: 24,
          blurSigma: 20,
          surfaceColor: AppColors.cardDark.withValues(alpha: 0.9),
          borderColor: iconColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.15),
                  border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Icon(icon, color: iconColor, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 22),
                GlassButton(
                  text: 'পুনরায় চেষ্টা করুন',
                  icon: CupertinoIcons.refresh,
                  onPressed: onRetry!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
