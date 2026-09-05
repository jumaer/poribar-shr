import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../features/expenses/domain/entities/expense_category.dart';
import 'app_database.dart';

abstract class CategoryDao {
  Future<void> insertOrUpdate(ExpenseCategory category, String familyId);
  Future<void> insertAll(List<ExpenseCategory> categories, String familyId);
  Future<void> delete(String id);
  Future<List<ExpenseCategory>> findAll(String familyId);
  Stream<List<ExpenseCategory>> watchAll(String familyId);
}

class SqliteCategoryDao implements CategoryDao {
  final AppDatabase _appDb;
  final StreamController<String> _changeNotifier = StreamController<String>.broadcast();

  SqliteCategoryDao(this._appDb);

  @override
  Future<void> delete(String id) async {
    final db = await _appDb.database;
    final existing = await db.query(
      'categories',
      columns: ['familyId'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final familyId = existing.isNotEmpty ? existing.first['familyId'] as String? : null;

    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    if (familyId != null) {
      _changeNotifier.add(familyId);
    }
  }

  @override
  Future<void> insertOrUpdate(ExpenseCategory category, String familyId) async {
    final db = await _appDb.database;
    await db.insert(
      'categories',
      {
        'id': category.id,
        'familyId': familyId,
        'nameBn': category.nameBn,
        'nameEn': category.nameEn,
        'iconCode': category.iconCodePoint,
        'colorValue': category.colorValue,
        'budgetLimit': category.isCustom ? 1.0 : 0.0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changeNotifier.add(familyId);
  }

  @override
  Future<void> insertAll(List<ExpenseCategory> categories, String familyId) async {
    if (categories.isEmpty) return;
    final db = await _appDb.database;
    final batch = db.batch();
    for (final c in categories) {
      batch.insert(
        'categories',
        {
          'id': c.id,
          'familyId': familyId,
          'nameBn': c.nameBn,
          'nameEn': c.nameEn,
          'iconCode': c.iconCodePoint,
          'colorValue': c.colorValue,
          'budgetLimit': c.isCustom ? 1.0 : 0.0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changeNotifier.add(familyId);
  }

  @override
  Future<List<ExpenseCategory>> findAll(String familyId) async {
    final db = await _appDb.database;
    final results = await db.query(
      'categories',
      where: 'familyId = ?',
      whereArgs: [familyId],
    );

    if (results.isEmpty) return [];

    return results.map((row) {
      return ExpenseCategory(
        id: row['id'] as String,
        nameBn: row['nameBn'] as String,
        nameEn: row['nameEn'] as String,
        iconCodePoint: row['iconCode'] as int? ?? 0xf6bb,
        colorValue: row['colorValue'] as int? ?? 0xFF10B981,
        isCustom: (row['budgetLimit'] as num?) == 1.0,
      );
    }).toList();
  }

  @override
  Stream<List<ExpenseCategory>> watchAll(String familyId) async* {
    yield await findAll(familyId);
    await for (final changedFamilyId in _changeNotifier.stream) {
      if (changedFamilyId == familyId) {
        yield await findAll(familyId);
      }
    }
  }
}
