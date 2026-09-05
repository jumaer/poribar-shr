import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/notification_service.dart';

class FamilyFirestoreDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _cacheUserLocally(Map<String, dynamic> data) async {
    try {
      final db = await AppDatabase().database;
      final cleanPhone = _sanitizePhone(data['phoneNumber'] ?? '');
      await db.insert(
        'users',
        {
          'phoneNumber': cleanPhone,
          'uid': data['uid'] ?? '',
          'fullName': data['fullName'] ?? '',
          'password': data['password'] ?? '',
          'activeFamilyId': data['activeFamilyId'] ?? '',
          'role': data['role'] ?? 'member',
          'isFamilyOwner': data['isFamilyOwner'] == true ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _getUserFromSqlite(String phone) async {
    try {
      final db = await AppDatabase().database;
      final rows = await db.query(
        'users',
        where: 'phoneNumber = ?',
        whereArgs: [phone],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final r = rows.first;
        return {
          'phoneNumber': r['phoneNumber'],
          'uid': r['uid'],
          'fullName': r['fullName'],
          'password': r['password'],
          'activeFamilyId': r['activeFamilyId'],
          'role': r['role'],
          'isFamilyOwner': r['isFamilyOwner'] == 1,
        };
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final cleanPhone = _sanitizePhone(phone);
    try {
      final doc = await _firestore.collection('users').doc(cleanPhone).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        await _cacheUserLocally(data);
        return data;
      }
    } catch (e) {
      debugPrint('Firestore fetch user error: $e');
    }

    // Offline fallback from SQLite
    return await _getUserFromSqlite(cleanPhone);
  }

  Future<void> saveUser(Map<String, dynamic> data) async {
    final cleanPhone = _sanitizePhone(data['phoneNumber'] ?? '');
    await _cacheUserLocally(data);
    try {
      await _firestore.collection('users').doc(cleanPhone).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore save user offline queued: $e');
    }
  }

  Future<void> createFamily(Map<String, dynamic> familyData) async {
    final familyId = familyData['id'] as String;
    try {
      await _firestore.collection('families').doc(familyId).set(familyData, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getFamily(String familyId) async {
    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (_) {}
    return null;
  }

  Stream<List<Map<String, dynamic>>> streamFamilyMembers(String familyId) async* {
    // 1. Yield from local SQLite cache immediately
    final localCached = await AppDatabase().familyMemberDao.findAll(familyId);
    if (localCached.isNotEmpty) {
      yield localCached;
    }

    // 2. Stream from Firestore in background
    try {
      await for (final snap in _firestore
          .collection('families')
          .doc(familyId)
          .collection('members')
          .snapshots()) {
        final list = snap.docs.map((d) => d.data()).toList();
        await AppDatabase().familyMemberDao.insertAll(list, familyId);
        yield list;
      }
    } catch (e) {
      // Offline fallback: keep streaming from SQLite
      yield* AppDatabase().familyMemberDao.watchAll(familyId);
    }
  }

  Future<List<Map<String, dynamic>>> getFamilyMembersOnce(String familyId) async {
    try {
      final snap = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('members')
          .get();
      final list = snap.docs.map((d) => d.data()).toList();
      await AppDatabase().familyMemberDao.insertAll(list, familyId);
      return list;
    } catch (_) {
      return await AppDatabase().familyMemberDao.findAll(familyId);
    }
  }

  Future<void> addMemberToFamily(String familyId, Map<String, dynamic> memberData) async {
    final phone = _sanitizePhone(memberData['phoneNumber'] ?? '');
    await AppDatabase().familyMemberDao.insertOrUpdate(memberData, familyId);

    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('members')
          .doc(phone)
          .set(memberData, SetOptions(merge: true));

      await _firestore.collection('users').doc(phone).set({
        'activeFamilyId': familyId,
        'joinedFamilyIds': FieldValue.arrayUnion([familyId]),
        'role': memberData['role'] ?? 'member',
        'fullName': memberData['name'] ?? '',
        'photoUrl': memberData['photoUrl'],
      }, SetOptions(merge: true));
    } catch (_) {}

    final memberName = memberData['name'] ?? 'নতুন সদস্য';
    final relation = memberData['relation'] ?? 'সদস্য';

    // Automatically send push notification to all other family members
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('notifications')
          .add({
        'title': 'নতুন সদস্য যুক্ত হয়েছেন 🎉',
        'body': '$memberName ($relation) আপনার পরিবারে যুক্ত হয়েছেন!',
        'type': 'new_member',
        'memberName': memberName,
        'memberPhone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'time': DateTime.now().toIso8601String(),
      });

      NotificationService().sendCustomPush(
        title: 'নতুন সদস্য যুক্ত হয়েছেন 🎉',
        body: '$memberName ($relation) আপনার পরিবারে যুক্ত হয়েছেন!',
        senderName: 'সিস্টেম',
        receiverId: familyId,
        senderIsPermitted: true,
      );
    } catch (_) {}
  }

  Future<void> removeMemberFromFamily(String familyId, String phone) async {
    final cleanPhone = _sanitizePhone(phone);
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(cleanPhone)
        .delete();

    await _firestore.collection('users').doc(cleanPhone).set({
      'activeFamilyId': '',
      'role': 'detached',
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> streamPendingInvitations(String phone) {
    final cleanPhone = _sanitizePhone(phone);
    return _firestore
        .collection('family_invitations')
        .where('targetPhone', isEqualTo: cleanPhone)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> sendFamilyInvitation(Map<String, dynamic> inviteData) async {
    final id = inviteData['id'] as String;
    await _firestore.collection('family_invitations').doc(id).set(inviteData);
  }

  Future<void> acceptFamilyInvitation({
    required String inviteId,
    required String newFamilyId,
    required Map<String, dynamic> memberData,
  }) async {
    await _firestore.collection('family_invitations').doc(inviteId).update({
      'status': 'accepted',
      'respondedAt': DateTime.now().toIso8601String(),
    });

    await addMemberToFamily(newFamilyId, memberData);
  }

  Future<void> rejectFamilyInvitation(String inviteId) async {
    await _firestore.collection('family_invitations').doc(inviteId).update({
      'status': 'rejected',
      'respondedAt': DateTime.now().toIso8601String(),
    });
  }

  String _sanitizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
  }
}
