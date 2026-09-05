import 'dart:async';
import '../../../../core/database/transaction_dao.dart';
import '../../../../core/database/transaction_db_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../datasources/expense_firestore_datasource.dart';
import '../models/expense_model.dart';

class RoomSyncedExpenseRepository {
  final TransactionDao localDao;
  final ExpenseFirestoreDatasource remoteDatasource;
  StreamSubscription? _remoteSubscription;

  RoomSyncedExpenseRepository({
    required this.localDao,
    required this.remoteDatasource,
  });

  Stream<List<ExpenseEntity>> watchFamilyExpenses(String familyId) {
    _startBackgroundRemoteSync(familyId);

    return localDao.watchAll(familyId).map((dbEntities) {
      return dbEntities.map(_mapToDomain).toList();
    });
  }

  Future<void> saveExpense(ExpenseEntity expense) async {
    final dbEntity = _mapToDbEntity(expense);
    await localDao.insertOrUpdate(dbEntity);

    try {
      await remoteDatasource.saveExpenseToFirestore(expense);
    } catch (_) {}
  }

  Future<void> deleteExpense(String expenseId, String familyId) async {
    await localDao.deleteById(expenseId);

    try {
      await remoteDatasource.deleteExpenseFromFirestore(
        familyId: familyId,
        expenseId: expenseId,
      );
    } catch (_) {}
  }

  void _startBackgroundRemoteSync(String familyId) {
    _remoteSubscription?.cancel();
    _remoteSubscription = remoteDatasource.streamExpenses(familyId).listen((remoteExpenses) async {
      final dbEntities = remoteExpenses.map((e) {
        final model = ExpenseModel.fromEntity(e);
        return TransactionDbEntity(
          id: model.id,
          familyId: model.familyId,
          type: model.type.name,
          category: model.category.name,
          amount: model.amount,
          purpose: model.purpose,
          description: model.description,
          timestamp: model.date.millisecondsSinceEpoch,
          recordedByUserId: model.recordedByUserId,
          recordedByUserName: model.recordedByUserName,
          imageBase64: model.imageUrl,
          lastModified: model.date.millisecondsSinceEpoch,
        );
      }).toList();

      await localDao.insertAll(dbEntities);
    }, onError: (err) {
      // Graceful offline fallback: keep streaming from local SQLite database
    });
  }

  void dispose() {
    _remoteSubscription?.cancel();
  }

  ExpenseEntity _mapToDomain(TransactionDbEntity entity) {
    TransactionType txType;
    if (entity.type == 'income') {
      txType = TransactionType.income;
    } else if (entity.type == 'savings') {
      txType = TransactionType.savings;
    } else {
      txType = TransactionType.expense;
    }

    return ExpenseEntity(
      id: entity.id,
      familyId: entity.familyId,
      type: txType,
      category: entity.category == 'personal' ? LedgerCategory.personal : LedgerCategory.family,
      amount: entity.amount,
      purpose: entity.purpose,
      description: entity.description,
      date: DateTime.fromMillisecondsSinceEpoch(entity.timestamp),
      recordedByUserId: entity.recordedByUserId,
      recordedByUserName: entity.recordedByUserName,
      imageUrl: entity.imageBase64,
    );
  }

  TransactionDbEntity _mapToDbEntity(ExpenseEntity domain) {
    return TransactionDbEntity(
      id: domain.id,
      familyId: domain.familyId,
      type: domain.type.name,
      category: domain.category.name,
      amount: domain.amount,
      purpose: domain.purpose,
      description: domain.description,
      timestamp: domain.date.millisecondsSinceEpoch,
      recordedByUserId: domain.recordedByUserId,
      recordedByUserName: domain.recordedByUserName,
      imageBase64: domain.imageUrl,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
