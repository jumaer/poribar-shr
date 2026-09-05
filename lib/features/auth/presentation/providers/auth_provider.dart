import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../../family_management/data/datasources/family_firestore_datasource.dart';

class AuthUserNotifier extends Notifier<UserEntity?> {
  final FamilyFirestoreDatasource _datasource = FamilyFirestoreDatasource();

  @override
  UserEntity? build() {
    return null;
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
      throw Exception('এই ফোন নম্বরে ইতিমধ্যে একাউন্ট রয়েছে, অনুগ্রহ করে লগইন করুন!');
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
      'role': 'admin',
      'relation': 'পরিবার প্রধান',
      'photoUrl': photoUrl,
      'canUpload': true,
      'canViewExpenses': true,
      'canSendPushNotification': true,
      'joinedAt': DateTime.now().toIso8601String(),
    });

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
      throw Exception('কোনো একাউন্ট পাওয়া যায়নি! অনুগ্রহ করে আগে রেজিস্ট্রেশন করুন।');
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

    state = UserEntity(
      uid: data['uid']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: cleanPhone,
      fullName: data['fullName']?.toString() ?? 'পরিবার সদস্য',
      photoUrl: data['photoUrl']?.toString(),
      activeFamilyId: familyId,
      joinedFamilyIds: List<String>.from(data['joinedFamilyIds'] ?? [familyId]),
      isFamilyOwner: isOwner,
      role: role,
    );
  }

  Future<void> reloadUser() async {
    if (state == null) return;
    final data = await _datasource.getUserByPhone(state!.phoneNumber);
    if (data != null) {
      state = state!.copyWith(
        fullName: data['fullName']?.toString(),
        photoUrl: data['photoUrl']?.toString(),
        activeFamilyId: data['activeFamilyId']?.toString(),
        role: data['role']?.toString(),
        isFamilyOwner: data['isFamilyOwner'] == true,
      );
    }
  }

  void logout() {
    state = null;
  }
}

final authUserProvider = NotifierProvider<AuthUserNotifier, UserEntity?>(
  AuthUserNotifier.new,
);
