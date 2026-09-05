import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/auth_validators.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/global_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/family_firestore_datasource.dart';

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key});

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  final FamilyFirestoreDatasource _datasource = FamilyFirestoreDatasource();
  final List<String> _relationOptions = [
    'পিতা / বাবা',
    'মাতা / মা',
    'স্বামী / স্ত্রী',
    'সন্তান',
    'ভাই',
    'বোন',
    'অন্যান্য',
  ];

  void _openAddMemberSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRelation = _relationOptions.first;
    String selectedRole = 'member';
    bool isSaving = false;
    String? errorText;

    final currentUser = ref.read(authUserProvider);
    final familyId = currentUser?.activeFamilyId ?? 'fam_01';

    GlobalBottomSheet.show(
      context: context,
      title: 'নতুন সদস্য যুক্ত করুন',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorText != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.darkRed,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryRed),
                ),
                child: Text(
                  errorText!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
            GlassTextField(
              controller: nameCtrl,
              label: 'সদস্যের পূর্ণ নাম',
              hint: 'যেমন: রাশেদ খান',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 10),
            GlassTextField(
              controller: phoneCtrl,
              label: 'মোবাইল নম্বর (১১ ডিজিট)',
              hint: '01XXXXXXXXX',
              maxLength: 11,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              prefixIcon: Icons.phone_android_outlined,
            ),
            const SizedBox(height: 10),
            GlassTextField(
              controller: passwordCtrl,
              label: 'সদস্যের পাসওয়ার্ড (৮+ অক্ষর, A-Z, a-z, 0-9)',
              hint: 'যেমন: Pass1234',
              obscureText: true,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: 10),
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
                  value: selectedRelation,
                  dropdownColor: AppColors.cardDark,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryGreen),
                  items: _relationOptions.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => selectedRelation = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
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
                  value: selectedRole,
                  dropdownColor: AppColors.cardDark,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryGreen),
                  items: const [
                    DropdownMenuItem(value: 'member', child: Text('সাধারণ সদস্য')),
                    DropdownMenuItem(value: 'admin', child: Text('সহ-অ্যাডমিন')),
                  ],
                  onChanged: (val) {
                    if (val != null) setSheetState(() => selectedRole = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            GlassButton(
              text: isSaving ? 'যাচাই করা হচ্ছে...' : 'যুক্ত করুন / আমন্ত্রণ পাঠান',
              isLoading: isSaving,
              icon: Icons.person_add_alt_1_outlined,
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim().replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
                      final pass = passwordCtrl.text.trim();

                      if (name.isEmpty) {
                        setSheetState(() => errorText = 'সদস্যের পূর্ণ নাম দিন');
                        return;
                      }

                      final phoneErr = AuthValidators.validatePhone(phone);
                      if (phoneErr != null) {
                        setSheetState(() => errorText = phoneErr);
                        return;
                      }

                      final passErr = AuthValidators.validatePassword(pass);
                      if (passErr != null) {
                        setSheetState(() => errorText = passErr);
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);

                      setSheetState(() {
                        isSaving = true;
                        errorText = null;
                      });

                      try {
                        final existing = await _datasource.getUserByPhone(phone);
                        if (existing != null) {
                          final existingFamilyId = existing['activeFamilyId']?.toString() ?? '';
                          if (existingFamilyId.isNotEmpty && existingFamilyId != familyId) {
                            final familyMembers = await _datasource.getFamilyMembersOnce(existingFamilyId);
                            if (familyMembers.length > 1) {
                              setSheetState(() {
                                isSaving = false;
                                errorText = 'এই নম্বরের সদস্য ইতিমধ্যে অন্য একটি পরিবারের সক্রিয় অংশ। তাকে যুক্ত করা সম্ভব নয়।';
                              });
                              return;
                            } else {
                              await _datasource.sendFamilyInvitation({
                                'id': 'inv_${DateTime.now().millisecondsSinceEpoch}',
                                'familyId': familyId,
                                'familyName': currentUser?.fullName != null ? '${currentUser!.fullName} পরিবার' : 'আমাদের পরিবার',
                                'fromAdminName': currentUser?.fullName ?? 'এডমিন',
                                'fromAdminPhone': currentUser?.phoneNumber ?? '',
                                'targetPhone': phone,
                                'targetName': existing['fullName'] ?? name,
                                'role': selectedRole,
                                'relation': selectedRelation,
                                'status': 'pending',
                                'createdAt': DateTime.now().toIso8601String(),
                              });

                              if (!mounted) return;
                              navigator.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('ব্যবহারকারী একক পরিবারে আছেন। যোগদানের আমন্ত্রণ পাঠানো হয়েছে!'),
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                              );
                              return;
                            }
                          }
                        }

                        final newUid = 'usr_${DateTime.now().millisecondsSinceEpoch}';

                        await _datasource.saveUser({
                          'uid': newUid,
                          'phoneNumber': phone,
                          'fullName': name,
                          'password': pass,
                          'activeFamilyId': familyId,
                          'joinedFamilyIds': [familyId],
                          'role': selectedRole,
                          'isFamilyOwner': false,
                          'createdAt': DateTime.now().toIso8601String(),
                        });

                        await _datasource.addMemberToFamily(familyId, {
                          'id': newUid,
                          'name': name,
                          'phoneNumber': phone,
                          'role': selectedRole,
                          'relation': selectedRelation,
                          'canUpload': true,
                          'canViewExpenses': true,
                          'canSendPushNotification': selectedRole == 'admin',
                          'joinedAt': DateTime.now().toIso8601String(),
                        });

                        if (!mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('নতুন সদস্য একাউন্ট সফলভাবে তৈরি হয়েছে!'),
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        );
                      } catch (e) {
                        setSheetState(() {
                          isSaving = false;
                          errorText = e.toString().replaceAll('Exception:', '').trim();
                        });
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(String memberPhone, String memberName, String familyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.iosDivider),
        ),
        title: const Text(
          'সদস্য বাদ দিন',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'আপনি কি নিশ্চিতভাবে $memberName-কে পরিবার থেকে বাদ দিতে চান? বাদ দেওয়ার পর তিনি পুনরায় লগইন করলে তার নিজস্ব নতুন পরিবার তৈরি হবে।',
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
              await _datasource.removeMemberFromFamily(familyId, memberPhone);
              if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authUserProvider);
    final familyId = currentUser?.activeFamilyId ?? 'fam_01';
    final isAdmin = currentUser?.isAdmin ?? false;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: 'পরিবারের সদস্য তালিকা',
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add_outlined, color: AppColors.primaryGreen),
              onPressed: _openAddMemberSheet,
            ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _datasource.streamFamilyMembers(familyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen)),
            );
          }

          final members = snapshot.data ?? [];

          if (members.isEmpty) {
            return const Center(
              child: Text(
                'কোনো সদস্য পাওয়া যায়নি',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final role = member['role']?.toString() ?? 'member';
              final memberIsAdmin = role == 'admin' || role == 'owner';
              final memberPhone = member['phoneNumber']?.toString() ?? '';
              final memberName = member['name']?.toString() ?? 'সদস্য';
              final relation = member['relation']?.toString() ?? 'পরিবার সদস্য';
              final isMe = currentUser?.phoneNumber == memberPhone;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.iosDivider),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.cardDarkSecondary,
                      child: Text(
                        memberName.isNotEmpty ? memberName.substring(0, 1) : 'প',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  memberName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDarkSecondary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  memberIsAdmin ? 'এডমিন' : 'সদস্য',
                                  style: TextStyle(
                                    color: memberIsAdmin ? AppColors.primaryGreen : AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                const Text(
                                  '(আপনি)',
                                  style: TextStyle(color: AppColors.primaryGreen, fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$relation • $memberPhone',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin && !isMe)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryRed, size: 20),
                        tooltip: 'পরিবার থেকে বাদ দিন',
                        onPressed: () => _confirmRemoveMember(memberPhone, memberName, familyId),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
