import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/user_entity.dart';
import '../../../family_management/data/datasources/family_firestore_datasource.dart';

class AuthUserNotifier extends Notifier<UserEntity?> {
  final FamilyFirestoreDatasource _datasource = FamilyFirestoreDatasource();

  @override
  UserEntity? build() {
    return null;
  }

  Future<bool> tryAutoLogin() async {
    try {
      final savedPhone = await AppDatabase().appSettingsDao.getSetting('session_phone');
      if (savedPhone != null && savedPhone.isNotEmpty) {
        final data = await _datasource.getUserByPhone(savedPhone);
        if (data != null) {
          final familyId = data['activeFamilyId']?.toString() ?? '';
          if (familyId.isNotEmpty) {
            final role = data['role']?.toString() ?? 'member';
            final isOwner = data['isFamilyOwner'] == true;
            final isAdmin = role == 'admin' || isOwner;

            state = UserEntity(
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
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('Auto login error: $e');
    }
    return false;
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

    await AppDatabase().appSettingsDao.setSetting('session_phone', cleanPhone);

    state = UserEntity(
      uid: uid,
      phoneNumber: cleanPhone,
      fullName: fullName,
      photoUrl: photoUrl,
      activeFamilyId: familyId,
      joinedFamilyIds: [familyId],
      isFamilyOwner: true,
      role: 'admin',
    );
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

    await AppDatabase().appSettingsDao.setSetting('session_phone', cleanPhone);

    final isAdmin = role == 'admin' || isOwner;

    state = UserEntity(
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
  }

  Future<void> reloadUser() async {
    if (state == null) return;
    final data = await _datasource.getUserByPhone(state!.phoneNumber);
    if (data != null) {
      final role = data['role']?.toString() ?? state!.role;
      final isOwner = data['isFamilyOwner'] == true || state!.isFamilyOwner;
      final isAdmin = role == 'admin' || isOwner;

      state = state!.copyWith(
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
    }
  }

  void logout() {
    AppDatabase().appSettingsDao.removeSetting('session_phone');
    state = null;
  }
}

final authUserProvider = NotifierProvider<AuthUserNotifier, UserEntity?>(
  AuthUserNotifier.new,
);
