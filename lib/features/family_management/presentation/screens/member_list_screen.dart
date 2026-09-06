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
import '../../../auth/presentation/widgets/otp_verification_sheet.dart';
import '../../data/datasources/family_firestore_datasource.dart';
import '../widgets/edit_member_permissions_sheet.dart';
import 'admin_dashboard_screen.dart';
import '../../../../core/services/firebase_dropdown_service.dart';

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key});

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  final FamilyFirestoreDatasource _datasource = FamilyFirestoreDatasource();
  List<String> get _relationOptions {
    return ref.read(dropdownOptionsProvider).value?.familyRelations ??
        DropdownConfigModel.defaults.familyRelations;
  }

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
                  value: _relationOptions.contains(selectedRelation)
                      ? selectedRelation
                      : _relationOptions.first,
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
              text: isSaving ? 'যাচাই করা হচ্ছে...' : 'ওটিপি পাঠিয়ে সদস্য যুক্ত করুন',
              isLoading: isSaving,
              icon: Icons.verified_user_outlined,
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

                        setSheetState(() => isSaving = false);
                        if (!mounted) return;

                        // Enforce real Firebase SMS OTP verification before adding member
                        final verified = await OtpVerificationSheet.show(
                          context: context,
                          phoneNumber: phone,
                          onVerified: () async {
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
                              'password': pass,
                              'role': selectedRole,
                              'relation': selectedRelation,
                              'canUpload': true,
                              'canViewExpenses': true,
                              'canSendPushNotification': selectedRole == 'admin',
                              'joinedAt': DateTime.now().toIso8601String(),
                            });
                          },
                        );

                        if (verified == true) {
                          if (!mounted) return;
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('সদস্যের নম্বর ওটিপি দিয়ে সফলভাবে যাচাই ও পরিবারে যুক্ত হয়েছে!'),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        final raw = e.toString().replaceAll('Exception:', '').trim();
                        String friendly;
                        if (raw.contains('PERMISSION_DENIED') ||
                            raw.contains('NOT_FOUND') ||
                            raw.contains('unavailable') ||
                            raw.contains('cloud_firestore')) {
                          friendly = 'ক্লাউডে সেভ করা যায়নি! ফায়ারবেস কনসোলে Firestore Database তৈরি ও রুলস সক্রিয় আছে কিনা নিশ্চিত করুন।';
                        } else {
                          friendly = raw;
                        }
                        setSheetState(() {
                          isSaving = false;
                          errorText = friendly;
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

  void _confirmLeaveFamily(List<Map<String, dynamic>> allMembers, String familyId) {
    final currentUser = ref.read(authUserProvider);
    if (currentUser == null) return;
    final myPhone = currentUser.phoneNumber;
    final isOwnerOrAdmin = currentUser.isAdmin || currentUser.isFamilyOwner;

    final otherMembers = allMembers.where((m) => (m['phoneNumber'] ?? '') != myPhone).toList();

    if (isOwnerOrAdmin && otherMembers.isNotEmpty) {
      String selectedNewAdminPhone = otherMembers.first['phoneNumber']?.toString() ?? '';

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
            backgroundColor: AppColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.iosDivider),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                SizedBox(width: 8),
                Text(
                  'এডমিন হস্তান্তর ও ত্যাগ',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'আপনি পরিবারের অ্যাডমিন। পরিবার ত্যাগ করার পূর্বে দায়িত্ব হস্তান্তরের জন্য নতুন একজন অ্যাডমিন নির্বাচন করুন:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.cardDarkSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.iosDivider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedNewAdminPhone,
                      dropdownColor: AppColors.cardDark,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      items: otherMembers.map((m) {
                        final name = m['name']?.toString() ?? 'সদস্য';
                        final rel = m['relation']?.toString() ?? 'সদস্য';
                        final phone = m['phoneNumber']?.toString() ?? '';
                        return DropdownMenuItem(
                          value: phone,
                          child: Text('$name ($rel)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedNewAdminPhone = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('বাতিল', style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  Navigator.pop(dialogCtx);

                  await _datasource.updateMemberPermissionsAndRelation(
                    familyId: familyId,
                    memberPhone: selectedNewAdminPhone,
                    updates: {
                      'role': 'admin',
                      'canAddMembers': true,
                      'canSetAlarms': true,
                      'canSendPushNotification': true,
                      'canViewExpenses': true,
                      'canUpload': true,
                    },
                  );

                  await _datasource.removeMemberFromFamily(familyId, myPhone);
                  await ref.read(authUserProvider.notifier).reloadUser();

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('অ্যাডমিনশিপ হস্তান্তর করে পরিবার ত্যাগ করা হয়েছে।'),
                      backgroundColor: AppColors.primaryRed,
                    ),
                  );
                  navigator.pop();
                },
                child: const Text('হস্তান্তর ও ত্যাগ', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.iosDivider),
        ),
        title: const Text(
          'পরিবার ত্যাগ নিশ্চিতকরণ',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'আপনি কি নিশ্চিতভাবে এই পরিবার ত্যাগ করতে চান? পরিবার ত্যাগ করলে আপনি উন্মুক্ত হবেন এবং অন্য যেকোনো পরিবারের আমন্ত্রণে সাধারণ সদস্য হিসেবে যোগ দিতে পারবেন।',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              Navigator.pop(ctx);

              await _datasource.removeMemberFromFamily(familyId, myPhone);
              await ref.read(authUserProvider.notifier).reloadUser();

              messenger.showSnackBar(
                const SnackBar(
                  content: Text('আপনি পরিবার সফলভাবে ত্যাগ করেছেন।'),
                  backgroundColor: AppColors.primaryRed,
                ),
              );
              navigator.pop();
            },
            child: const Text('পরিবার ত্যাগ করুন', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
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
    final canAdd = isAdmin || (currentUser?.canAddMembers ?? false);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: 'পরিবারের সদস্য তালিকা',
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.shield_outlined, color: AppColors.primaryGreen),
              tooltip: 'অ্যাডমিন ড্যাশবোর্ড',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
          if (canAdd)
            IconButton(
              icon: const Icon(Icons.person_add_outlined, color: AppColors.primaryGreen),
              tooltip: 'নতুন সদস্য যুক্ত করুন',
              onPressed: _openAddMemberSheet,
            ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _datasource.streamFamilyMembers(familyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: members.length + (isAdmin ? 1 : 0),
            itemBuilder: (context, index) {
              if (isAdmin && index == 0) {
                // Admin dashboard banner at top
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primaryGreen, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'অ্যাডমিন কন্ট্রোল সেন্টার',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'সদস্যের সম্পর্ক ও অনুমতি (অ্যালার্ম, পুশ, সদস্য যোগ) নিয়ন্ত্রণ করুন',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                        ),
                        child: const Text('প্যানেল', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }

              final memberIndex = isAdmin ? index - 1 : index;
              final member = members[memberIndex];
              final role = member['role']?.toString() ?? 'member';
              final memberIsAdmin = role == 'admin' || role == 'owner';
              final memberPhone = member['phoneNumber']?.toString() ?? '';
              final memberName = member['name']?.toString() ?? 'সদস্য';
              final relation = member['relation']?.toString() ?? 'পরিবার সদস্য';
              final isMe = currentUser?.phoneNumber == memberPhone;

              final memberCanAdd = memberIsAdmin || member['canAddMembers'] == true;
              final memberCanAlarm = member['canSetAlarms'] == null ? true : member['canSetAlarms'] == true;
              final memberCanPush = memberIsAdmin || member['canSendPushNotification'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isMe ? AppColors.primaryGreen.withValues(alpha: 0.35) : AppColors.iosDivider,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    if (isAdmin) {
                      EditMemberPermissionsSheet.show(
                        context: context,
                        familyId: familyId,
                        member: member,
                        isSelf: isMe,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: memberIsAdmin ? Colors.amber.withValues(alpha: 0.15) : AppColors.cardDarkSecondary,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: memberIsAdmin ? Colors.amber.withValues(alpha: 0.4) : Colors.transparent,
                                          ),
                                        ),
                                        child: Text(
                                          memberIsAdmin ? 'এডমিন' : 'সদস্য',
                                          style: TextStyle(
                                            color: memberIsAdmin ? Colors.amberAccent : AppColors.textSecondary,
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
                            if (isMe)
                              IconButton(
                                icon: const Icon(Icons.logout_rounded, color: AppColors.accentRed, size: 20),
                                tooltip: 'পরিবার ত্যাগ করুন',
                                onPressed: () => _confirmLeaveFamily(members, familyId),
                              ),
                            if (isAdmin) ...[
                              IconButton(
                                icon: const Icon(Icons.tune_outlined, color: AppColors.primaryGreen, size: 20),
                                tooltip: 'অনুমতি ও সম্পর্ক পরিবর্তন',
                                onPressed: () {
                                  EditMemberPermissionsSheet.show(
                                    context: context,
                                    familyId: familyId,
                                    member: member,
                                    isSelf: isMe,
                                  );
                                },
                              ),
                            ],
                            if (isAdmin && !isMe)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryRed, size: 20),
                                tooltip: 'পরিবার থেকে বাদ দিন',
                                onPressed: () => _confirmRemoveMember(memberPhone, memberName, familyId),
                              ),
                          ],
                        ),
                        if (isAdmin) ...[
                          const Divider(color: AppColors.iosDivider, height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildMiniBadge('সদস্য যোগ', memberCanAdd),
                              _buildMiniBadge('অ্যালার্ম', memberCanAlarm),
                              _buildMiniBadge('পুশ বার্তা', memberCanPush),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMiniBadge(String label, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: enabled ? AppColors.primaryGreen.withValues(alpha: 0.12) : AppColors.cardDarkSecondary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: enabled ? AppColors.primaryGreen.withValues(alpha: 0.3) : AppColors.iosDivider.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '$label: ${enabled ? 'অন' : 'অফ'}',
        style: TextStyle(
          color: enabled ? AppColors.primaryGreen : AppColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
