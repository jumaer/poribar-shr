import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/firestore_image_service.dart';
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
  String _selectedCategory = '📢 জরুরি ঘোষণা';
  String? _selectedImageBase64;
  bool _isSending = false;

  int _todayPushesSent = 0;
  final int _maxDailyPushes = 5;

  final List<Map<String, String>> _categories = [
    {'name': '📢 জরুরি ঘোষণা', 'hint': 'জরুরি পারিবারিক বার্তা বা নির্দেশনা'},
    {'name': '🛍️ অফার ও কেনাকাটা', 'hint': 'নতুন কোনো পণ্যের অফার বা কেনাকাটা'},
    {'name': '👥 মেহমান আগমন', 'hint': 'বাসায় অতিথি/মেহমান আসছেন'},
    {'name': '💰 টাকা বা বকেয়া পরিশোধ', 'hint': 'টাকা পাঠানো হয়েছে বা প্রয়োজন'},
    {'name': '✍️ অন্যান্য সাধারণ', 'hint': 'সাধারণ বার্তা'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.familyMembers.isNotEmpty
        ? widget.familyMembers.first
        : 'সকল সদস্য';
    _loadDailyPushCount();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String get _todayKey {
    final user = ref.read(authUserProvider);
    final familyId = user?.activeFamilyId ?? 'fam_01';
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'push_quota_${familyId}_$dateStr';
  }

  Future<void> _loadDailyPushCount() async {
    try {
      final val = await AppDatabase().appSettingsDao.get(_todayKey);
      if (mounted && val != null) {
        setState(() {
          _todayPushesSent = int.tryParse(val) ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _incrementDailyPushCount() async {
    try {
      final newCount = _todayPushesSent + 1;
      await AppDatabase().appSettingsDao.set(_todayKey, newCount.toString());
      if (mounted) {
        setState(() {
          _todayPushesSent = newCount;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedImageBase64 = base64Encode(bytes);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ছবি নির্বাচন ত্রুটি: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
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
              'কেবলমাত্র অনুমোদিত এডমিনরা পরিবারের সদস্যদের কাছে সরাসরি পুশ নোটিফিকেশন পাঠাতে পারেন।',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final isLimitReached = _todayPushesSent >= _maxDailyPushes;
    final remainingPushes = _maxDailyPushes - _todayPushesSent;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Daily Push Limit Badge (Max 5/day)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isLimitReached
                  ? AppColors.primaryRed.withValues(alpha: 0.15)
                  : AppColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLimitReached
                    ? AppColors.primaryRed.withValues(alpha: 0.4)
                    : AppColors.primaryGreen.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isLimitReached ? Icons.block_flipped : Icons.verified_outlined,
                  color: isLimitReached ? AppColors.primaryRed : AppColors.primaryGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isLimitReached
                        ? 'আজকের জন্য সর্বোচ্চ ৫টি পুশ পাঠানো সম্পন্ন হয়েছে।'
                        : 'দৈনিক পুশ কোটা: $remainingPushes / $_maxDailyPushes টি বাকি আছে।',
                    style: TextStyle(
                      color: isLimitReached ? AppColors.primaryRed : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Selector
          const Text(
            'বার্তার ধরন বা ক্যাটাগরি',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.cardDarkSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedCategory,
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accentGreen),
                items: _categories.map((c) {
                  return DropdownMenuItem(
                    value: c['name'],
                    child: Text(c['name']!),
                  );
                }).toList(),
                onChanged: isLimitReached
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                            if (_titleController.text.isEmpty) {
                              _titleController.text = val;
                            }
                          });
                        }
                      },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Target Member Selector
          const Text(
            'প্রাপক সদস্য',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.cardDarkSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedMember,
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accentGreen),
                items: widget.familyMembers.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m),
                  );
                }).toList(),
                onChanged: isLimitReached
                    ? null
                    : (val) {
                        if (val != null) setState(() => _selectedMember = val);
                      },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          GlassTextField(
            controller: _titleController,
            label: 'নোটিফিকেশন শিরোনাম',
            hint: 'যেমন: মেহমান আসছেন / জরুরি অফার',
            prefixIcon: Icons.title,
            readOnly: isLimitReached,
          ),
          const SizedBox(height: 10),

          // Message
          GlassTextField(
            controller: _messageController,
            label: 'বার্তার বিবরণ',
            hint: 'বিস্তারিত বিবরণ লিখুন...',
            maxLines: 3,
            prefixIcon: Icons.message_outlined,
            readOnly: isLimitReached,
          ),
          const SizedBox(height: 12),

          // Image Attachment Section
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: isLimitReached ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text('ছবি যুক্ত করুন', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: isLimitReached ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('ক্যামেরা', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          if (_selectedImageBase64 != null) ...[
            const SizedBox(height: 10),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(_selectedImageBase64!),
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImageBase64 = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),

          // Submit Button
          GlassButton(
            text: isLimitReached
                ? 'আজকের কোটা শেষ'
                : (_isSending ? 'পুশ পাঠানো হচ্ছে...' : 'এখনই পুশ পাঠান'),
            icon: Icons.send_rounded,
            isLoading: _isSending,
            onPressed: isLimitReached || _isSending
                ? null
                : () async {
                    final title = _titleController.text.trim();
                    final body = _messageController.text.trim();
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    if (title.isEmpty || body.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('শিরোনাম ও বার্তার বিবরণ প্রদান করুন'),
                          backgroundColor: AppColors.primaryRed,
                        ),
                      );
                      return;
                    }

                    setState(() => _isSending = true);

                    final currentUser = ref.read(authUserProvider);
                    final adminName = currentUser?.fullName.isNotEmpty == true
                        ? currentUser!.fullName
                        : 'পরিবার অ্যাডমিন';
                    final familyId = currentUser?.activeFamilyId ?? 'fam_01';

                    String? uploadedImageUrl;
                    if (_selectedImageBase64 != null) {
                      try {
                        uploadedImageUrl = await FirestoreImageService.saveImageToFirestore(
                          _selectedImageBase64!,
                        );
                      } catch (_) {}
                    }

                    await NotificationService().sendCustomPush(
                      title: '$_selectedCategory: $title',
                      body: body,
                      senderName: adminName,
                      receiverId: _selectedMember,
                      senderIsPermitted: widget.canSend,
                      familyId: familyId,
                      senderPhone: currentUser?.phoneNumber,
                      imageUrl: uploadedImageUrl,
                    );

                    await _incrementDailyPushCount();

                    if (!mounted) return;
                    setState(() => _isSending = false);
                    navigator.pop();

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('পুশ নোটিফিকেশন পাঠানো হয়েছে! (আজকের বাকি: ${remainingPushes - 1}টি)'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
