class TransactionDbEntity {
  final String id;
  final String familyId;
  final String type;
  final String category;
  final double amount;
  final String purpose;
  final String description;
  final int timestamp;
  final String recordedByUserId;
  final String recordedByUserName;
  final String? imageBase64;
  final int lastModified;

  const TransactionDbEntity({
    required this.id,
    required this.familyId,
    required this.type,
    required this.category,
    required this.amount,
    required this.purpose,
    required this.description,
    required this.timestamp,
    required this.recordedByUserId,
    required this.recordedByUserName,
    this.imageBase64,
    required this.lastModified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'type': type,
      'category': category,
      'amount': amount,
      'purpose': purpose,
      'description': description,
      'timestamp': timestamp,
      'recordedByUserId': recordedByUserId,
      'recordedByUserName': recordedByUserName,
      'imageBase64': imageBase64,
      'lastModified': lastModified,
    };
  }

  factory TransactionDbEntity.fromMap(Map<String, dynamic> map) {
    return TransactionDbEntity(
      id: map['id'] as String,
      familyId: map['familyId'] as String,
      type: map['type'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      purpose: map['purpose'] as String,
      description: map['description'] as String,
      timestamp: map['timestamp'] as int,
      recordedByUserId: map['recordedByUserId'] as String,
      recordedByUserName: map['recordedByUserName'] as String,
      imageBase64: map['imageBase64'] as String?,
      lastModified: map['lastModified'] as int? ?? map['timestamp'] as int,
    );
  }
}
