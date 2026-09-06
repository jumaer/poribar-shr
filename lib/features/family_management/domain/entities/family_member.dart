class FamilyMember {
  final String id;
  final String name;
  final String role;
  final String relation;
  final String phoneNumber;
  final bool canUpload;
  final bool canViewExpenses;
  final bool canSendPushNotification;
  final bool canAddMembers;
  final bool canSetAlarms;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.role,
    required this.relation,
    required this.phoneNumber,
    this.canUpload = true,
    this.canViewExpenses = true,
    this.canSendPushNotification = false,
    this.canAddMembers = false,
    this.canSetAlarms = true,
  });

  bool get isAdmin => role == 'admin' || role == 'owner';

  FamilyMember copyWith({
    String? id,
    String? name,
    String? role,
    String? relation,
    String? phoneNumber,
    bool? canUpload,
    bool? canViewExpenses,
    bool? canSendPushNotification,
    bool? canAddMembers,
    bool? canSetAlarms,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      relation: relation ?? this.relation,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      canUpload: canUpload ?? this.canUpload,
      canViewExpenses: canViewExpenses ?? this.canViewExpenses,
      canSendPushNotification: canSendPushNotification ?? this.canSendPushNotification,
      canAddMembers: canAddMembers ?? this.canAddMembers,
      canSetAlarms: canSetAlarms ?? this.canSetAlarms,
    );
  }
}
