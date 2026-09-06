import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/global_bottom_sheet.dart';
import '../../data/datasources/family_firestore_datasource.dart';

class EditMemberPermissionsSheet extends StatefulWidget {
  final String familyId;
  final Map<String, dynamic> member;
  final bool isSelf;
  final VoidCallback? onUpdated;

  const EditMemberPermissionsSheet({
    super.key,
    required this.familyId,
    required this.member,
    required this.isSelf,
    this.onUpdated,
  });

  static Future<void> show({
    required BuildContext context,
    required String familyId,
    required Map<String, dynamic> member,
    required bool isSelf,
    VoidCallback? onUpdated,
  }) {
    return GlobalBottomSheet.show(
      context: context,
      title: 'সদস্যের অনুমতি ও সম্পর্ক নিয়ন্ত্রণ',
      child: EditMemberPermissionsSheet(
        familyId: familyId,
        member: member,
        isSelf: isSelf,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<EditMemberPermissionsSheet> createState() => _EditMemberPermissionsSheetState();
}

class _EditMemberPermissionsSheetState extends State<EditMemberPermissionsSheet> {
  final FamilyFirestoreDatasource _datasource = FamilyFirestoreDatasource();
  final TextEditingController _customRelationCtrl = TextEditingController();

  final List<String> _relationPresets = [
    'পিতা / বাবা',
    'মাতা / মা',
    'স্বামী / স্ত্রী',
    'সন্তান',
    'ভাই',
    'বোন',
    'দাদা / নানা',
    'দাদী / নানী',
    'চাচা / মামা',
    'ফুফু / খালা',
    'অন্যান্য / কাস্টম',
  ];

  late String _selectedRelation;
  bool _isCustomRelation = false;
  late String _selectedRole;
  late bool _canAddMembers;
  late bool _canSetAlarms;
  late bool _canSendPushNotification;
  late bool _canViewExpenses;
  late bool _canUpload;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initialRelation = widget.member['relation']?.toString() ?? 'পিতা / বাবা';
    if (_relationPresets.contains(initialRelation)) {
      _selectedRelation = initialRelation;
      _isCustomRelation = false;
    } else {
      _selectedRelation = 'অন্যান্য / কাস্টম';
      _isCustomRelation = true;
      _customRelationCtrl.text = initialRelation;
    }

    _selectedRole = widget.member['role']?.toString() ?? 'member';
    _canAddMembers = widget.member['canAddMembers'] == true;
    _canSetAlarms = widget.member['canSetAlarms'] == null ? true : (widget.member['canSetAlarms'] == true);
    _canSendPushNotification = widget.member['canSendPushNotification'] == true;
    _canViewExpenses = widget.member['canViewExpenses'] == null ? true : (widget.member['canViewExpenses'] == true);
    _canUpload = widget.member['canUpload'] == null ? true : (widget.member['canUpload'] == true);
  }

  @override
  void dispose() {
    _customRelationCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final memberPhone = widget.member['phoneNumber']?.toString() ?? '';
    if (memberPhone.isEmpty) return;

    String finalRelation = _selectedRelation;
    if (_isCustomRelation) {
      final custom = _customRelationCtrl.text.trim();
      if (custom.isNotEmpty) {
        finalRelation = custom;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updates = <String, dynamic>{
        'relation': finalRelation,
        'role': _selectedRole,
        'canAddMembers': _selectedRole == 'admin' ? true : _canAddMembers,
        'canSetAlarms': _canSetAlarms,
        'canSendPushNotification': _selectedRole == 'admin' ? true : _canSendPushNotification,
        'canViewExpenses': _canViewExpenses,
        'canUpload': _canUpload,
      };

      await _datasource.updateMemberPermissionsAndRelation(
        familyId: widget.familyId,
        memberPhone: memberPhone,
        updates: updates,
      );

      if (!mounted) return;
      widget.onUpdated?.call();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.member['name'] ?? 'সদস্য'}-এর অনুমতি ও সম্পর্ক সংরক্ষিত হয়েছে!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'সংরক্ষণ ব্যর্থ হয়েছে! ক্লাউড নেটওয়ার্ক বা পারমিশন নিশ্চিত করুন।';
      });
    }
  }

  void _confirmRemoveMember() {
    final memberPhone = widget.member['phoneNumber']?.toString() ?? '';
    final memberName = widget.member['name']?.toString() ?? 'সদস্য';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.iosDivider),
        ),
        title: const Text(
          'পরিবার থেকে বাদ দিন',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'আপনি কি নিশ্চিতভাবে $memberName-কে পরিবার থেকে বাদ দিতে চান?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context); // close bottom sheet
              await _datasource.removeMemberFromFamily(widget.familyId, memberPhone);
              if (mounted) {
                widget.onUpdated?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$memberName-কে পরিবার থেকে বাদ দেওয়া হয়েছে।'),
                    backgroundColor: AppColors.primaryRed,
                  ),
                );
              }
            },
            child: const Text('বাদ দিন', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool disabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDarkSecondary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.iosDivider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? AppColors.primaryGreen.withValues(alpha: 0.15) : AppColors.cardDarkSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? AppColors.primaryGreen : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppColors.primaryGreen,
            onChanged: disabled ? null : onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberName = widget.member['name']?.toString() ?? 'সদস্য';
    final memberPhone = widget.member['phoneNumber']?.toString() ?? '';

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Member Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardDarkSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                  child: Text(
                    memberName.isNotEmpty ? memberName.substring(0, 1) : 'প',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memberName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        memberPhone,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.isSelf)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryGreen),
                    ),
                    child: const Text(
                      'আপনি',
                      style: TextStyle(color: AppColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.darkRed,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryRed),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Relation Selection Header
          const Text(
            'পারিবারিক সম্পর্ক (সম্পর্ক পরিবর্তন / যোগ)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
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
                value: _selectedRelation,
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryGreen),
                items: _relationPresets.map((r) {
                  return DropdownMenuItem(value: r, child: Text(r));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedRelation = val;
                      _isCustomRelation = val == 'অন্যান্য / কাস্টম';
                    });
                  }
                },
              ),
            ),
          ),

          if (_isCustomRelation) ...[
            const SizedBox(height: 8),
            GlassTextField(
              controller: _customRelationCtrl,
              label: 'কাস্টম সম্পর্ক লিখুন',
              hint: 'যেমন: মেজো ভাই, ভাগ্নে, ফুফা ইত্যাদি',
              prefixIcon: Icons.edit_outlined,
            ),
          ],
          const SizedBox(height: 14),

          // Role Selection
          const Text(
            'পরিবারে ভূমিকা (রোল)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
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
                value: _selectedRole,
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryGreen),
                items: const [
                  DropdownMenuItem(value: 'member', child: Text('সাধারণ সদস্য')),
                  DropdownMenuItem(value: 'admin', child: Text('সহ-অ্যাডমিন (সকল অনুমতি সক্রিয়)')),
                ],
                onChanged: widget.isSelf
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedRole = val;
                            if (val == 'admin') {
                              _canAddMembers = true;
                              _canSetAlarms = true;
                              _canSendPushNotification = true;
                              _canViewExpenses = true;
                              _canUpload = true;
                            }
                          });
                        }
                      },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Permissions Section
          const Text(
            'অনুমতিসমূহ নিয়ন্ত্রণ (Permissions On / Off)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),

          _buildSwitchTile(
            title: 'নতুন সদস্য যুক্ত করার অনুমতি',
            subtitle: 'পরিবারে অন্য কাউকে ইনভাইট বা ওটিপি দিয়ে যুক্ত করতে পারবে',
            icon: Icons.person_add_alt_1_outlined,
            value: _selectedRole == 'admin' ? true : _canAddMembers,
            disabled: _selectedRole == 'admin',
            onChanged: (val) => setState(() => _canAddMembers = val),
          ),

          _buildSwitchTile(
            title: 'মাসিক অ্যালার্ম ও রিমাইন্ডার সেট',
            subtitle: 'মাসিক বাড়িভাড়া, বিল বা পরিশোধের অ্যালার্ম তৈরি করতে পারবে',
            icon: Icons.alarm_outlined,
            value: _canSetAlarms,
            onChanged: (val) => setState(() => _canSetAlarms = val),
          ),

          _buildSwitchTile(
            title: 'পুশ বার্তা ও পিং পাঠানোর অনুমতি',
            subtitle: 'পরিবারের সদস্যদের কাস্টম পুশ নোটিফিকেশন বা বার্তা পাঠাতে পারবে',
            icon: Icons.notifications_active_outlined,
            value: _selectedRole == 'admin' ? true : _canSendPushNotification,
            disabled: _selectedRole == 'admin',
            onChanged: (val) => setState(() => _canSendPushNotification = val),
          ),

          _buildSwitchTile(
            title: 'হিসাব ও মোট খরচ দেখার অনুমতি',
            subtitle: 'পারিবারিক খরচের খতিয়ান ও হিসাব দেখতে পারবে',
            icon: Icons.visibility_outlined,
            value: _canViewExpenses,
            onChanged: (val) => setState(() => _canViewExpenses = val),
          ),

          _buildSwitchTile(
            title: 'রসিদ ও ভাউচার আপলোড',
            subtitle: 'ব্যয়ের সাথে রসিদের ছবি বা ডকুমেন্ট আপলোড করতে পারবে',
            icon: Icons.cloud_upload_outlined,
            value: _canUpload,
            onChanged: (val) => setState(() => _canUpload = val),
          ),

          const SizedBox(height: 16),

          // Save Button
          GlassButton(
            text: _isSaving ? 'সংরক্ষণ করা হচ্ছে...' : 'অনুমতি ও তথ্য সংরক্ষণ করুন',
            isLoading: _isSaving,
            icon: Icons.check_circle_outline,
            onPressed: _isSaving ? null : _saveChanges,
          ),

          if (!widget.isSelf) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.person_remove_outlined, color: AppColors.primaryRed, size: 18),
              label: const Text('এই সদস্যকে পরিবার থেকে বাদ দিন', style: TextStyle(color: AppColors.primaryRed, fontSize: 13)),
              onPressed: _confirmRemoveMember,
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
