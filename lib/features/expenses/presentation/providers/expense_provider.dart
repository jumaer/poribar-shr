import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../data/datasources/expense_firestore_datasource.dart';
import '../../data/repositories/room_synced_expense_repository.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_reminder.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SelectedLedgerCategoryNotifier extends Notifier<LedgerCategory> {
  @override
  LedgerCategory build() => LedgerCategory.family;

  void setCategory(LedgerCategory category) {
    state = category;
  }
}

final selectedLedgerCategoryProvider =
    NotifierProvider<SelectedLedgerCategoryNotifier, LedgerCategory>(
  SelectedLedgerCategoryNotifier.new,
);

class ExpenseListNotifier extends Notifier<List<ExpenseEntity>> {
  late final RoomSyncedExpenseRepository _repository = RoomSyncedExpenseRepository(
    localDao: AppDatabase().transactionDao,
    remoteDatasource: ExpenseFirestoreDatasource(),
  );
  StreamSubscription<List<ExpenseEntity>>? _sub;

  @override
  List<ExpenseEntity> build() {
    final user = ref.watch(authUserProvider);
    final familyId = user?.activeFamilyId ?? '';

    _sub?.cancel();
    if (familyId.isNotEmpty) {
      _sub = _repository.watchFamilyExpenses(familyId).listen((expenses) {
        state = expenses;
      });
    }

    ref.onDispose(() {
      _sub?.cancel();
      _repository.dispose();
    });
    return [];
  }

  Future<void> addExpense(ExpenseEntity expense) async {
    state = [expense, ...state.where((e) => e.id != expense.id)];
    await _repository.saveExpense(expense);
  }

  Future<void> deleteExpense(String id, String familyId) async {
    state = state.where((item) => item.id != id).toList();
    await _repository.deleteExpense(id, familyId);
  }
}

final expenseListProvider = NotifierProvider<ExpenseListNotifier, List<ExpenseEntity>>(
  ExpenseListNotifier.new,
);

class ReminderListNotifier extends Notifier<List<ExpenseReminder>> {
  final ExpenseFirestoreDatasource _datasource = ExpenseFirestoreDatasource();
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  List<ExpenseReminder> build() {
    final user = ref.watch(authUserProvider);
    final familyId = user?.activeFamilyId ?? '';

    _sub?.cancel();
    if (familyId.isNotEmpty) {
      _sub = _datasource.streamReminders(familyId).listen((docs) {
        state = docs.map((d) {
          return ExpenseReminder(
            id: d['id']?.toString() ?? '',
            title: d['title']?.toString() ?? '',
            amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
            targetPerson: d['targetPerson']?.toString() ?? '',
            purpose: d['purpose']?.toString() ?? '',
            dueDate: d['dueDate'] != null
                ? DateTime.tryParse(d['dueDate'].toString()) ?? DateTime.now()
                : DateTime.now(),
            details: d['details']?.toString() ?? '',
            isResolved: d['isResolved'] == true,
            alarmTime: d['alarmTime']?.toString() ?? '09:00 AM',
          );
        }).toList();
      });
    }

    ref.onDispose(() {
      _sub?.cancel();
    });
    return [];
  }

  Future<void> addReminder(ExpenseReminder reminder) async {
    final user = ref.read(authUserProvider);
    final familyId = user?.activeFamilyId ?? '';
    state = [reminder, ...state.where((r) => r.id != reminder.id)];
    if (familyId.isNotEmpty) {
      try {
        await _datasource.saveReminderToFirestore(familyId, {
          'id': reminder.id,
          'title': reminder.title,
          'amount': reminder.amount,
          'targetPerson': reminder.targetPerson,
          'purpose': reminder.purpose,
          'dueDate': reminder.dueDate.toIso8601String(),
          'details': reminder.details,
          'isResolved': reminder.isResolved,
          'alarmTime': reminder.alarmTime,
        });
      } catch (_) {}
    }
  }

  Future<void> toggleResolved(String id) async {
    final user = ref.read(authUserProvider);
    final familyId = user?.activeFamilyId ?? '';
    state = state.map((r) => r.id == id ? r.copyWith(isResolved: !r.isResolved) : r).toList();
    final updated = state.firstWhere((r) => r.id == id);
    if (familyId.isNotEmpty) {
      try {
        await _datasource.saveReminderToFirestore(familyId, {
          'id': updated.id,
          'title': updated.title,
          'amount': updated.amount,
          'targetPerson': updated.targetPerson,
          'purpose': updated.purpose,
          'dueDate': updated.dueDate.toIso8601String(),
          'details': updated.details,
          'isResolved': updated.isResolved,
          'alarmTime': updated.alarmTime,
        });
      } catch (_) {}
    }
  }
}

final reminderListProvider =
    NotifierProvider<ReminderListNotifier, List<ExpenseReminder>>(
  ReminderListNotifier.new,
);

final currentFilteredExpensesProvider = Provider<List<ExpenseEntity>>((ref) {
  final category = ref.watch(selectedLedgerCategoryProvider);
  final all = ref.watch(expenseListProvider);
  return all.where((e) => e.category == category).toList();
});

final monthlyIncomeTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseListProvider);
  return expenses
      .where((e) => e.type == TransactionType.income)
      .fold(0.0, (sum, item) => sum + item.amount);
});

final monthlyExpenseTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseListProvider);
  return expenses
      .where((e) => e.type == TransactionType.expense)
      .fold(0.0, (sum, item) => sum + item.amount);
});

final monthlySavingsTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseListProvider);
  return expenses
      .where((e) => e.type == TransactionType.savings)
      .fold(0.0, (sum, item) => sum + item.amount);
});
