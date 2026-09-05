import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

abstract class AppSettingsDao {
  Future<void> setSetting(String key, String value);
  Future<String?> getSetting(String key);
  Future<void> removeSetting(String key);
  Future<void> set(String key, String value);
  Future<String?> get(String key);
}

class SqliteAppSettingsDao implements AppSettingsDao {
  final AppDatabase _appDb;

  SqliteAppSettingsDao(this._appDb);

  @override
  Future<void> setSetting(String key, String value) async {
    final db = await _appDb.database;
    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String?> getSetting(String key) async {
    final db = await _appDb.database;
    final results = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }

  @override
  Future<void> removeSetting(String key) async {
    final db = await _appDb.database;
    await db.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  @override
  Future<void> set(String key, String value) => setSetting(key, value);

  @override
  Future<String?> get(String key) => getSetting(key);
}
