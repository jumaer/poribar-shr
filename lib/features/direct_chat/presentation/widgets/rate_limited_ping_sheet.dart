import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/global_bottom_sheet.dart';
import '../../../private_vault/presentation/providers/direct_message_quota_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../family_management/data/datasources/family_firestore_datasource.dart';

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
  final FamilyFirestoreDatasource _datasource = FamilyFirestoreDatasource();
  String? _selectedMemberPhone;
  String? _selectedMemberName;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final sentCount = ref.watch(directMessageQuotaProvider);
    final isQuotaExhausted = sentCount >= DirectMessageQuotaNotifier.maxDailyLimit;
    final currentUser = ref.watch(authUserProvider);
    final familyId = currentUser?.activeFamilyId ?? '';
    final canSendPush = (currentUser?.isAdmin ?? false) || (currentUser?.canSendPushNotification ?? false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _datasource.streamFamilyMembers(familyId),
      builder: (context, snapshot) {
        final allMembers = snapshot.data ?? [];
        final otherMembers = allMembers.where((m) {
          final phone = m['phoneNumber']?.toString() ?? '';
          return phone.isNotEmpty && phone != currentUser?.phoneNumber;
        }).toList();

        if (otherMembers.isNotEmpty && _selectedMemberPhone == null) {
          _selectedMemberPhone = otherMembers.first['phoneNumber']?.toString();
          _selectedMemberName = otherMembers.first['name']?.toString() ?? l10n.translate('invitation_default_role');
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!canSendPush) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkRed,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryRed),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.translate('ping_permission_blocked'),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
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
                        '${l10n.translate('ping_daily_quota_title')}: $sentCount/৩ ${l10n.translate('ping_used_text')}',
                        style: TextStyle(
                          color: isQuotaExhausted ? AppColors.primaryRed : AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isQuotaExhausted
                        ? l10n.translate('ping_limit_over')
                        : '${3 - sentCount} ${l10n.translate('ping_left_text')}',
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
                child: Text(
                  l10n.translate('ping_limit_over_desc'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 14),
            ] else if (otherMembers.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDarkSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.iosDivider),
                ),
                child: Column(
                  children: [
                    const Icon(CupertinoIcons.person_2, color: AppColors.textSecondary, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      l10n.translate('ping_no_other_members'),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate('ping_no_members_hint'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
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
                    value: _selectedMemberPhone,
                    dropdownColor: AppColors.cardDark,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    icon: const Icon(CupertinoIcons.chevron_down, color: AppColors.accentGreen, size: 16),
                    items: otherMembers.map((m) {
                      final name = m['name']?.toString() ?? l10n.translate('invitation_default_role');
                      final rel = m['relation']?.toString() ?? '';
                      final phone = m['phoneNumber']?.toString() ?? '';
                      final label = rel.isNotEmpty ? '$name ($rel)' : name;
                      return DropdownMenuItem(
                        value: phone,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedMemberPhone = val;
                          final found = otherMembers.firstWhere((m) => m['phoneNumber'] == val, orElse: () => {});
                          _selectedMemberName = found['name']?.toString() ?? l10n.translate('invitation_default_role');
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GlassTextField(
                controller: _messageController,
                label: l10n.translate('ping_msg_label'),
                hint: l10n.translate('ping_msg_hint'),
                maxLines: 2,
                prefixIcon: CupertinoIcons.chat_bubble_text,
              ),
              const SizedBox(height: 16),
              GlassButton(
                text: !canSendPush
                    ? l10n.translate('ping_btn_no_perm')
                    : isQuotaExhausted
                        ? l10n.translate('ping_btn_limit_over')
                        : l10n.translate('ping_btn_send'),
                icon: CupertinoIcons.paperplane_fill,
                onPressed: (!canSendPush || isQuotaExhausted)
                    ? null
                    : () {
                  final text = _messageController.text.trim();
                  if (text.isNotEmpty && _selectedMemberPhone != null) {
                    final success = ref.read(directMessageQuotaProvider.notifier).recordSentMessage();
                    if (success) {
                      NotificationService().sendCustomPush(
                        title: l10n.language == AppLanguage.bangla ? 'পরিবার থেকে সরাসরি পিং' : 'Direct Ping from Family',
                        body: text,
                        senderName: currentUser?.fullName ?? 'পরিবার সদস্য',
                        senderPhone: currentUser?.phoneNumber,
                        receiverId: _selectedMemberPhone!,
                        familyId: familyId,
                        senderIsPermitted: true,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.language == AppLanguage.bangla
                                ? '$_selectedMemberName-কে ডিরেক্ট মেসেজ পাঠানো হয়েছে!'
                                : 'Direct message sent to $_selectedMemberName!',
                          ),
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
      },
    );
  }
}
