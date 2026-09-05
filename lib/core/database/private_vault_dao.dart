import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import 'private_vault_db_entity.dart';

abstract class PrivateVaultDao {
  Future<void> insertOrUpdate(PrivateVaultDbEntity item);
  Future<void> insertAll(List<PrivateVaultDbEntity> items);
  Future<void> deleteById(String id);
  Future<List<PrivateVaultDbEntity>> findAll(String userId);
  Stream<List<PrivateVaultDbEntity>> watchAll(String userId);
}

class SqlitePrivateVaultDao implements PrivateVaultDao {
  final AppDatabase _appDb;
  final StreamController<String> _changeNotifier = StreamController<String>.broadcast();

  SqlitePrivateVaultDao(this._appDb);

  @override
  Future<void> insertOrUpdate(PrivateVaultDbEntity item) async {
    final db = await _appDb.database;
    await db.insert(
      'private_vault',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changeNotifier.add(item.userId);
  }

  @override
  Future<void> insertAll(List<PrivateVaultDbEntity> items) async {
    if (items.isEmpty) return;
    final db = await _appDb.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'private_vault',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changeNotifier.add(items.first.userId);
  }

  @override
  Future<void> deleteById(String id) async {
    final db = await _appDb.database;
    final existing = await db.query(
      'private_vault',
      columns: ['userId'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final userId = existing.isNotEmpty ? existing.first['userId'] as String? : null;

    await db.delete(
      'private_vault',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (userId != null) {
      _changeNotifier.add(userId);
    }
  }

  @override
  Future<List<PrivateVaultDbEntity>> findAll(String userId) async {
    final db = await _appDb.database;
    final results = await db.query(
      'private_vault',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return results.map(PrivateVaultDbEntity.fromMap).toList();
  }

  @override
  Stream<List<PrivateVaultDbEntity>> watchAll(String userId) async* {
    yield await findAll(userId);
    await for (final changedUserId in _changeNotifier.stream) {
      if (changedUserId == userId) {
        yield await findAll(userId);
      }
    }
  }
}

class InMemoryPrivateVaultDao implements PrivateVaultDao {
  final Map<String, PrivateVaultDbEntity> _vaultStore = {};
  final StreamController<List<PrivateVaultDbEntity>> _streamController =
      StreamController<List<PrivateVaultDbEntity>>.broadcast();

  @override
  Future<void> insertOrUpdate(PrivateVaultDbEntity item) async {
    _vaultStore[item.id] = item;
    _notify();
  }

  @override
  Future<void> insertAll(List<PrivateVaultDbEntity> items) async {
    for (final item in items) {
      _vaultStore[item.id] = item;
    }
    _notify();
  }

  @override
  Future<void> deleteById(String id) async {
    _vaultStore.remove(id);
    _notify();
  }

  @override
  Future<List<PrivateVaultDbEntity>> findAll(String userId) async {
    return _vaultStore.values.where((item) => item.userId == userId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Stream<List<PrivateVaultDbEntity>> watchAll(String userId) {
    _notify();
    return _streamController.stream.map((list) {
      return list.where((item) => item.userId == userId).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  void _notify() {
    final list = _vaultStore.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _streamController.add(list);
  }
}
