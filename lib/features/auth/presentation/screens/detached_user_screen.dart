import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../expenses/presentation/screens/dashboard_screen.dart';

class DetachedUserScreen extends StatefulWidget {
  final String userName;
  final String userPhone;

  const DetachedUserScreen({
    super.key,
    required this.userName,
    required this.userPhone,
  });

  @override
  State<DetachedUserScreen> createState() => _DetachedUserScreenState();
}

class _DetachedUserScreenState extends State<DetachedUserScreen> {
  final _newFamilyNameCtrl = TextEditingController();
  bool _creating = false;

  void _handleCreateFamily() {
    final name = _newFamilyNameCtrl.text.trim();
    if (name.isNotEmpty) {
      setState(() => _creating = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassBox(
                borderRadius: 24,
                blurSigma: 20,
                surfaceColor: AppColors.cardDark.withValues(alpha: 0.9),
                borderColor: AppColors.primaryGreen.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentGreen.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4), width: 2),
                      ),
                      child: const Icon(CupertinoIcons.person_crop_circle_badge_plus, color: AppColors.accentGreen, size: 38),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'স্বাগতম, ${widget.userName}!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'বর্তমানে আপনি কোনো পরিবারের অন্তর্ভুক্ত নন। আপনি নিজে একটি নতুন পরিবারের অ্যাডমিন হতে পারেন অথবা অন্য পরিবারের অ্যাডমিন কর্তৃক যোগ করার অপেক্ষা করতে পারেন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassTextField(
                      controller: _newFamilyNameCtrl,
                      label: 'নতুন পরিবারের নাম',
                      hint: 'যেমন: চৌধুরী পরিবার',
                      prefixIcon: CupertinoIcons.home,
                    ),
                    const SizedBox(height: 16),
                    GlassButton(
                      text: 'নতুন পরিবার তৈরি করুন (এডমিন)',
                      icon: CupertinoIcons.plus_circle_fill,
                      isLoading: _creating,
                      onPressed: _handleCreateFamily,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.device_phone_portrait, color: AppColors.textMuted, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'নিবন্ধিত নম্বর: ${widget.userPhone}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
