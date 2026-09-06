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
      debugPrint('Firestore saveUser successful for: $cleanPhone');
    } catch (e) {
      debugPrint('Firestore save user error: $e');
      rethrow;
    }
  }

  Future<void> createFamily(Map<String, dynamic> familyData) async {
    final familyId = familyData['id'] as String;
    try {
      await _firestore.collection('families').doc(familyId).set(familyData, SetOptions(merge: true));
      debugPrint('Firestore createFamily successful: $familyId');
    } catch (e) {
      debugPrint('Firestore createFamily error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getFamily(String familyId) async {
    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Firestore getFamily error: $e');
    }
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
      debugPrint('Firestore streamFamilyMembers error (falling back to SQLite): $e');
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
    } catch (e) {
      debugPrint('Firestore getFamilyMembersOnce error (reading SQLite): $e');
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

      final userDocUpdate = <String, dynamic>{
        'uid': memberData['id'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
        'phoneNumber': phone,
        'activeFamilyId': familyId,
        'joinedFamilyIds': FieldValue.arrayUnion([familyId]),
        'role': memberData['role'] ?? 'member',
        'relation': memberData['relation'] ?? 'সদস্য',
        'fullName': memberData['name'] ?? '',
        'photoUrl': memberData['photoUrl'],
      };
      if (memberData['password'] != null && memberData['password'].toString().isNotEmpty) {
        userDocUpdate['password'] = memberData['password'];
      }

      await _firestore.collection('users').doc(phone).set(userDocUpdate, SetOptions(merge: true));
      debugPrint('Firestore addMemberToFamily successful for: $phone in family $familyId');
    } catch (e) {
      debugPrint('Firestore addMemberToFamily error: $e');
      rethrow;
    }

    final memberName = memberData['name'] ?? 'নতুন সদস্য';
    final relation = memberData['relation'] ?? 'সদস্য';
    final isFamilyHead = memberData['role'] == 'admin' && (relation == 'পরিবার প্রধান' || relation == 'Family Head');

    // Automatically send push notification to all other family members when a new member joins
    // (do not generate notification when family owner/creator first creates the family)
    if (!isFamilyHead) {
      try {
        await NotificationService().broadcastFamilyMemberChangeNotification(
          familyId: familyId,
          memberName: memberName,
          memberPhone: phone,
          isRemoved: false,
        );
      } catch (_) {}
    }
  }

  Future<void> updateMemberPermissionsAndRelation({
    required String familyId,
    required String memberPhone,
    required Map<String, dynamic> updates,
  }) async {
    final cleanPhone = _sanitizePhone(memberPhone);

    // 1. Update SQLite local cache immediately
    await AppDatabase().familyMemberDao.updateMember(updates, familyId, cleanPhone);

    // 2. Update Firestore member document
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('members')
          .doc(cleanPhone)
          .set(updates, SetOptions(merge: true));

      final userDocUpdates = <String, dynamic>{};
      if (updates.containsKey('role')) userDocUpdates['role'] = updates['role'];
      if (updates.containsKey('relation')) userDocUpdates['relation'] = updates['relation'];
      if (updates.containsKey('canAddMembers')) userDocUpdates['canAddMembers'] = updates['canAddMembers'];
      if (updates.containsKey('canSetAlarms')) userDocUpdates['canSetAlarms'] = updates['canSetAlarms'];
      if (updates.containsKey('canSendPushNotification')) userDocUpdates['canSendPushNotification'] = updates['canSendPushNotification'];
      if (updates.containsKey('canViewExpenses')) userDocUpdates['canViewExpenses'] = updates['canViewExpenses'];
      if (updates.containsKey('canUpload')) userDocUpdates['canUpload'] = updates['canUpload'];

      if (userDocUpdates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(cleanPhone)
            .set(userDocUpdates, SetOptions(merge: true));
      }

      // 3. Send notification regarding permission updates
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('notifications')
          .add({
        'title': 'অনুমতি ও প্রোফাইল আপডেট 🛡️',
        'body': 'অ্যাডমিন আপনার অনুমতি বা পারিবারিক সম্পর্ক আপডেট করেছেন।',
        'type': 'permission_update',
        'memberPhone': cleanPhone,
        'createdAt': FieldValue.serverTimestamp(),
        'time': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Firestore updateMemberPermissionsAndRelation error: $e');
      rethrow;
    }
  }

  Future<void> removeMemberFromFamily(String familyId, String phone) async {
    final cleanPhone = _sanitizePhone(phone);
    String memberName = 'সদস্য';
    try {
      final doc = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('members')
          .doc(cleanPhone)
          .get();
      if (doc.exists && doc.data() != null) {
        memberName = doc.data()?['name']?.toString() ?? 'সদস্য';
      }
    } catch (_) {}

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

    // Case 6: Broadcast member removal
    try {
      await NotificationService().broadcastFamilyMemberChangeNotification(
        familyId: familyId,
        memberName: memberName,
        memberPhone: cleanPhone,
        isRemoved: true,
      );
    } catch (_) {}
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

    // Case 5: Broadcast push when user receives invitation / request
    try {
      final targetPhone = inviteData['targetPhone']?.toString() ?? '';
      final senderName = inviteData['inviterName']?.toString() ?? 'পারিবারিক অ্যাডমিন';
      final familyName = inviteData['familyName']?.toString() ?? 'পারিবারিক খতিয়ান';
      final familyId = inviteData['familyId']?.toString() ?? '';

      if (targetPhone.isNotEmpty) {
        await NotificationService().broadcastFamilyInviteNotification(
          targetPhone: targetPhone,
          senderName: senderName,
          familyName: familyName,
          familyId: familyId,
        );
      }
    } catch (_) {}
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
