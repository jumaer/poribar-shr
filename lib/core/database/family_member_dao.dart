import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

abstract class FamilyMemberDao {
  Future<void> insertOrUpdate(Map<String, dynamic> member, String familyId);
  Future<void> insertAll(List<Map<String, dynamic>> members, String familyId);
  Future<List<Map<String, dynamic>>> findAll(String familyId);
  Stream<List<Map<String, dynamic>>> watchAll(String familyId);
}

class SqliteFamilyMemberDao implements FamilyMemberDao {
  final AppDatabase _appDb;
  final StreamController<String> _changeNotifier = StreamController<String>.broadcast();

  SqliteFamilyMemberDao(this._appDb);

  @override
  Future<void> insertOrUpdate(Map<String, dynamic> member, String familyId) async {
    final db = await _appDb.database;
    await db.insert(
      'family_members',
      {
        'phoneNumber': member['phoneNumber']?.toString() ?? '',
        'id': member['id']?.toString() ?? '',
        'familyId': familyId,
        'name': member['name']?.toString() ?? '',
        'role': member['role']?.toString() ?? 'member',
        'relation': member['relation']?.toString() ?? '',
        'photoUrl': member['photoUrl']?.toString() ?? '',
        'canUpload': member['canUpload'] == true ? 1 : 0,
        'canViewExpenses': member['canViewExpenses'] == true ? 1 : 0,
        'canSendPushNotification': member['canSendPushNotification'] == true ? 1 : 0,
        'joinedAt': member['joinedAt']?.toString() ?? '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changeNotifier.add(familyId);
  }

  @override
  Future<void> insertAll(List<Map<String, dynamic>> members, String familyId) async {
    if (members.isEmpty) return;
    final db = await _appDb.database;
    final batch = db.batch();
    for (final m in members) {
      batch.insert(
        'family_members',
        {
          'phoneNumber': m['phoneNumber']?.toString() ?? '',
          'id': m['id']?.toString() ?? '',
          'familyId': familyId,
          'name': m['name']?.toString() ?? '',
          'role': m['role']?.toString() ?? 'member',
          'relation': m['relation']?.toString() ?? '',
          'photoUrl': m['photoUrl']?.toString() ?? '',
          'canUpload': m['canUpload'] == true ? 1 : 0,
          'canViewExpenses': m['canViewExpenses'] == true ? 1 : 0,
          'canSendPushNotification': m['canSendPushNotification'] == true ? 1 : 0,
          'joinedAt': m['joinedAt']?.toString() ?? '',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _changeNotifier.add(familyId);
  }

  @override
  Future<List<Map<String, dynamic>>> findAll(String familyId) async {
    final db = await _appDb.database;
    final results = await db.query(
      'family_members',
      where: 'familyId = ?',
      whereArgs: [familyId],
    );

    return results.map((row) {
      return {
        'phoneNumber': row['phoneNumber'],
        'id': row['id'],
        'familyId': row['familyId'],
        'name': row['name'],
        'role': row['role'],
        'relation': row['relation'],
        'photoUrl': row['photoUrl'],
        'canUpload': row['canUpload'] == 1,
        'canViewExpenses': row['canViewExpenses'] == 1,
        'canSendPushNotification': row['canSendPushNotification'] == 1,
        'joinedAt': row['joinedAt'],
      };
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchAll(String familyId) async* {
    yield await findAll(familyId);
    await for (final changedFamilyId in _changeNotifier.stream) {
      if (changedFamilyId == familyId) {
        yield await findAll(familyId);
      }
    }
  }
}
