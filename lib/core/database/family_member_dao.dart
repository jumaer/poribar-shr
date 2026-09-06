import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

abstract class FamilyMemberDao {
  Future<void> insertOrUpdate(Map<String, dynamic> member, String familyId);
  Future<void> insertAll(List<Map<String, dynamic>> members, String familyId);
  Future<List<Map<String, dynamic>>> findAll(String familyId);
  Stream<List<Map<String, dynamic>>> watchAll(String familyId);
  Future<void> updateMember(Map<String, dynamic> data, String familyId, String phone);
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
        'canUpload': member['canUpload'] == false ? 0 : 1,
        'canViewExpenses': member['canViewExpenses'] == false ? 0 : 1,
        'canSendPushNotification': member['canSendPushNotification'] == true ? 1 : 0,
        'canAddMembers': member['canAddMembers'] == true ? 1 : 0,
        'canSetAlarms': member['canSetAlarms'] == false ? 0 : 1,
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
          'canUpload': m['canUpload'] == false ? 0 : 1,
          'canViewExpenses': m['canViewExpenses'] == false ? 0 : 1,
          'canSendPushNotification': m['canSendPushNotification'] == true ? 1 : 0,
          'canAddMembers': m['canAddMembers'] == true ? 1 : 0,
          'canSetAlarms': m['canSetAlarms'] == false ? 0 : 1,
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
        'canUpload': row['canUpload'] != 0,
        'canViewExpenses': row['canViewExpenses'] != 0,
        'canSendPushNotification': row['canSendPushNotification'] == 1,
        'canAddMembers': row['canAddMembers'] == 1,
        'canSetAlarms': row['canSetAlarms'] == null ? true : (row['canSetAlarms'] != 0),
        'joinedAt': row['joinedAt'],
      };
    }).toList();
  }

  @override
  Future<void> updateMember(Map<String, dynamic> data, String familyId, String phone) async {
    final db = await _appDb.database;
    final row = <String, dynamic>{};
    if (data.containsKey('name')) row['name'] = data['name'];
    if (data.containsKey('role')) row['role'] = data['role'];
    if (data.containsKey('relation')) row['relation'] = data['relation'];
    if (data.containsKey('photoUrl')) row['photoUrl'] = data['photoUrl'];
    if (data.containsKey('canUpload')) row['canUpload'] = data['canUpload'] == false ? 0 : 1;
    if (data.containsKey('canViewExpenses')) row['canViewExpenses'] = data['canViewExpenses'] == false ? 0 : 1;
    if (data.containsKey('canSendPushNotification')) row['canSendPushNotification'] = data['canSendPushNotification'] == true ? 1 : 0;
    if (data.containsKey('canAddMembers')) row['canAddMembers'] = data['canAddMembers'] == true ? 1 : 0;
    if (data.containsKey('canSetAlarms')) row['canSetAlarms'] = data['canSetAlarms'] == false ? 0 : 1;

    if (row.isNotEmpty) {
      await db.update(
        'family_members',
        row,
        where: 'phoneNumber = ? AND familyId = ?',
        whereArgs: [phone, familyId],
      );
      _changeNotifier.add(familyId);
    }
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
