class PrivateVaultDbEntity {
  final String id;
  final String userId;
  final String category;
  final String title;
  final String secretContent;
  final int timestamp;

  const PrivateVaultDbEntity({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.secretContent,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'title': title,
      'secretContent': secretContent,
      'timestamp': timestamp,
    };
  }

  factory PrivateVaultDbEntity.fromMap(Map<String, dynamic> map) {
    return PrivateVaultDbEntity(
      id: map['id'] as String,
      userId: map['userId'] as String,
      category: map['category'] as String,
      title: map['title'] as String,
      secretContent: map['secretContent'] as String,
      timestamp: map['timestamp'] as int,
    );
  }
}
