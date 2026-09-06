import 'dart:convert';

class UserEntity {
  final String uid;
  final String phoneNumber;
  final String fullName;
  final String? photoUrl;
  final String activeFamilyId;
  final List<String> joinedFamilyIds;
  final bool isFamilyOwner;
  final String role;
  final bool canAddMembers;
  final bool canSetAlarms;
  final bool canSendPushNotification;
  final bool canViewExpenses;
  final bool canUpload;

  const UserEntity({
    required this.uid,
    required this.phoneNumber,
    required this.fullName,
    this.photoUrl,
    required this.activeFamilyId,
    required this.joinedFamilyIds,
    this.isFamilyOwner = false,
    this.role = 'admin',
    this.canAddMembers = true,
    this.canSetAlarms = true,
    this.canSendPushNotification = true,
    this.canViewExpenses = true,
    this.canUpload = true,
  });

  bool get isAdmin => role == 'admin' || isFamilyOwner;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'activeFamilyId': activeFamilyId,
      'joinedFamilyIds': joinedFamilyIds,
      'isFamilyOwner': isFamilyOwner,
      'role': role,
      'canAddMembers': canAddMembers,
      'canSetAlarms': canSetAlarms,
      'canSendPushNotification': canSendPushNotification,
      'canViewExpenses': canViewExpenses,
      'canUpload': canUpload,
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    final familyId = map['activeFamilyId']?.toString() ?? '';
    final role = map['role']?.toString() ?? 'member';
    final isOwner = map['isFamilyOwner'] == true || map['isFamilyOwner'] == 1;
    final isAdmin = role == 'admin' || isOwner;

    List<String> families = [];
    if (map['joinedFamilyIds'] is List) {
      families = (map['joinedFamilyIds'] as List).map((e) => e.toString()).toList();
    }
    if (families.isEmpty && familyId.isNotEmpty) {
      families = [familyId];
    }

    return UserEntity(
      uid: map['uid']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString(),
      activeFamilyId: familyId,
      joinedFamilyIds: families,
      isFamilyOwner: isOwner,
      role: role,
      canAddMembers: isAdmin ? true : (map['canAddMembers'] == true || map['canAddMembers'] == 1),
      canSetAlarms: isAdmin ? true : (map['canSetAlarms'] == null ? true : (map['canSetAlarms'] == true || map['canSetAlarms'] == 1)),
      canSendPushNotification: isAdmin ? true : (map['canSendPushNotification'] == true || map['canSendPushNotification'] == 1),
      canViewExpenses: isAdmin ? true : (map['canViewExpenses'] == null ? true : (map['canViewExpenses'] == true || map['canViewExpenses'] == 1)),
      canUpload: isAdmin ? true : (map['canUpload'] == null ? true : (map['canUpload'] == true || map['canUpload'] == 1)),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserEntity.fromJson(String source) =>
      UserEntity.fromMap(json.decode(source) as Map<String, dynamic>);

  UserEntity copyWith({
    String? uid,
    String? phoneNumber,
    String? fullName,
    String? photoUrl,
    String? activeFamilyId,
    List<String>? joinedFamilyIds,
    bool? isFamilyOwner,
    String? role,
    bool? canAddMembers,
    bool? canSetAlarms,
    bool? canSendPushNotification,
    bool? canViewExpenses,
    bool? canUpload,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      activeFamilyId: activeFamilyId ?? this.activeFamilyId,
      joinedFamilyIds: joinedFamilyIds ?? this.joinedFamilyIds,
      isFamilyOwner: isFamilyOwner ?? this.isFamilyOwner,
      role: role ?? this.role,
      canAddMembers: canAddMembers ?? this.canAddMembers,
      canSetAlarms: canSetAlarms ?? this.canSetAlarms,
      canSendPushNotification: canSendPushNotification ?? this.canSendPushNotification,
      canViewExpenses: canViewExpenses ?? this.canViewExpenses,
      canUpload: canUpload ?? this.canUpload,
    );
  }
}
