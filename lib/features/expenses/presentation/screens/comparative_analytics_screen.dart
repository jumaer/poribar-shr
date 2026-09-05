import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/transaction_dao.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/global_bottom_sheet.dart';
import '../providers/comparative_analytics_provider.dart';

class ComparativeAnalyticsScreen extends ConsumerStatefulWidget {
  const ComparativeAnalyticsScreen({super.key});

  @override
  ConsumerState<ComparativeAnalyticsScreen> createState() =>
      _ComparativeAnalyticsScreenState();
}

class _ComparativeAnalyticsScreenState
    extends ConsumerState<ComparativeAnalyticsScreen> {
  String? _selectedUserId;

  void _openWarningPushSheet(UserMonthlyAnalysisData item) {
    final titleCtrl = TextEditingController(text: 'খরচ নিয়ন্ত্রণের অনুরোধ');
    final msgCtrl = TextEditingController(
      text: '${item.userName}, আপনি এই মাসে "${item.topCategory}" খাতে মোট ৳${item.topCategoryAmount.toStringAsFixed(0)} খরচ করেছেন। বাজেট নিয়ন্ত্রণে সচেতন হোন।',
    );

    GlobalBottomSheet.show(
      context: context,
      title: 'সতর্কবার্তা পুশ পাঠান',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryRed.withValues(alpha: 0.2),
                child: const Icon(CupertinoIcons.exclamationmark_triangle, color: AppColors.accentRed, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'প্রাপক: ${item.userName} (${item.topCategory})',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassTextField(
            controller: titleCtrl,
            label: 'নোটিফিকেশন শিরোনাম',
            prefixIcon: CupertinoIcons.bell,
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: msgCtrl,
            label: 'সতর্কবার্তা বিবরণ',
            maxLines: 3,
            prefixIcon: CupertinoIcons.chat_bubble_text,
          ),
          const SizedBox(height: 18),
          GlassButton(
            text: 'সতর্কবার্তা পুশ নোটিফিকেশন পাঠান',
            isRed: true,
            icon: CupertinoIcons.paperplane_fill,
            onPressed: () {
              NotificationService().sendCustomPush(
                title: titleCtrl.text.trim(),
                body: msgCtrl.text.trim(),
                senderName: 'পরিবার এডমিন',
                receiverId: item.userId,
                senderIsPermitted: true,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.userName} এর কাছে সরাসরি পুশ পাঠানো হয়েছে!'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaries = ref.watch(comparativeUserAnalyticsProvider);
    final displayedSummaries = _selectedUserId == null
        ? summaries
        : summaries.where((s) => s.userId == _selectedUserId).toList();

    return GlassScaffold(
      appBar: const GlassAppBar(
        title: 'তুলনামূলক বিশ্লেষণ ও MoM রিপোর্ট',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassBox(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const Icon(CupertinoIcons.person_2_fill, color: AppColors.accentGreen, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'সদস্য ফিল্টার:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedUserId,
                      dropdownColor: AppColors.cardDark,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      icon: const Icon(CupertinoIcons.chevron_down, color: AppColors.accentGreen, size: 16),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('সকল সদস্য')),
                        ...summaries.map((s) => DropdownMenuItem(value: s.userId, child: Text(s.userName))),
                      ],
                      onChanged: (val) => setState(() => _selectedUserId = val),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'সদস্যভিত্তিক মাসিক খরচ তুলনা',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(CupertinoIcons.chart_bar_alt_fill, color: AppColors.accentGreen, size: 16),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            getTitlesWidget: (val, meta) => Text(
                              '৳${(val / 1000).toStringAsFixed(0)}k',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < displayedSummaries.length) {
                                final name = displayedSummaries[idx].userName;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    name.split(' ').first,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(displayedSummaries.length, (i) {
                        final s = displayedSummaries[i];
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: s.previousMonthTotal > 0 ? s.previousMonthTotal : 500,
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: s.currentMonthTotal,
                              color: s.isSpendingIncreased ? AppColors.accentRed : AppColors.accentGreen,
                              width: 10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('পূর্বের মাস', Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(width: 16),
                    _buildLegendItem('চলতি মাস (বৃদ্ধি)', AppColors.accentRed),
                    const SizedBox(width: 16),
                    _buildLegendItem('চলতি মাস (হ্রাস)', AppColors.accentGreen),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'সদস্যভিত্তিক বিস্তারিত ব্যয় টেবিল',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                dataTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                columnSpacing: 18,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('সদস্য')),
                  DataColumn(label: Text('শীর্ষ খাত')),
                  DataColumn(label: Text('চলতি ব্যয়')),
                  DataColumn(label: Text('MoM পরিবর্তন')),
                  DataColumn(label: Text('অ্যাকশন')),
                ],
                rows: displayedSummaries.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.accentGreen.withValues(alpha: 0.2),
                              child: Text(
                                item.userName.isNotEmpty ? item.userName.substring(0, 1) : 'স',
                                style: const TextStyle(color: AppColors.accentGreen, fontSize: 10),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(item.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.topCategory),
                        ),
                      ),
                      DataCell(Text('৳ ${item.currentMonthTotal.toStringAsFixed(0)}')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.isSpendingIncreased
                                  ? CupertinoIcons.arrow_up_right
                                  : CupertinoIcons.arrow_down_right,
                              color: item.isSpendingIncreased ? AppColors.accentRed : AppColors.accentGreen,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.percentageChange.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: item.isSpendingIncreased ? AppColors.accentRed : AppColors.accentGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(CupertinoIcons.bell_fill, color: AppColors.accentRed, size: 18),
                          tooltip: 'সতর্কবার্তা পুশ পাঠান',
                          onPressed: () => _openWarningPushSheet(item),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}
