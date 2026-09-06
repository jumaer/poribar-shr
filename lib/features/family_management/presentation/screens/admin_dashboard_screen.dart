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
import '../../../namaj/presentation/screens/namaj_alarm_screen.dart';
import '../../../amol/presentation/screens/amol_screen.dart';
import '../../../../core/services/firebase_dropdown_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final FamilyFirestoreDatasource _datasource = FamilyFirestoreDatasource();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<String> get _relationOptions {
    return ref.read(dropdownOptionsProvider).value?.familyRelations ??
        DropdownConfigModel.defaults.familyRelations;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddMemberSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRelation = _relationOptions.first;
    String selectedRole = 'member';
    bool canAddOthers = false;
    bool canSetAlarm = true;
    bool canSendPush = false;
    bool isSaving = false;
    String? errorText;

    final currentUser = ref.read(authUserProvider);
    final familyId = currentUser?.activeFamilyId ?? 'fam_01';

    GlobalBottomSheet.show(
      context: context,
      title: 'নতুন সদস্য যুক্ত ও অনুমতি নির্ধারণ',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) => SingleChildScrollView(
          child: Column(
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
                label: 'সদস্যের পাসওয়ার্ড (৮+ অক্ষর)',
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
                      if (val != null) {
                        setSheetState(() {
                          selectedRole = val;
                          if (val == 'admin') {
                            canAddOthers = true;
                            canSetAlarm = true;
                            canSendPush = true;
                          }
                        });
                      }
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
                                  errorText = 'এই নম্বরের সদস্য ইতিমধ্যে অন্য একটি পরিবারের সক্রিয় অংশ।';
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

                          // Real Firebase SMS OTP verification
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
                                'canAddMembers': selectedRole == 'admin' ? true : canAddOthers,
                                'canSetAlarms': canSetAlarm,
                                'canSendPushNotification': selectedRole == 'admin' ? true : canSendPush,
                                'canViewExpenses': true,
                                'canUpload': true,
                                'createdAt': DateTime.now().toIso8601String(),
                              });

                              await _datasource.addMemberToFamily(familyId, {
                                'id': newUid,
                                'name': name,
                                'phoneNumber': phone,
                                'password': pass,
                                'role': selectedRole,
                                'relation': selectedRelation,
                                'canAddMembers': selectedRole == 'admin' ? true : canAddOthers,
                                'canSetAlarms': canSetAlarm,
                                'canSendPushNotification': selectedRole == 'admin' ? true : canSendPush,
                                'canUpload': true,
                                'canViewExpenses': true,
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
                          setSheetState(() {
                            isSaving = false;
                            errorText = 'ত্রুটি ঘটেছে! আবার চেষ্টা করুন।';
                          });
                        }
                      },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.iosDivider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionChip({
    required String label,
    required bool enabled,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 6, top: 4),
      decoration: BoxDecoration(
        color: enabled ? AppColors.primaryGreen.withValues(alpha: 0.15) : AppColors.cardDarkSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: enabled ? AppColors.primaryGreen.withValues(alpha: 0.4) : AppColors.iosDivider.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: enabled ? AppColors.primaryGreen : AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: enabled ? AppColors.primaryGreen : AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
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
        title: 'অ্যাডমিন ড্যাশবোর্ড ও অনুমতি',
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.primaryGreen),
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
          final filteredMembers = _searchQuery.isEmpty
              ? members
              : members.where((m) {
                  final name = (m['name'] ?? '').toString().toLowerCase();
                  final phone = (m['phoneNumber'] ?? '').toString();
                  final relation = (m['relation'] ?? '').toString().toLowerCase();
                  final q = _searchQuery.toLowerCase();
                  return name.contains(q) || phone.contains(q) || relation.contains(q);
                }).toList();

          final totalCount = members.length;
          final adminCount = members.where((m) => m['role'] == 'admin' || m['role'] == 'owner').length;
          final regularMemberCount = totalCount - adminCount;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Top Stats Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'মোট সদস্য',
                      value: '$totalCount জন',
                      icon: Icons.groups_outlined,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      title: 'সহ-অ্যাডমিন',
                      value: '$adminCount জন',
                      icon: Icons.shield_outlined,
                      color: Colors.amberAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'সাধারণ সদস্য',
                      value: '$regularMemberCount জন',
                      icon: Icons.person_outline,
                      color: Colors.lightBlueAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _openAddMemberSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add_circle_outline, color: AppColors.primaryGreen, size: 22),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '+ সদস্য যোগ করুন',
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick Module Links for Admin
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NamajAlarmScreen()),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.mosque_outlined, color: AppColors.accentGreen, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'নামাজ ও অ্যালার্ম',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AmolScreen()),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.volunteer_activism_outlined, color: Colors.purpleAccent, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'আমল ও তসবিহ',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Field
              GlassTextField(
                controller: _searchCtrl,
                label: 'সদস্য খুঁজুন',
                hint: 'নাম, সম্পর্ক বা মোবাইল নম্বর দিয়ে খুঁজুন',
                prefixIcon: Icons.search,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'পরিবারের সদস্য তালিকা ও অনুমতিসমূহ',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '(${filteredMembers.length} জন)',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (filteredMembers.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: const Text(
                    'কোনো সদস্য পাওয়া যায়নি',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...filteredMembers.map((member) {
                  final role = member['role']?.toString() ?? 'member';
                  final memberIsAdmin = role == 'admin' || role == 'owner';
                  final memberPhone = member['phoneNumber']?.toString() ?? '';
                  final memberName = member['name']?.toString() ?? 'সদস্য';
                  final relation = member['relation']?.toString() ?? 'সদস্য';
                  final isMe = currentUser?.phoneNumber == memberPhone;

                  final canAdd = memberIsAdmin || member['canAddMembers'] == true;
                  final canAlarm = member['canSetAlarms'] == null ? true : member['canSetAlarms'] == true;
                  final canPush = memberIsAdmin || member['canSendPushNotification'] == true;
                  final canViewExp = member['canViewExpenses'] == null ? true : member['canViewExpenses'] == true;
                  final canUp = member['canUpload'] == null ? true : member['canUpload'] == true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isMe ? AppColors.primaryGreen.withValues(alpha: 0.4) : AppColors.iosDivider,
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
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
                                      const SizedBox(height: 2),
                                      Text(
                                        'সম্পর্ক: $relation • $memberPhone',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.tune_outlined,
                                  color: AppColors.primaryGreen,
                                  size: 20,
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.iosDivider, height: 16),

                            // Permissions Chips Row
                            Wrap(
                              children: [
                                _buildPermissionChip(
                                  label: 'সদস্য যোগ',
                                  enabled: canAdd,
                                  icon: Icons.person_add_alt_1_outlined,
                                ),
                                _buildPermissionChip(
                                  label: 'অ্যালার্ম সেট',
                                  enabled: canAlarm,
                                  icon: Icons.alarm_outlined,
                                ),
                                _buildPermissionChip(
                                  label: 'পুশ বার্তা',
                                  enabled: canPush,
                                  icon: Icons.notifications_active_outlined,
                                ),
                                _buildPermissionChip(
                                  label: 'হিসাব দেখা',
                                  enabled: canViewExp,
                                  icon: Icons.visibility_outlined,
                                ),
                                _buildPermissionChip(
                                  label: 'রসিদ আপলোড',
                                  enabled: canUp,
                                  icon: Icons.cloud_upload_outlined,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
