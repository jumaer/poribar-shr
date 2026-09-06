import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/user_entity.dart';
import '../../../family_management/data/datasources/family_firestore_datasource.dart';

class AuthUserNotifier extends Notifier<UserEntity?> {
  final FamilyFirestoreDatasource _datasource = FamilyFirestoreDatasource();

  @override
  UserEntity? build() {
    return null;
  }

  /// Saves the active user entity into SQLite AppSettings and the local users table
  /// for instant, lifetime offline session persistence.
  Future<void> _persistUserSession(UserEntity user) async {
    try {
      await AppDatabase().appSettingsDao.setSetting('session_phone', user.phoneNumber);
      await AppDatabase().appSettingsDao.setSetting('session_user_json', user.toJson());

      final db = await AppDatabase().database;
      await db.insert(
        'users',
        {
          'phoneNumber': user.phoneNumber,
          'uid': user.uid,
          'fullName': user.fullName,
          'activeFamilyId': user.activeFamilyId,
          'role': user.role,
          'isFamilyOwner': user.isFamilyOwner ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error persisting user session: $e');
    }
  }

  /// Automatically restores the lifetime user session.
  /// First checks local SQLite cache for instant zero-latency startup.
  /// Never logs the user out due to offline state or network failure.
  Future<bool> tryAutoLogin() async {
    try {
      // 1. FAST PATH: Instant local restoration from cached session_user_json
      final cachedUserJson = await AppDatabase().appSettingsDao.getSetting('session_user_json');
      if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
        try {
          final user = UserEntity.fromJson(cachedUserJson);
          if (user.phoneNumber.isNotEmpty && user.activeFamilyId.isNotEmpty) {
            state = user;
            // Non-blocking background sync for remote updates
            _syncUserInBackground(user.phoneNumber);
            return true;
          }
        } catch (e) {
          debugPrint('Error parsing cached session_user_json: $e');
        }
      }

      // 2. SECONDARY LOCAL PATH: Restore from SQLite users table using saved session_phone
      final savedPhone = await AppDatabase().appSettingsDao.getSetting('session_phone');
      if (savedPhone != null && savedPhone.isNotEmpty) {
        try {
          final db = await AppDatabase().database;
          final localRows = await db.query(
            'users',
            where: 'phoneNumber = ?',
            whereArgs: [savedPhone],
            limit: 1,
          );
          if (localRows.isNotEmpty) {
            final row = localRows.first;
            final familyId = row['activeFamilyId']?.toString() ?? '';
            if (familyId.isNotEmpty) {
              final role = row['role']?.toString() ?? 'member';
              final isOwner = (row['isFamilyOwner'] == 1 || row['isFamilyOwner'] == true);
              final isAdmin = role == 'admin' || isOwner;
              final user = UserEntity(
                uid: row['uid']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
                phoneNumber: savedPhone,
                fullName: row['fullName']?.toString() ?? 'পরিবার সদস্য',
                activeFamilyId: familyId,
                joinedFamilyIds: [familyId],
                isFamilyOwner: isOwner,
                role: role,
                canAddMembers: isAdmin,
                canSetAlarms: true,
                canSendPushNotification: isAdmin,
                canViewExpenses: true,
                canUpload: true,
              );
              state = user;
              await _persistUserSession(user);
              _syncUserInBackground(savedPhone);
              return true;
            }
          }
        } catch (e) {
          debugPrint('Error loading user from local SQLite table: $e');
        }

        // 3. REMOTE FALLBACK: Network query with short timeout (non-hanging)
        try {
          final data = await _datasource.getUserByPhone(savedPhone).timeout(
            const Duration(seconds: 4),
          );
          if (data != null) {
            final familyId = data['activeFamilyId']?.toString() ?? '';
            if (familyId.isNotEmpty) {
              final role = data['role']?.toString() ?? 'member';
              final isOwner = data['isFamilyOwner'] == true;
              final isAdmin = role == 'admin' || isOwner;

              final user = UserEntity(
                uid: data['uid']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
                phoneNumber: savedPhone,
                fullName: data['fullName']?.toString() ?? 'পরিবার সদস্য',
                photoUrl: data['photoUrl']?.toString(),
                activeFamilyId: familyId,
                joinedFamilyIds: List<String>.from(data['joinedFamilyIds'] ?? [familyId]),
                isFamilyOwner: isOwner,
                role: role,
                canAddMembers: isAdmin ? true : (data['canAddMembers'] == true),
                canSetAlarms: isAdmin ? true : (data['canSetAlarms'] == null ? true : data['canSetAlarms'] == true),
                canSendPushNotification: isAdmin ? true : (data['canSendPushNotification'] == true),
                canViewExpenses: isAdmin ? true : (data['canViewExpenses'] == null ? true : data['canViewExpenses'] == true),
                canUpload: isAdmin ? true : (data['canUpload'] == null ? true : data['canUpload'] == true),
              );

              state = user;
              await _persistUserSession(user);
              return true;
            }
          }
        } catch (e) {
          debugPrint('Remote auto-login timeout/error: $e');
        }
      }
    } catch (e) {
      debugPrint('Auto login error: $e');
    }
    return false;
  }

  void _syncUserInBackground(String phoneNumber) {
    Future.microtask(() async {
      try {
        final data = await _datasource.getUserByPhone(phoneNumber);
        if (data != null && state != null && state!.phoneNumber == phoneNumber) {
          final role = data['role']?.toString() ?? state!.role;
          final isOwner = data['isFamilyOwner'] == true || state!.isFamilyOwner;
          final isAdmin = role == 'admin' || isOwner;

          final updated = state!.copyWith(
            fullName: data['fullName']?.toString(),
            photoUrl: data['photoUrl']?.toString(),
            activeFamilyId: data['activeFamilyId']?.toString(),
            role: role,
            isFamilyOwner: isOwner,
            canAddMembers: isAdmin ? true : (data['canAddMembers'] == true),
            canSetAlarms: isAdmin ? true : (data['canSetAlarms'] == null ? true : data['canSetAlarms'] == true),
            canSendPushNotification: isAdmin ? true : (data['canSendPushNotification'] == true),
            canViewExpenses: isAdmin ? true : (data['canViewExpenses'] == null ? true : data['canViewExpenses'] == true),
            canUpload: isAdmin ? true : (data['canUpload'] == null ? true : data['canUpload'] == true),
          );
          state = updated;
          await _persistUserSession(updated);
        }
      } catch (e) {
        debugPrint('Silent background user sync: $e');
      }
    });
  }

  Future<void> signUp({
    required String fullName,
    required String phoneNumber,
    required String password,
    String? photoUrl,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    final existing = await _datasource.getUserByPhone(cleanPhone);
    if (existing != null) {
      final role = existing['role']?.toString() ?? 'member';
      final isOwner = existing['isFamilyOwner'] == true;
      if (role == 'admin' || isOwner) {
        throw Exception('এই ফোন নম্বরে ইতিমধ্যে অ্যাডমিন অ্যাকাউন্ট রয়েছে! অনুগ্রহ করে লগইন করুন।');
      } else {
        throw Exception('এই ফোন নম্বরে ইতিমধ্যে পরিবার সদস্য অ্যাকাউন্ট রয়েছে! অনুগ্রহ করে সরাসরি লগইন করুন।');
      }
    }

    final familyId = 'fam_${DateTime.now().millisecondsSinceEpoch}';
    final uid = 'usr_${DateTime.now().millisecondsSinceEpoch}';

    await _datasource.createFamily({
      'id': familyId,
      'name': '$fullName পরিবার',
      'adminId': uid,
      'adminPhone': cleanPhone,
      'createdAt': DateTime.now().toIso8601String(),
    });

    final userData = {
      'uid': uid,
      'phoneNumber': cleanPhone,
      'fullName': fullName,
      'password': password,
      'photoUrl': photoUrl,
      'activeFamilyId': familyId,
      'joinedFamilyIds': [familyId],
      'isFamilyOwner': true,
      'role': 'admin',
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _datasource.saveUser(userData);

    await _datasource.addMemberToFamily(familyId, {
      'id': uid,
      'name': fullName,
      'phoneNumber': cleanPhone,
      'password': password,
      'role': 'admin',
      'relation': 'পরিবার প্রধান',
      'photoUrl': photoUrl,
      'canUpload': true,
      'canViewExpenses': true,
      'canSendPushNotification': true,
      'joinedAt': DateTime.now().toIso8601String(),
    });

    final newUser = UserEntity(
      uid: uid,
      phoneNumber: cleanPhone,
      fullName: fullName,
      photoUrl: photoUrl,
      activeFamilyId: familyId,
      joinedFamilyIds: [familyId],
      isFamilyOwner: true,
      role: 'admin',
    );

    state = newUser;
    await _persistUserSession(newUser);
  }

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    final data = await _datasource.getUserByPhone(cleanPhone);

    if (data == null) {
      throw Exception('কোনো একাউন্ট পাওয়া যায়নি! অনুগ্রহ করে আগে রেজিস্ট্রেশন করুন অথবা সঠিক নম্বর দিন।');
    }

    if (data['password'] != null && data['password'].toString() != password.trim()) {
      throw Exception('ভুল পাসওয়ার্ড! অনুগ্রহ করে সঠিক পাসওয়ার্ড দিন।');
    }

    String familyId = data['activeFamilyId']?.toString() ?? '';
    String role = data['role']?.toString() ?? 'member';
    bool isOwner = data['isFamilyOwner'] == true;

    if (familyId.isEmpty || role == 'detached') {
      familyId = 'fam_${DateTime.now().millisecondsSinceEpoch}';
      role = 'admin';
      isOwner = true;

      await _datasource.createFamily({
        'id': familyId,
        'name': '${data['fullName']} পরিবার',
        'adminId': data['uid'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
        'adminPhone': cleanPhone,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _datasource.addMemberToFamily(familyId, {
        'id': data['uid'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
        'name': data['fullName'] ?? '',
        'phoneNumber': cleanPhone,
        'password': password,
        'role': 'admin',
        'relation': 'পরিবার প্রধান',
        'photoUrl': data['photoUrl'],
        'canUpload': true,
        'canViewExpenses': true,
        'canSendPushNotification': true,
        'joinedAt': DateTime.now().toIso8601String(),
      });

      await _datasource.saveUser({
        'phoneNumber': cleanPhone,
        'activeFamilyId': familyId,
        'role': 'admin',
        'isFamilyOwner': true,
      });
    }

    final isAdmin = role == 'admin' || isOwner;

    final user = UserEntity(
      uid: data['uid']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: cleanPhone,
      fullName: data['fullName']?.toString() ?? 'পরিবার সদস্য',
      photoUrl: data['photoUrl']?.toString(),
      activeFamilyId: familyId,
      joinedFamilyIds: List<String>.from(data['joinedFamilyIds'] ?? [familyId]),
      isFamilyOwner: isOwner,
      role: role,
      canAddMembers: isAdmin ? true : (data['canAddMembers'] == true),
      canSetAlarms: isAdmin ? true : (data['canSetAlarms'] == null ? true : data['canSetAlarms'] == true),
      canSendPushNotification: isAdmin ? true : (data['canSendPushNotification'] == true),
      canViewExpenses: isAdmin ? true : (data['canViewExpenses'] == null ? true : data['canViewExpenses'] == true),
      canUpload: isAdmin ? true : (data['canUpload'] == null ? true : data['canUpload'] == true),
    );

    state = user;
    await _persistUserSession(user);
  }

  Future<void> reloadUser() async {
    if (state == null) return;
    try {
      final data = await _datasource.getUserByPhone(state!.phoneNumber);
      if (data != null && state != null) {
        final role = data['role']?.toString() ?? state!.role;
        final isOwner = data['isFamilyOwner'] == true || state!.isFamilyOwner;
        final isAdmin = role == 'admin' || isOwner;

        final updated = state!.copyWith(
          fullName: data['fullName']?.toString(),
          photoUrl: data['photoUrl']?.toString(),
          activeFamilyId: data['activeFamilyId']?.toString(),
          role: role,
          isFamilyOwner: isOwner,
          canAddMembers: isAdmin ? true : (data['canAddMembers'] == true),
          canSetAlarms: isAdmin ? true : (data['canSetAlarms'] == null ? true : data['canSetAlarms'] == true),
          canSendPushNotification: isAdmin ? true : (data['canSendPushNotification'] == true),
          canViewExpenses: isAdmin ? true : (data['canViewExpenses'] == null ? true : data['canViewExpenses'] == true),
          canUpload: isAdmin ? true : (data['canUpload'] == null ? true : data['canUpload'] == true),
        );
        state = updated;
        await _persistUserSession(updated);
      }
    } catch (e) {
      debugPrint('reloadUser error: $e');
    }
  }

  Future<void> logout() async {
    try {
      await AppDatabase().appSettingsDao.removeSetting('session_phone');
      await AppDatabase().appSettingsDao.removeSetting('session_user_json');
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Logout cleanup error: $e');
    } finally {
      state = null;
    }
  }
}

final authUserProvider = NotifierProvider<AuthUserNotifier, UserEntity?>(
  AuthUserNotifier.new,
);

