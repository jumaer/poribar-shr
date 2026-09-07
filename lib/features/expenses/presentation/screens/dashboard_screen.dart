import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/services/firestore_image_service.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../camera/presentation/screens/custom_camera_screen.dart';
import '../../../direct_chat/presentation/screens/family_chat_screen.dart';
import '../../../family_management/presentation/screens/member_list_screen.dart';
import '../../../family_management/presentation/screens/admin_dashboard_screen.dart';
import '../../../notifications/presentation/screens/notification_screen.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_provider.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/add_reminder_sheet.dart';
import '../widgets/advanced_expense_graphs.dart';
import 'comparative_analytics_screen.dart';
import '../../../private_vault/presentation/screens/private_vault_screen.dart';
import '../../../family_management/presentation/widgets/invitation_banner_widget.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/widgets/global_delete_dialog.dart';
import '../widgets/edit_expense_sheet.dart';
import 'dart:async';
import '../../../splash/presentation/widgets/update_splash_dialog.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/network_status_service.dart';
import '../../../../core/services/sos_shake_service.dart';
import '../../../../core/widgets/sos_alert_dialog.dart';
import '../../../namaj/presentation/screens/namaj_alarm_screen.dart';
import '../../../amol/presentation/screens/amol_screen.dart';
import '../widgets/salary_celebration_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final List<Map<String, String>> _problemList = [];
  final TextEditingController _problemInputCtrl = TextEditingController();
  StreamSubscription<SosTriggerEvent>? _sosSub;

  @override
  void initState() {
    super.initState();
    _sosSub = SosShakeService().onSosTriggered.listen((event) {
      if (mounted) {
        SosAlertDialog.show(context, event);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authUserProvider);
      if (user != null) {
        final id = user.phoneNumber.isNotEmpty ? user.phoneNumber : user.activeFamilyId;
        NotificationService().initializeNotificationEngine(userIdOrPhone: id);
        if (user.activeFamilyId.isNotEmpty) {
          NotificationService().listenToFamilyNotifications(user.activeFamilyId, myPhone: user.phoneNumber);
          SosShakeService().startListening(
            familyId: user.activeFamilyId,
            userName: user.fullName,
            userPhone: user.phoneNumber,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _sosSub?.cancel();
    _problemInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshDashboardData() async {
    await ref.read(networkStatusProvider.notifier).refresh();
    await ref.read(authUserProvider.notifier).reloadUser();
    ref.invalidate(expenseListProvider);
    ref.invalidate(monthlyIncomeTotalProvider);
    ref.invalidate(monthlyExpenseTotalProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সার্ভার থেকে সমস্ত তথ্য রিফ্রেশ ও সিঙ্ক করা হয়েছে!'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _openAddExpense() {
    final isOnline = ref.read(networkStatusProvider);
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ আপনি অফলাইনে আছেন! নতুন কোনো এন্ট্রি সার্ভারে সংরক্ষণ করা সম্ভব নয়। দয়া করে ইন্টারনেট সংযোগ চালু করুন।'),
          backgroundColor: AppColors.primaryRed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    AddExpenseSheet.show(context);
  }

  void _showProblemListDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'পরিবারের জরুরি তালিকা',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_problemList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'কোন সমস্যা বা জরুরি কাজ তালিকাভুক্ত নেই',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ..._problemList.map(
                    (item) => _buildProblemItem(
                      item['title'] ?? '',
                      item['priority'] ?? 'জরুরি',
                      AppColors.primaryRed,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _problemInputCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'জরুরি কাজের বিবরণ...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.cardDarkSecondary,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.iosDivider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.iosDivider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primaryGreen),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primaryGreen, size: 28),
                      onPressed: () {
                        final text = _problemInputCtrl.text.trim();
                        if (text.isNotEmpty) {
                          setDialogState(() {
                            _problemList.add({'title': text, 'priority': 'জরুরি'});
                          });
                          _problemInputCtrl.clear();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageZoomDialog(String base64Image, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.iosDivider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'রসিদ: $title',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FirestoreImageService.buildFirestoreImage(
                base64Data: base64Image,
                width: 260,
                height: 320,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProblemItem(String title, String priority, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDarkSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.iosDivider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              priority,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedLedgerCategoryProvider);
    final allExpenses = ref.watch(expenseListProvider);
    final filteredExpenses = ref.watch(currentFilteredExpensesProvider);
    final totalIncome = ref.watch(monthlyIncomeTotalProvider);
    final totalExpense = ref.watch(monthlyExpenseTotalProvider);
    final totalSavings = totalIncome - totalExpense;
    final totalLoanGiven = ref.watch(totalLoanGivenProvider);
    final totalLoanTaken = ref.watch(totalLoanTakenProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final user = ref.watch(authUserProvider);

    final personalSum = allExpenses
        .where((e) => e.category == LedgerCategory.personal && e.type == TransactionType.expense)
        .fold(0.0, (sum, i) => sum + i.amount);

    final familySum = allExpenses
        .where((e) => e.category == LedgerCategory.family && e.type == TransactionType.expense)
        .fold(0.0, (sum, i) => sum + i.amount);

    final budgetProgress = totalIncome > 0 ? (totalExpense / totalIncome).clamp(0.0, 1.0) : 0.0;

    final isOnline = ref.watch(networkStatusProvider);

    return GlassScaffold(
      drawer: _buildAppDrawer(context, user, currentLang, l10n),
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        backgroundColor: AppColors.cardDark,
        onRefresh: _refreshDashboardData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(user, currentLang, isOnline, l10n),
                    if (!isOnline) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.darkRed,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryRed),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.translate('offline_warning'),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 12),
                    const InvitationBannerWidget(),
                    const SizedBox(height: 6),
                    _buildSosShakeBanner(l10n),
                    const SizedBox(height: 6),
                    _buildFinancialSummaryCard(
                      totalSavings,
                      totalIncome,
                      totalExpense,
                      totalLoanGiven,
                      totalLoanTaken,
                      budgetProgress,
                      l10n,
                    ),
                    const SizedBox(height: 12),
                    _buildSalarySpotlightBanner(allExpenses, l10n),
                    _buildNoticeBanner(allExpenses, l10n),
                    const SizedBox(height: 16),
                    _buildSegmentedControl(selectedCategory, personalSum, familySum, l10n),
                    const SizedBox(height: 16),
                    _buildQuickActionsRow(l10n),
                    const SizedBox(height: 20),
                    const AdvancedExpenseGraphsWidget(),
                    const SizedBox(height: 20),
                    _buildRecentTransactionsHeader(filteredExpenses.length, l10n),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (filteredExpenses.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 44),
                        const SizedBox(height: 10),
                        Text(
                          l10n.translate('no_entries_found'),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredExpenses[index];
                      return _buildTransactionItem(item, index == filteredExpenses.length - 1, l10n);
                    },
                    childCount: filteredExpenses.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpense,
        backgroundColor: isOnline ? AppColors.primaryGreen : AppColors.cardDarkSecondary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tooltip: isOnline ? l10n.translate('add_expense_fab') : l10n.translate('offline_fab_disabled'),
        child: Icon(Icons.add, color: isOnline ? Colors.black : AppColors.textSecondary, size: 28),
      ),
    );
  }

  void _triggerEmergencySos() {
    final user = ref.read(authUserProvider);
    if (user != null) {
      SosShakeService().triggerEmergencySos(
        familyId: user.activeFamilyId,
        userName: user.fullName,
        userPhone: user.phoneNumber,
      );
    }
  }

  void _confirmLogout(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.translate('logout'), style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.translate('logout_confirm'), style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel'), style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final navigator = Navigator.of(context);
              await ref.read(authUserProvider.notifier).logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              l10n.translate('logout'),
              style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context, dynamic user, AppLanguage currentLang, AppLocalizations l10n) {
    final isAdmin = user?.isAdmin ?? false;
    final userName = user?.fullName != null && user!.fullName.isNotEmpty ? user.fullName : 'ব্যবহারকারী';
    final userPhone = user?.phoneNumber ?? '';

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.96),
          border: const Border(
            right: BorderSide(color: AppColors.iosDivider, width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: const Border(
                    bottom: BorderSide(color: AppColors.iosDivider),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryGreen, Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'SRH',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
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
                                  userName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.5)),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(color: AppColors.primaryGreen, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userPhone,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.dashboard_outlined,
                      title: l10n.translate('dashboard'),
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      icon: Icons.people_outline_rounded,
                      title: l10n.translate('member_list'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberListScreen()));
                      },
                    ),
                    if (isAdmin)
                      _buildDrawerItem(
                        icon: Icons.admin_panel_settings_outlined,
                        title: l10n.translate('admin_panel'),
                        badgeColor: AppColors.primaryGreen,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                        },
                      ),
                    _buildDrawerItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: l10n.translate('messages'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyChatScreen()));
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.notifications_none_rounded,
                      title: l10n.translate('notification'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.camera_alt_outlined,
                      title: l10n.translate('receipt_camera'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomCameraScreen()));
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.insights_rounded,
                      title: l10n.translate('analytics'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ComparativeAnalyticsScreen()));
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.lock_outline_rounded,
                      title: l10n.translate('private_vault'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivateVaultScreen()));
                      },
                    ),
                    const Divider(color: AppColors.iosDivider, height: 18),
                    _buildDrawerItem(
                      icon: Icons.mosque_outlined,
                      title: l10n.translate('namaj_alarm_title'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NamajAlarmScreen()));
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.fingerprint_rounded,
                      title: l10n.translate('amol_tasbih_title'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AmolScreen()));
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.alarm_outlined,
                      title: l10n.translate('monthly_alarm'),
                      onTap: () {
                        Navigator.pop(context);
                        final currentUser = ref.read(authUserProvider);
                        final canSet = (currentUser?.isAdmin ?? false) || (currentUser?.canSetAlarms ?? false);
                        if (!canSet) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.translate('alarm_permission_denied')),
                              backgroundColor: AppColors.primaryRed,
                            ),
                          );
                          return;
                        }
                        AddReminderSheet.show(context);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.playlist_add_check_rounded,
                      title: l10n.translate('emergency_list_title'),
                      onTap: () {
                        Navigator.pop(context);
                        _showProblemListDialog();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.palette_outlined,
                      title: l10n.translate('splash_img_title'),
                      onTap: () {
                        Navigator.pop(context);
                        UpdateSplashDialog.show(context);
                      },
                    ),
                    const Divider(color: AppColors.iosDivider, height: 18),
                    _buildDrawerItem(
                      icon: Icons.language_rounded,
                      title: currentLang == AppLanguage.bangla ? 'English এ পরিবর্তন' : 'Change to বাংলা',
                      trailing: Text(
                        currentLang == AppLanguage.bangla ? 'BN' : 'EN',
                        style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        ref.read(appLanguageProvider.notifier).toggleLanguage();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: l10n.translate('logout'),
                      textColor: AppColors.primaryRed,
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        Navigator.pop(context);
                        _confirmLogout(l10n);
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'SRH • স্মার্ট যৌথ পরিবার',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    Color? badgeColor,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      dense: true,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
    );
  }

  Widget _buildHeader(dynamic user, AppLanguage currentLang, bool isOnline, AppLocalizations l10n) {
    final familyDisplayName = user?.fullName != null && user!.fullName.isNotEmpty
        ? '${user.fullName} ${l10n.translate("family_label")}'
        : l10n.translate('our_family');

    return Row(
      children: [
        Builder(
          builder: (scaffoldCtx) => Container(
            margin: const EdgeInsets.only(right: 8),
            child: _buildCircleIconButton(
              icon: Icons.menu_rounded,
              tooltip: 'মেনু ড্রয়ার',
              onTap: () => Scaffold.of(scaffoldCtx).openDrawer(),
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MemberListScreen()),
                ),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.cardDarkSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.iosDivider),
                  ),
                  child: const Icon(Icons.family_restroom, color: AppColors.primaryGreen, size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.6)),
                          ),
                          child: const Text(
                            'SRH',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            familyDisplayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: AppColors.primaryGreen, size: 14),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isOnline ? AppColors.primaryGreen : AppColors.primaryRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${isOnline ? l10n.translate("online") : l10n.translate("offline")} • ${currentLang == AppLanguage.bangla ? "বাংলা" : "English"}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCircleIconButton(
                  icon: Icons.emergency_share,
                  iconColor: AppColors.primaryRed,
                  tooltip: l10n.translate('sos_banner_title'),
                  onTap: _triggerEmergencySos,
                ),
                const SizedBox(width: 6),
                _buildCircleIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: l10n.translate('refresh'),
                  onTap: _refreshDashboardData,
                ),
                const SizedBox(width: 6),
                _buildCircleIconButton(
                  icon: Icons.notifications_none_rounded,
                  tooltip: l10n.translate('notification'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  ),
                ),
                const SizedBox(width: 6),
                _buildCircleIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: l10n.translate('messages'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FamilyChatScreen()),
                  ),
                ),
                const SizedBox(width: 6),
                _buildCircleIconButton(
                  icon: Icons.logout_rounded,
                  tooltip: l10n.translate('logout'),
                  onTap: () => _confirmLogout(l10n),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showDot = false,
    String? tooltip,
    Color? iconColor,
  }) {
    final btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.iosDivider),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 20),
            if (showDot)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: btn);
    }
    return btn;
  }

  Widget _buildFinancialSummaryCard(
    double totalSavings,
    double totalIncome,
    double totalExpense,
    double totalLoanGiven,
    double totalLoanTaken,
    double budgetProgress,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.iosDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('total_savings_remaining'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardDarkSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(budgetProgress * 100).toStringAsFixed(0)}% ${l10n.translate("spent_percentage")}',
                  style: TextStyle(
                    color: budgetProgress > 0.85 ? AppColors.primaryRed : AppColors.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '৳ ${totalSavings.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: budgetProgress,
              minHeight: 5,
              backgroundColor: AppColors.cardDarkSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(
                budgetProgress > 0.85 ? AppColors.primaryRed : AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.darkGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_downward, color: AppColors.primaryGreen, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.translate('total_income'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          Text(
                            '৳ ${totalIncome.toStringAsFixed(0)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.iosDivider),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.darkRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_upward, color: AppColors.primaryRed, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.translate('total_expense'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          Text(
                            '৳ ${totalExpense.toStringAsFixed(0)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (totalLoanGiven > 0 || totalLoanTaken > 0) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: AppColors.iosDivider),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.call_made_rounded, color: Colors.amber, size: 15),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.translate('loan_given'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            Text(
                              '৳ ${totalLoanGiven.toStringAsFixed(0)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: AppColors.iosDivider),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.call_received_rounded, color: Colors.deepOrange, size: 15),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.translate('loan_taken'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            Text(
                              '৳ ${totalLoanTaken.toStringAsFixed(0)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalarySpotlightBanner(List<ExpenseEntity> allExpenses, AppLocalizations l10n) {
    final salaryEntries = allExpenses.where((e) =>
        e.type == TransactionType.income &&
        (e.purpose.toLowerCase().contains('বেতন') ||
            e.purpose.toLowerCase().contains('salary'))).toList();

    if (salaryEntries.isEmpty) return const SizedBox.shrink();

    final latestSalary = salaryEntries.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.18),
            AppColors.primaryGreen.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded, color: Colors.amber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.translate('salary_received'),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.translate('current_month'),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${latestSalary.recordedByUserName}: ৳ ${latestSalary.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              SalaryCelebrationDialog.show(
                context,
                amount: latestSalary.amount,
                userName: latestSalary.recordedByUserName,
                date: latestSalary.date,
                slipImageBase64: latestSalary.imageUrl,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
              ),
              child: Text(
                l10n.translate('budget_distribution'),
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBanner(List<ExpenseEntity> allExpenses, AppLocalizations l10n) {
    final noticeText = allExpenses.isNotEmpty
        ? '${l10n.translate("recent_prefix")}: ${allExpenses.first.purpose} (৳ ${allExpenses.first.amount.toStringAsFixed(0)})'
        : l10n.translate('welcome_family_banner');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDarkSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.iosDivider),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: AppColors.primaryGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              noticeText,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosShakeBanner(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glassRedTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vibration_rounded, color: AppColors.primaryRed, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('sos_banner_title'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.translate('sos_banner_desc'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _triggerEmergencySos,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.6)),
              ),
              child: Text(
                l10n.translate('sos_test_btn'),
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(
    LedgerCategory selectedCategory,
    double personalSum,
    double familySum,
    dynamic l10n,
  ) {
    final isPersonal = selectedCategory == LedgerCategory.personal;
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.iosDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => ref
                  .read(selectedLedgerCategoryProvider.notifier)
                  .setCategory(LedgerCategory.personal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: isPersonal
                      ? const LinearGradient(
                          colors: [
                            AppColors.primaryGreen,
                            Color(0xFF059669),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isPersonal ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isPersonal
                      ? [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: isPersonal ? Colors.black : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${l10n.translate('my_tab')} (৳ ${personalSum.toStringAsFixed(0)})',
                        style: TextStyle(
                          color: isPersonal ? Colors.black : AppColors.textSecondary,
                          fontWeight: isPersonal ? FontWeight.w800 : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => ref
                  .read(selectedLedgerCategoryProvider.notifier)
                  .setCategory(LedgerCategory.family),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: !isPersonal
                      ? const LinearGradient(
                          colors: [
                            AppColors.primaryGreen,
                            Color(0xFF059669),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: !isPersonal ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: !isPersonal
                      ? [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_rounded,
                        size: 16,
                        color: !isPersonal ? Colors.black : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${l10n.translate('family_tab')} (৳ ${familySum.toStringAsFixed(0)})',
                        style: TextStyle(
                          color: !isPersonal ? Colors.black : AppColors.textSecondary,
                          fontWeight: !isPersonal ? FontWeight.w800 : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(AppLocalizations l10n) {
    final user = ref.watch(authUserProvider);
    final isAdmin = user?.isAdmin ?? false;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (isAdmin) ...[
            _buildQuickActionButton(
              icon: Icons.shield_outlined,
              label: l10n.translate('admin_panel'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
            const SizedBox(width: 10),
          ],
          _buildQuickActionButton(
            icon: Icons.camera_alt_outlined,
            label: l10n.translate('receipt_camera'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
            ),
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.bar_chart_rounded,
            label: l10n.translate('analytics'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComparativeAnalyticsScreen()),
            ),
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.lock_outline_rounded,
            label: l10n.translate('private_vault'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivateVaultScreen()),
            ),
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.people_alt_outlined,
            label: l10n.translate('member_list'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemberListScreen()),
            ),
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.alarm_outlined,
            label: l10n.translate('monthly_alarm'),
            onTap: () {
              final currentUser = ref.read(authUserProvider);
              final canSet = (currentUser?.isAdmin ?? false) || (currentUser?.canSetAlarms ?? false);
              if (!canSet) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.translate('alarm_permission_denied')),
                    backgroundColor: AppColors.primaryRed,
                  ),
                );
                return;
              }
              AddReminderSheet.show(context);
            },
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.mosque_outlined,
            label: l10n.translate('namaj_alarm_title'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NamajAlarmScreen()),
            ),
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.fingerprint_rounded,
            label: l10n.translate('amol_tasbih_title'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AmolScreen()),
            ),
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.checklist_rounded,
            label: l10n.translate('emergency_list_title'),
            onTap: _showProblemListDialog,
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.palette_outlined,
            label: l10n.translate('splash_img_title'),
            onTap: () => UpdateSplashDialog.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.iosDivider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsHeader(int count, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              l10n.translate('recent_transactions'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cardDarkSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionItem(ExpenseEntity item, bool isLast, AppLocalizations l10n) {
    final isExpense = item.type == TransactionType.expense;
    final isIncome = item.type == TransactionType.income;
    final isSavings = item.type == TransactionType.savings;
    final isLoanGiven = item.type == TransactionType.loanGiven;

    Color badgeBg;
    Color badgeColor;
    IconData badgeIcon;
    String sign;
    Color amountColor;
    String typeLabel;

    if (isExpense) {
      badgeBg = AppColors.darkRed;
      badgeColor = AppColors.primaryRed;
      badgeIcon = Icons.shopping_bag_outlined;
      sign = '-';
      amountColor = AppColors.textPrimary;
      typeLabel = l10n.translate('expense');
    } else if (isIncome) {
      badgeBg = AppColors.darkGreen;
      badgeColor = AppColors.primaryGreen;
      badgeIcon = Icons.account_balance_wallet_outlined;
      sign = '+';
      amountColor = AppColors.primaryGreen;
      typeLabel = l10n.translate('income');
    } else if (isSavings) {
      badgeBg = Colors.teal.withValues(alpha: 0.2);
      badgeColor = Colors.tealAccent;
      badgeIcon = Icons.savings_outlined;
      sign = '•';
      amountColor = Colors.tealAccent;
      typeLabel = l10n.translate('savings');
    } else if (isLoanGiven) {
      badgeBg = Colors.amber.withValues(alpha: 0.2);
      badgeColor = Colors.amber;
      badgeIcon = Icons.call_made_rounded;
      sign = '→';
      amountColor = Colors.amber;
      typeLabel = l10n.translate('loan_given');
    } else {
      badgeBg = Colors.deepOrange.withValues(alpha: 0.2);
      badgeColor = Colors.deepOrangeAccent;
      badgeIcon = Icons.call_received_rounded;
      sign = '←';
      amountColor = Colors.deepOrangeAccent;
      typeLabel = l10n.translate('loan_taken');
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await GlobalDeleteDialog.show(
          context: context,
          title: l10n.translate('delete_transaction_title'),
          message: l10n.translate('delete_transaction_msg'),
          itemName: item.purpose,
          itemAmount: '৳ ${item.amount.toStringAsFixed(0)}',
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.primaryRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(expenseListProvider.notifier).deleteExpense(item.id, item.familyId);
      },
      child: InkWell(
        onTap: () => EditExpenseSheet.show(context, expense: item),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.iosDivider),
          ),
          child: Row(
            children: [
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                GestureDetector(
                  onTap: () => _showImageZoomDialog(item.imageUrl!, item.purpose),
                  child: FirestoreImageService.buildFirestoreImage(
                    base64Data: item.imageUrl,
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    badgeIcon,
                    color: badgeColor,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.purpose,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.recordedByUserName} • $typeLabel • ${item.category == LedgerCategory.personal ? l10n.translate("personal") : l10n.translate("family")}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign ৳ ${item.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
