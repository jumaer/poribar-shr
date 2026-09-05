class FamilyMember {
  final String id;
  final String name;
  final String role;
  final String relation;
  final String phoneNumber;
  final bool canUpload;
  final bool canViewExpenses;
  final bool canSendPushNotification;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.role,
    required this.relation,
    required this.phoneNumber,
    this.canUpload = true,
    this.canViewExpenses = true,
    this.canSendPushNotification = false,
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
    );
  }
}
