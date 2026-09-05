import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import 'transaction_db_entity.dart';

class MonthOverMonthData {
  final String category;
  final double currentMonthAmount;
  final double previousMonthAmount;
  final double percentageChange;

  const MonthOverMonthData({
    required this.category,
    required this.currentMonthAmount,
    required this.previousMonthAmount,
    required this.percentageChange,
  });
}

class UserMonthlyAnalysisData {
  final String userId;
  final String userName;
  final double currentMonthTotal;
  final double previousMonthTotal;
  final double percentageChange;
  final bool isSpendingIncreased;
  final String topCategory;
  final double topCategoryAmount;

  const UserMonthlyAnalysisData({
    required this.userId,
    required this.userName,
    required this.currentMonthTotal,
    required this.previousMonthTotal,
    required this.percentageChange,
    required this.isSpendingIncreased,
    required this.topCategory,
    required this.topCategoryAmount,
  });
}

abstract class TransactionDao {
  Future<void> insertOrUpdate(TransactionDbEntity transaction);
  Future<void> insertAll(List<TransactionDbEntity> transactions);
  Future<void> deleteById(String id);
  Future<List<TransactionDbEntity>> findAll(String familyId);
  Stream<List<TransactionDbEntity>> watchAll(String familyId);
  Future<List<UserMonthlyAnalysisData>> calculateUserMonthlySummaries(String familyId);
}

class SqliteTransactionDao implements TransactionDao {
  final AppDatabase _appDb;
  final StreamController<String> _changeNotifier = StreamController<String>.broadcast();

  SqliteTransactionDao(this._appDb);

  @override
  Future<void> insertOrUpdate(TransactionDbEntity transaction) async {
    final db = await _appDb.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changeNotifier.add(transaction.familyId);
  }

  @override
  Future<void> insertAll(List<TransactionDbEntity> transactions) async {
    if (transactions.isEmpty) return;
    final db = await _appDb.database;
    final batch = db.batch();
    for (final t in transactions) {
      batch.insert(
        'transactions',
        t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changeNotifier.add(transactions.first.familyId);
  }

  @override
  Future<void> deleteById(String id) async {
    final db = await _appDb.database;
    final existing = await db.query(
      'transactions',
      columns: ['familyId'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final familyId = existing.isNotEmpty ? existing.first['familyId'] as String? : null;

    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (familyId != null) {
      _changeNotifier.add(familyId);
    }
  }

  @override
  Future<List<TransactionDbEntity>> findAll(String familyId) async {
    final db = await _appDb.database;
    final results = await db.query(
      'transactions',
      where: 'familyId = ?',
      whereArgs: [familyId],
      orderBy: 'timestamp DESC',
    );
    return results.map(TransactionDbEntity.fromMap).toList();
  }

  @override
  Stream<List<TransactionDbEntity>> watchAll(String familyId) async* {
    // Yield immediately from SQLite
    yield await findAll(familyId);

    // Then yield on every change
    await for (final changedFamilyId in _changeNotifier.stream) {
      if (changedFamilyId == familyId) {
        yield await findAll(familyId);
      }
    }
  }

  @override
  Future<List<UserMonthlyAnalysisData>> calculateUserMonthlySummaries(String familyId) async {
    final all = await findAll(familyId);
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final prevMonthStart = DateTime(now.year, now.month - 1, 1).millisecondsSinceEpoch;
    final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59).millisecondsSinceEpoch;

    final familyExpenses = all.where((t) => t.type == 'expense').toList();
    final userIds = familyExpenses.map((t) => t.recordedByUserId).toSet();
    final List<UserMonthlyAnalysisData> result = [];

    for (final uid in userIds) {
      final userExpenses = familyExpenses.where((t) => t.recordedByUserId == uid).toList();
      final userName = userExpenses.first.recordedByUserName;

      final currentExpenses = userExpenses.where((t) => t.timestamp >= currentMonthStart).toList();
      final prevExpenses = userExpenses.where((t) => t.timestamp >= prevMonthStart && t.timestamp <= prevMonthEnd).toList();

      final currentTotal = currentExpenses.fold(0.0, (sum, i) => sum + i.amount);
      final prevTotal = prevExpenses.fold(0.0, (sum, i) => sum + i.amount);

      final change = prevTotal > 0 ? ((currentTotal - prevTotal) / prevTotal) * 100 : (currentTotal > 0 ? 100.0 : 0.0);

      final categorySums = <String, double>{};
      for (final e in currentExpenses) {
        categorySums[e.category] = (categorySums[e.category] ?? 0.0) + e.amount;
      }

      String topCat = 'সাধারণ';
      double topCatAmount = 0.0;
      categorySums.forEach((cat, amount) {
        if (amount > topCatAmount) {
          topCatAmount = amount;
          topCat = cat;
        }
      });

      result.add(UserMonthlyAnalysisData(
        userId: uid,
        userName: userName,
        currentMonthTotal: currentTotal,
        previousMonthTotal: prevTotal,
        percentageChange: change,
        isSpendingIncreased: currentTotal > prevTotal,
        topCategory: topCat,
        topCategoryAmount: topCatAmount,
      ));
    }

    return result;
  }
}

class InMemoryTransactionDao implements TransactionDao {
  final Map<String, TransactionDbEntity> _store = {};
  final StreamController<List<TransactionDbEntity>> _streamController =
      StreamController<List<TransactionDbEntity>>.broadcast();

  @override
  Future<void> insertOrUpdate(TransactionDbEntity transaction) async {
    final existing = _store[transaction.id];
    if (existing == null || transaction.lastModified >= existing.lastModified) {
      _store[transaction.id] = transaction;
      _notify();
    }
  }

  @override
  Future<void> insertAll(List<TransactionDbEntity> transactions) async {
    for (final t in transactions) {
      final existing = _store[t.id];
      if (existing == null || t.lastModified >= existing.lastModified) {
        _store[t.id] = t;
      }
    }
    _notify();
  }

  @override
  Future<void> deleteById(String id) async {
    _store.remove(id);
    _notify();
  }

  @override
  Future<List<TransactionDbEntity>> findAll(String familyId) async {
    final list = _store.values.where((t) => t.familyId == familyId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Stream<List<TransactionDbEntity>> watchAll(String familyId) {
    _notify();
    return _streamController.stream.map((list) {
      return list.where((t) => t.familyId == familyId).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  @override
  Future<List<UserMonthlyAnalysisData>> calculateUserMonthlySummaries(String familyId) async {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final prevMonthStart = DateTime(now.year, now.month - 1, 1).millisecondsSinceEpoch;
    final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59).millisecondsSinceEpoch;

    final familyTransactions = _store.values
        .where((t) => t.familyId == familyId && t.type == 'expense')
        .toList();

    final userIds = familyTransactions.map((t) => t.recordedByUserId).toSet();
    final List<UserMonthlyAnalysisData> result = [];

    for (final uid in userIds) {
      final userExpenses = familyTransactions.where((t) => t.recordedByUserId == uid).toList();
      final userName = userExpenses.first.recordedByUserName;

      final currentExpenses = userExpenses.where((t) => t.timestamp >= currentMonthStart).toList();
      final prevExpenses = userExpenses.where((t) => t.timestamp >= prevMonthStart && t.timestamp <= prevMonthEnd).toList();

      final currentTotal = currentExpenses.fold(0.0, (sum, i) => sum + i.amount);
      final prevTotal = prevExpenses.fold(0.0, (sum, i) => sum + i.amount);

      final change = prevTotal > 0 ? ((currentTotal - prevTotal) / prevTotal) * 100 : (currentTotal > 0 ? 100.0 : 0.0);

      final categorySums = <String, double>{};
      for (final e in currentExpenses) {
        categorySums[e.category] = (categorySums[e.category] ?? 0.0) + e.amount;
      }

      String topCat = 'সাধারণ';
      double topCatAmount = 0.0;
      categorySums.forEach((cat, amount) {
        if (amount > topCatAmount) {
          topCatAmount = amount;
          topCat = cat;
        }
      });

      result.add(UserMonthlyAnalysisData(
        userId: uid,
        userName: userName,
        currentMonthTotal: currentTotal,
        previousMonthTotal: prevTotal,
        percentageChange: change,
        isSpendingIncreased: currentTotal > prevTotal,
        topCategory: topCat,
        topCategoryAmount: topCatAmount,
      ));
    }

    return result;
  }

  void _notify() {
    _streamController.add(_store.values.toList());
  }
}
