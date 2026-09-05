import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';

class AdvancedExpenseGraphsWidget extends ConsumerStatefulWidget {
  const AdvancedExpenseGraphsWidget({super.key});

  @override
  ConsumerState<AdvancedExpenseGraphsWidget> createState() =>
      _AdvancedExpenseGraphsWidgetState();
}

class _AdvancedExpenseGraphsWidgetState
    extends ConsumerState<AdvancedExpenseGraphsWidget> {
  int _selectedView = 0;
  DateTime _currentMonth = DateTime.now();
  int _touchedIndex = -1;

  final List<String> _monthNamesBn = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iosDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _previousMonth,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_monthNamesBn[_currentMonth.month - 1]} ${_currentMonth.year}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              const Icon(Icons.insights_rounded, color: AppColors.primaryGreen, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.cardDarkSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedView = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: _selectedView == 0
                            ? AppColors.cardDarkElevated
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'মাসিক ট্রেন্ড',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _selectedView == 0 ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: _selectedView == 0 ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedView = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: _selectedView == 1
                            ? AppColors.cardDarkElevated
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'খাতওয়ারি বন্টন',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _selectedView == 1 ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: _selectedView == 1 ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _selectedView == 0 ? _buildLineChart() : _buildCategoryPieChart(),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final allExpenses = ref.watch(expenseListProvider);

    if (allExpenses.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, color: AppColors.textMuted, size: 36),
            SizedBox(height: 8),
            Text(
              'কোন লেনদেন রেকর্ড করা হয়নি',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 2),
            Text(
              'নিচের + বাটনে চেপে আয় বা খরচ যোগ করুন',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    final incomeByDay = <int, double>{};
    final expenseByDay = <int, double>{};

    for (final item in allExpenses) {
      final day = item.date.day.clamp(1, 30);
      if (item.type == TransactionType.income) {
        incomeByDay[day] = (incomeByDay[day] ?? 0.0) + item.amount;
      } else if (item.type == TransactionType.expense) {
        expenseByDay[day] = (expenseByDay[day] ?? 0.0) + item.amount;
      }
    }

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    double maxY = 1000.0;

    for (int d = 1; d <= 30; d += 5) {
      final inc = incomeByDay[d] ?? 0.0;
      final exp = expenseByDay[d] ?? 0.0;
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
      incomeSpots.add(FlSpot(d.toDouble(), inc));
      expenseSpots.add(FlSpot(d.toDouble(), exp));
    }
    maxY = (maxY * 1.25).ceilToDouble();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('আয়', AppColors.accentGreen),
            const SizedBox(width: 16),
            _buildLegendItem('খরচ', AppColors.accentRed),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 2000 ? (maxY / 3).roundToDouble() : 500,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.white.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: maxY > 2000 ? (maxY / 3).roundToDouble() : 500,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        value >= 1000 ? '৳${(value / 1000).toStringAsFixed(0)}k' : '৳${value.toInt()}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value > 30) return const SizedBox.shrink();
                      return Text(
                        '${value.toInt()}ই',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 1,
              maxX: 30,
              minY: 0,
              maxY: maxY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.cardDarkElevated,
                  tooltipBorder: const BorderSide(color: AppColors.iosDivider),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isIncome = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${spot.x.toInt()} তারিখ\n${isIncome ? "আয়" : "খরচ"}: ৳${spot.y.toStringAsFixed(0)}',
                        TextStyle(
                          color: isIncome ? AppColors.accentGreen : AppColors.accentRed,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  color: AppColors.accentGreen,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.darkGreen,
                  ),
                ),
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  color: AppColors.accentRed,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.darkRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart() {
    final categories = ref.watch(categoryAnalyticsProvider);

    if (categories.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, color: AppColors.textMuted, size: 36),
            SizedBox(height: 8),
            Text(
              'কোন ক্যাটাগরি খরচ পাওয়া যায়নি',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 36,
              sections: List.generate(categories.length, (i) {
                final isTouched = i == _touchedIndex;
                final fontSize = isTouched ? 12.0 : 10.0;
                final radius = isTouched ? 48.0 : 42.0;
                final item = categories[i];
                final pct = item.percentage.clamp(1.0, 100.0);

                return PieChartSectionData(
                  color: Color(item.category.colorValue),
                  value: pct,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: categories.map((cat) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(cat.category.colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${cat.category.nameBn}: ৳${cat.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
