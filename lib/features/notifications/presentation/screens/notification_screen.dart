import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firestore_image_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../family_management/data/datasources/family_firestore_datasource.dart';
import 'send_custom_push_sheet.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FamilyFirestoreDatasource _datasource = FamilyFirestoreDatasource();
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFcmToken();
  }

  Future<void> _loadFcmToken() async {
    final token = NotificationService().cachedFcmToken;
    if (token != null) {
      setState(() => _fcmToken = token);
    } else {
      final user = ref.read(authUserProvider);
      await NotificationService().initializeNotificationEngine(
        userIdOrPhone: user?.phoneNumber ?? user?.uid,
      );
      if (mounted) {
        setState(() => _fcmToken = NotificationService().cachedFcmToken);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openSendCustomPush() async {
    final currentUser = ref.read(authUserProvider);
    final familyId = currentUser?.activeFamilyId ?? '';

    List<String> memberNames = ['সকল সদস্য'];
    if (familyId.isNotEmpty) {
      try {
        final members = await _datasource.getFamilyMembersOnce(familyId);
        for (final m in members) {
          final name = m['name']?.toString() ?? 'সদস্য';
          final relation = m['relation']?.toString() ?? 'সম্পর্ক';
          memberNames.add('$name ($relation)');
        }
      } catch (_) {}
    }

    if (mounted) {
      SendCustomPushSheet.show(
        context: context,
        familyMembers: memberNames,
        canSend: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: 'নোটিফিকেশন সেন্টার',
        actions: [
          IconButton(
            icon: const Icon(Icons.send_rounded, color: AppColors.accentGreen, size: 20),
            tooltip: 'সরাসরি পুশ পাঠান',
            onPressed: _openSendCustomPush,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.accentGreen,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accentGreen,
          tabs: const [
            Tab(text: 'বার্তা'),
            Tab(text: 'অফার'),
            Tab(text: 'বকেয়া পরিশোধ'),
            Tab(text: 'কার্যক্রম'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Firebase FCM Token Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done_outlined, color: AppColors.accentGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Firebase FCM ডিভাইস টোকেন:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fcmToken != null
                            ? '${_fcmToken!.substring(0, _fcmToken!.length > 25 ? 25 : _fcmToken!.length)}...'
                            : 'টোকেন লোড হচ্ছে / ফায়ারবেস সিংক...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_fcmToken != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: AppColors.accentGreen),
                    tooltip: 'টোকেন কপি করুন',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _fcmToken!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Firebase FCM টোকেন ক্লিপবোর্ডে কপি করা হয়েছে!'),
                          backgroundColor: AppColors.primaryGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppNotificationItem>>(
              stream: NotificationService().notificationStream,
              initialData: NotificationService().currentNotifications,
              builder: (context, snapshot) {
                final all = snapshot.data ?? [];

                final messages = all.where((n) => n.tab == NotificationTabType.messages).toList();
                final offers = all.where((n) => n.tab == NotificationTabType.offers).toList();
                final due = all.where((n) => n.tab == NotificationTabType.paymentsDue).toList();
                final activity = all.where((n) => n.tab == NotificationTabType.activity).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationList(messages),
                    _buildNotificationList(offers),
                    _buildNotificationList(due),
                    _buildNotificationList(activity),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<AppNotificationItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'কোনো নোটিফিকেশন নেই',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.iosDivider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          item.time,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.iosDivider),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: FirestoreImageService.buildFirestoreImage(
                                        base64Data: item.imageUrl,
                                        width: MediaQuery.of(context).size.width * 0.8,
                                        height: 320,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text('ভাউচার / রসিদ ছবি', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 34,
                                height: 34,
                                child: FirestoreImageService.buildFirestoreImage(
                                  base64Data: item.imageUrl,
                                  width: 34,
                                  height: 34,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'সংযুক্ত রসিদ দেখুন (ট্যাপ)',
                                style: TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (item.senderName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'প্রেরক: ${item.senderName}',
                        style: const TextStyle(color: AppColors.accentGreen, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
