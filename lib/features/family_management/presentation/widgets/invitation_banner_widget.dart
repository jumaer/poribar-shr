import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/family_firestore_datasource.dart';

class InvitationBannerWidget extends ConsumerStatefulWidget {
  const InvitationBannerWidget({super.key});

  @override
  ConsumerState<InvitationBannerWidget> createState() => _InvitationBannerWidgetState();
}

class _InvitationBannerWidgetState extends ConsumerState<InvitationBannerWidget> {
  final FamilyFirestoreDatasource _datasource = FamilyFirestoreDatasource();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authUserProvider);
    if (currentUser == null || currentUser.phoneNumber.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _datasource.streamPendingInvitations(currentUser.phoneNumber),
      builder: (context, snapshot) {
        final invitations = snapshot.data ?? [];
        if (invitations.isEmpty) {
          return const SizedBox.shrink();
        }

        final invite = invitations.first;
        final inviteId = invite['id']?.toString() ?? '';
        final familyName = invite['familyName']?.toString() ?? 'একটি পরিবার';
        final fromAdmin = invite['fromAdminName']?.toString() ?? 'পরিবার এডমিন';
        final newFamilyId = invite['familyId']?.toString() ?? '';
        final role = invite['role']?.toString() ?? 'member';
        final relation = invite['relation']?.toString() ?? 'সদস্য';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDarkSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryGreen),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.darkGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.mail_outline_rounded, color: AppColors.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'পরিবারে যোগদানের নতুন আমন্ত্রণ!',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$fromAdmin আপনাকে "$familyName"-এ $relation হিসেবে যোগদানের অনুরোধ জানিয়েছেন। গ্রহণ করলে আপনি এই পরিবারের সদস্য হবেন।',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () async {
                              setState(() => _isProcessing = true);
                              try {
                                await _datasource.acceptFamilyInvitation(
                                  inviteId: inviteId,
                                  newFamilyId: newFamilyId,
                                  memberData: {
                                    'id': currentUser.uid,
                                    'name': currentUser.fullName,
                                    'phoneNumber': currentUser.phoneNumber,
                                    'role': role,
                                    'relation': relation,
                                    'photoUrl': currentUser.photoUrl,
                                    'joinedAt': DateTime.now().toIso8601String(),
                                  },
                                );
                                await ref.read(authUserProvider.notifier).reloadUser();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('আপনি সফলভাবে $familyName-এ যুক্ত হয়েছেন!'),
                                      backgroundColor: AppColors.primaryGreen,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('আমন্ত্রণ গ্রহণ করা সম্ভব হয়নি: $e'),
                                      backgroundColor: AppColors.primaryRed,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isProcessing = false);
                              }
                            },
                      child: const Text('গ্রহণ করুন', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryRed,
                        side: const BorderSide(color: AppColors.primaryRed),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () async {
                              setState(() => _isProcessing = true);
                              try {
                                await _datasource.rejectFamilyInvitation(inviteId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('আমন্ত্রণ প্রত্যাখ্যান করা হয়েছে।'),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isProcessing = false);
                              }
                            },
                      child: const Text('প্রত্যাখ্যান করুন'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
