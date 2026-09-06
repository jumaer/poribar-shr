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
