import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/global_bottom_sheet.dart';
import '../../../private_vault/presentation/providers/direct_message_quota_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class RateLimitedPingSheet extends ConsumerStatefulWidget {
  const RateLimitedPingSheet({super.key});

  static Future<void> show(BuildContext context) {
    return GlobalBottomSheet.show(
      context: context,
      title: '১-টু-১ ডিরেক্ট পিং পাঠান (দৈনিক ৩টি)',
      child: const RateLimitedPingSheet(),
    );
  }

  @override
  ConsumerState<RateLimitedPingSheet> createState() => _RateLimitedPingSheetState();
}

class _RateLimitedPingSheetState extends ConsumerState<RateLimitedPingSheet> {
  final _messageController = TextEditingController();
  final List<String> _members = ['রাশেদ খান (ভাই)', 'নুসরাত জাহান (বোন)'];
  late String _selectedMember;

  @override
  void initState() {
    super.initState();
    _selectedMember = _members.first;
  }

  @override
  Widget build(BuildContext context) {
    final sentCount = ref.watch(directMessageQuotaProvider);
    final isQuotaExhausted = sentCount >= DirectMessageQuotaNotifier.maxDailyLimit;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDarkSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.iosDivider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isQuotaExhausted
                        ? CupertinoIcons.exclamationmark_circle
                        : CupertinoIcons.chat_bubble_2_fill,
                    color: isQuotaExhausted ? AppColors.primaryRed : AppColors.primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'দৈনিক পিং লিমিট: $sentCount/৩ টি ব্যবহৃত',
                    style: TextStyle(
                      color: isQuotaExhausted ? AppColors.primaryRed : AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                isQuotaExhausted ? 'লিমিট শেষ' : '${3 - sentCount} টি অবশিষ্ট',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isQuotaExhausted) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardDarkSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: const Text(
              'আপনি আজকের সর্বোচ্চ ৩টি ডিরেক্ট পিং কোটা সম্পন্ন করেছেন। রাত ১২টার পর কোটা স্বয়ংক্রিয়ভাবে রিসেট হবে।',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardDarkSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedMember,
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                icon: const Icon(CupertinoIcons.chevron_down, color: AppColors.accentGreen, size: 16),
                items: _members.map((m) {
                  return DropdownMenuItem(value: m, child: Text(m));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMember = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: _messageController,
            label: 'সরাসরি জরুরি বার্তা',
            hint: 'যেমন: টাকা কি পেয়েছ? ৫০০ টাকা...',
            maxLines: 2,
            prefixIcon: CupertinoIcons.chat_bubble_text,
          ),
          const SizedBox(height: 16),
          GlassButton(
            text: 'সরাসরি বার্তা পাঠান',
            icon: CupertinoIcons.paperplane_fill,
            onPressed: () {
              final text = _messageController.text.trim();
              if (text.isNotEmpty) {
                final success = ref.read(directMessageQuotaProvider.notifier).recordSentMessage();
                if (success) {
                  NotificationService().sendCustomPush(
                    title: 'পরিবার থেকে সরাসরি পিং',
                    body: text,
                    senderName: ref.read(authUserProvider)?.fullName ?? 'পরিবার সদস্য',
                    receiverId: _selectedMember,
                    senderIsPermitted: true,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ডিরেক্ট মেসেজ সফলভাবে পাঠানো হয়েছে!'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ],
    );
  }
}
