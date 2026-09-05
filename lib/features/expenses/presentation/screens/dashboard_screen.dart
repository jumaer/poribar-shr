import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/services/firestore_image_service.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../camera/presentation/screens/custom_camera_screen.dart';
import '../../../direct_chat/presentation/screens/family_chat_screen.dart';
import '../../../family_management/presentation/screens/member_list_screen.dart';
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
import '../widgets/salary_celebration_dialog.dart';
import '../../../splash/presentation/widgets/update_splash_dialog.dart';
import '../../../../core/services/notification_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final List<Map<String, String>> _problemList = [];
  final TextEditingController _problemInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authUserProvider);
      if (user != null) {
        final id = user.phoneNumber.isNotEmpty ? user.phoneNumber : user.activeFamilyId;
        NotificationService().initializeNotificationEngine(userIdOrPhone: id);
        if (user.activeFamilyId.isNotEmpty) {
          NotificationService().listenToFamilyNotifications(user.activeFamilyId);
        }
      }
    });
  }

  @override
  void dispose() {
    _problemInputCtrl.dispose();
    super.dispose();
  }

  void _openAddExpense() {
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

    return GlassScaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(user, currentLang),
                  const SizedBox(height: 12),
                  const InvitationBannerWidget(),
                  const SizedBox(height: 4),
                  _buildFinancialSummaryCard(totalSavings, totalIncome, totalExpense, budgetProgress),
                  const SizedBox(height: 12),
                  _buildSalarySpotlightBanner(allExpenses),
                  _buildNoticeBanner(allExpenses),
                  const SizedBox(height: 16),
                  _buildSegmentedControl(selectedCategory, personalSum, familySum, l10n),
                  const SizedBox(height: 16),
                  _buildQuickActionsRow(),
                  const SizedBox(height: 20),
                  const AdvancedExpenseGraphsWidget(),
                  const SizedBox(height: 20),
                  _buildRecentTransactionsHeader(filteredExpenses.length),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (filteredExpenses.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 44),
                      SizedBox(height: 10),
                      Text(
                        'কোনো এন্ট্রি পাওয়া যায়নি',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                    return _buildTransactionItem(item, index == filteredExpenses.length - 1);
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpense,
        backgroundColor: AppColors.primaryGreen,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _buildHeader(dynamic user, AppLanguage currentLang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  ref.read(appLanguageProvider.notifier).toggleLanguage();
                },
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user?.fullName != null && user!.fullName.isNotEmpty
                                ? '${user.fullName} পরিবার'
                                : 'আমাদের পরিবার',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppColors.primaryGreen, size: 15),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'অনলাইন • ${currentLang == AppLanguage.bangla ? "বাংলা" : "English"}',
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
        Row(
          children: [
            _buildCircleIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildCircleIconButton(
              icon: Icons.chat_bubble_outline_rounded,
              showDot: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FamilyChatScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
            _buildCircleIconButton(
              icon: Icons.logout_rounded,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.cardDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.iosDivider),
                    ),
                    title: const Text('লগআউট', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    content: const Text('আপনি কি আপনার একাউন্ট থেকে লগআউট করতে চান?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল', style: TextStyle(color: AppColors.textSecondary))),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(authUserProvider.notifier).logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text('লগআউট', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showDot = false,
  }) {
    return InkWell(
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
            Icon(icon, color: AppColors.textPrimary, size: 20),
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
  }

  Widget _buildFinancialSummaryCard(
    double totalSavings,
    double totalIncome,
    double totalExpense,
    double budgetProgress,
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
              const Text(
                'মোট সঞ্চয় / অবশিষ্ট ব্যালেন্স',
                style: TextStyle(
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
                  '${(budgetProgress * 100).toStringAsFixed(0)}% খরচ',
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
                          const Text('মোট আয়', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
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
                          const Text('মোট খরচ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
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
        ],
      ),
    );
  }

  Widget _buildSalarySpotlightBanner(List<ExpenseEntity> allExpenses) {
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
                const Row(
                  children: [
                    Text(
                      '🎉 বেতন প্রাপ্তি!',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'চলতি মাস',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
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
              child: const Text(
                'বাজেট বণ্টন',
                style: TextStyle(
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

  Widget _buildNoticeBanner(List<ExpenseEntity> allExpenses) {
    final noticeText = allExpenses.isNotEmpty
        ? 'সর্বশেষ: ${allExpenses.first.purpose} (৳ ${allExpenses.first.amount.toStringAsFixed(0)})'
        : 'পরিবারে স্বাগতম! হিসাব সংরক্ষণ শুরু করতে নিচে + চাপুন';

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

  Widget _buildSegmentedControl(
    LedgerCategory selectedCategory,
    double personalSum,
    double familySum,
    dynamic l10n,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.iosDivider),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => ref
                  .read(selectedLedgerCategoryProvider.notifier)
                  .setCategory(LedgerCategory.personal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selectedCategory == LedgerCategory.personal
                      ? AppColors.cardDarkSecondary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${l10n.translate('my_tab')} (৳ ${personalSum.toStringAsFixed(0)})',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selectedCategory == LedgerCategory.personal
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => ref
                  .read(selectedLedgerCategoryProvider.notifier)
                  .setCategory(LedgerCategory.family),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selectedCategory == LedgerCategory.family
                      ? AppColors.cardDarkSecondary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${l10n.translate('family_tab')} (৳ ${familySum.toStringAsFixed(0)})',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selectedCategory == LedgerCategory.family
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickActionButton(
            icon: Icons.camera_alt_outlined,
            label: 'রসিদ ক্যামেরা',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
            ),
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.bar_chart_rounded,
            label: 'হিসাব বিশ্লেষণ',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComparativeAnalyticsScreen()),
            ),
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.lock_outline_rounded,
            label: 'গোপন ভল্ট',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivateVaultScreen()),
            ),
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.people_alt_outlined,
            label: 'সদস্য তালিকা',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemberListScreen()),
            ),
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.alarm_outlined,
            label: 'মাসিক অ্যালার্ম',
            onTap: () => AddReminderSheet.show(context),
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.checklist_rounded,
            label: 'জরুরি তালিকা',
            onTap: _showProblemListDialog,
          ),
          const SizedBox(width: 10),
          _buildQuickActionButton(
            icon: Icons.palette_outlined,
            label: 'স্প্ল্যাশ ছবি',
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

  Widget _buildRecentTransactionsHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'সাম্প্রতিক লেনদেন',
              style: TextStyle(
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

  Widget _buildTransactionItem(ExpenseEntity item, bool isLast) {
    final isExpense = item.type == TransactionType.expense;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await GlobalDeleteDialog.show(
          context: context,
          title: 'লেনদেন মুছে ফেলা নিশ্চিত করুন',
          message: 'আপনি কি নিশ্চিতভাবে এই লেনদেনটি মুছে ফেলতে চান?',
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
                    color: isExpense ? AppColors.darkRed : AppColors.darkGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isExpense ? Icons.shopping_bag_outlined : Icons.account_balance_wallet_outlined,
                    color: isExpense ? AppColors.primaryRed : AppColors.primaryGreen,
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
                      '${item.recordedByUserName} • ${item.category == LedgerCategory.personal ? "ব্যক্তিগত" : "পারিবারিক"}',
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
                '${isExpense ? "-" : "+"} ৳ ${item.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: isExpense ? AppColors.textPrimary : AppColors.primaryGreen,
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
