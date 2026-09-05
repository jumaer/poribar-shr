import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/global_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SendCustomPushSheet extends ConsumerStatefulWidget {
  final List<String> familyMembers;
  final bool canSend;

  const SendCustomPushSheet({
    super.key,
    required this.familyMembers,
    required this.canSend,
  });

  static Future<void> show({
    required BuildContext context,
    required List<String> familyMembers,
    required bool canSend,
  }) {
    return GlobalBottomSheet.show(
      context: context,
      title: 'সরাসরি পুশ নোটিফিকেশন পাঠান',
      child: SendCustomPushSheet(
        familyMembers: familyMembers,
        canSend: canSend,
      ),
    );
  }

  @override
  ConsumerState<SendCustomPushSheet> createState() => _SendCustomPushSheetState();
}

class _SendCustomPushSheetState extends ConsumerState<SendCustomPushSheet> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  late String _selectedMember;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.familyMembers.isNotEmpty
        ? widget.familyMembers.first
        : 'সকল সদস্য';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canSend) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.lock_outline, color: AppColors.accentRed, size: 36),
            SizedBox(height: 8),
            Text(
              'পুশ পাঠানোর অনুমতি নেই',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'কেবলমাত্র অনুমোদিত এডমিনরা (সর্বোচ্চ ৫ জন) সরাসরি পুশ নোটিফিকেশন পাঠাতে পারেন।',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMember,
              dropdownColor: AppColors.cardDark,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accentGreen),
              items: widget.familyMembers.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(m),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedMember = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        GlassTextField(
          controller: _titleController,
          label: 'নোটিফিকেশন শিরোনাম',
          hint: 'যেমন: জরুরি টাকা প্রয়োজন',
          prefixIcon: Icons.title,
        ),
        const SizedBox(height: 10),
        GlassTextField(
          controller: _messageController,
          label: 'বার্তার বিবরণ',
          hint: 'যেমন: টাকা কি পেয়েছ? ৫০০ টাকা...',
          maxLines: 3,
          prefixIcon: Icons.message_outlined,
        ),
        const SizedBox(height: 18),
        GlassButton(
          text: 'এখনই পুশ পাঠান',
          icon: Icons.send_outlined,
          onPressed: () {
            if (_titleController.text.isNotEmpty && _messageController.text.isNotEmpty) {
              final currentUser = ref.read(authUserProvider);
              final adminName = currentUser?.fullName != null ? currentUser!.fullName : 'পরিবার অ্যাডমিন';
              NotificationService().sendCustomPush(
                title: _titleController.text.trim(),
                body: _messageController.text.trim(),
                senderName: adminName,
                receiverId: _selectedMember,
                senderIsPermitted: widget.canSend,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('পুশ নোটিফিকেশন সফলভাবে পাঠানো হয়েছে!'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
