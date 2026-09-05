import 'dart:async';
import '../../domain/entities/expense_entity.dart';
import '../datasources/expense_firestore_datasource.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseEntity>> getExpenses(String familyId);
  Future<void> addExpense(ExpenseEntity expense);
  Future<void> deleteExpense(String expenseId, String familyId);
  Stream<List<ExpenseEntity>> watchExpenses(String familyId);
}

class CachedExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseFirestoreDatasource _remoteDatasource;
  final Map<String, List<ExpenseEntity>> _localMemoryCache = {};
  final StreamController<List<ExpenseEntity>> _streamController =
      StreamController<List<ExpenseEntity>>.broadcast();

  CachedExpenseRepositoryImpl([ExpenseFirestoreDatasource? remoteDatasource])
      : _remoteDatasource = remoteDatasource ?? ExpenseFirestoreDatasource();

  @override
  Future<List<ExpenseEntity>> getExpenses(String familyId) async {
    final cached = _localMemoryCache[familyId];
    if (cached != null && cached.isNotEmpty) {
      _syncFromRemoteInBackground(familyId);
      return cached;
    }

    try {
      final stream = _remoteDatasource.streamExpenses(familyId);
      final list = await stream.first.timeout(const Duration(seconds: 4));
      _localMemoryCache[familyId] = list;
      return list;
    } catch (_) {
      return _localMemoryCache[familyId] ?? [];
    }
  }

  void _syncFromRemoteInBackground(String familyId) {
    _remoteDatasource.streamExpenses(familyId).listen((freshData) {
      _localMemoryCache[familyId] = freshData;
      _streamController.add(freshData);
    });
  }

  @override
  Future<void> addExpense(ExpenseEntity expense) async {
    final list = _localMemoryCache[expense.familyId] ?? [];
    _localMemoryCache[expense.familyId] = [expense, ...list];
    _streamController.add(_localMemoryCache[expense.familyId]!);

    try {
      await _remoteDatasource.saveExpenseToFirestore(expense);
    } catch (_) {}
  }

  @override
  Future<void> deleteExpense(String expenseId, String familyId) async {
    final list = _localMemoryCache[familyId] ?? [];
    _localMemoryCache[familyId] = list.where((e) => e.id != expenseId).toList();
    _streamController.add(_localMemoryCache[familyId]!);

    try {
      await _remoteDatasource.deleteExpenseFromFirestore(
        familyId: familyId,
        expenseId: expenseId,
      );
    } catch (_) {}
  }

  @override
  Stream<List<ExpenseEntity>> watchExpenses(String familyId) {
    _syncFromRemoteInBackground(familyId);
    return _streamController.stream;
  }
}
