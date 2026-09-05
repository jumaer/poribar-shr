import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/transaction_dao.dart';
import '../../domain/entities/expense_entity.dart';
import 'expense_provider.dart';

class SelectedMemberFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectMember(String? userId) {
    state = userId;
  }
}

final selectedMemberFilterProvider =
    NotifierProvider<SelectedMemberFilterNotifier, String?>(
  SelectedMemberFilterNotifier.new,
);

final comparativeUserAnalyticsProvider = Provider<List<UserMonthlyAnalysisData>>((ref) {
  final allExpenses = ref.watch(expenseListProvider);

  final now = DateTime.now();
  final currentMonthStart = DateTime(now.year, now.month, 1);
  final prevMonthStart = DateTime(now.year, now.month - 1, 1);
  final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

  final expenseItems = allExpenses.where((e) => e.type == TransactionType.expense).toList();
  final userIds = expenseItems.map((e) => e.recordedByUserId).toSet();

  final List<UserMonthlyAnalysisData> summaries = [];

  for (final uid in userIds) {
    final userExpenses = expenseItems.where((e) => e.recordedByUserId == uid).toList();
    final userName = userExpenses.first.recordedByUserName;

    final currentExpenses = userExpenses.where((e) => e.date.isAfter(currentMonthStart) || e.date.isAtSameMomentAs(currentMonthStart)).toList();
    final prevExpenses = userExpenses.where((e) => e.date.isAfter(prevMonthStart) && e.date.isBefore(prevMonthEnd)).toList();

    final currentTotal = currentExpenses.fold(0.0, (sum, i) => sum + i.amount);
    final prevTotal = prevExpenses.fold(0.0, (sum, i) => sum + i.amount);

    final change = prevTotal > 0
        ? ((currentTotal - prevTotal) / prevTotal) * 100
        : (currentTotal > 0 ? 100.0 : 0.0);
    final isIncreased = currentTotal > prevTotal;

    final Map<String, double> categoryMap = {};
    for (final e in currentExpenses) {
      final key = e.purpose.contains('বাজার')
          ? 'খাবার ও বাজার'
          : (e.purpose.contains('বিদ্যুৎ')
              ? 'বিদ্যুৎ বিল'
              : (e.purpose.contains('ওষুধ') ? 'ওষুধ ও চিকিৎসা' : 'অন্যান্য'));
      categoryMap[key] = (categoryMap[key] ?? 0.0) + e.amount;
    }

    var topCat = 'খাবার ও বাজার';
    var topCatAmount = currentTotal;
    if (categoryMap.isNotEmpty) {
      final sorted = categoryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topCat = sorted.first.key;
      topCatAmount = sorted.first.value;
    }

    summaries.add(
      UserMonthlyAnalysisData(
        userId: uid,
        userName: userName,
        currentMonthTotal: currentTotal,
        previousMonthTotal: prevTotal,
        percentageChange: change.abs(),
        isSpendingIncreased: isIncreased,
        topCategory: topCat,
        topCategoryAmount: topCatAmount,
      ),
    );
  }

  return summaries;
});
