import '../../domain/entities/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.familyId,
    required super.type,
    required super.category,
    required super.amount,
    required super.purpose,
    required super.description,
    required super.date,
    required super.recordedByUserId,
    required super.recordedByUserName,
    super.imageUrl,
  });

  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      familyId: entity.familyId,
      type: entity.type,
      category: entity.category,
      amount: entity.amount,
      purpose: entity.purpose,
      description: entity.description,
      date: entity.date,
      recordedByUserId: entity.recordedByUserId,
      recordedByUserName: entity.recordedByUserName,
      imageUrl: entity.imageUrl,
    );
  }

  factory ExpenseModel.fromFirestore(Map<String, dynamic> json, String docId) {
    TransactionType txType;
    final typeStr = json['type'] as String?;
    if (typeStr == 'income') {
      txType = TransactionType.income;
    } else if (typeStr == 'savings') {
      txType = TransactionType.savings;
    } else {
      txType = TransactionType.expense;
    }

    return ExpenseModel(
      id: docId,
      familyId: json['familyId'] as String? ?? 'fam_01',
      type: txType,
      category: json['category'] == 'personal' ? LedgerCategory.personal : LedgerCategory.family,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      purpose: json['purpose'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['date'] as int)
          : DateTime.now(),
      recordedByUserId: json['recordedByUserId'] as String? ?? '',
      recordedByUserName: json['recordedByUserName'] as String? ?? '',
      imageUrl: json['imagePath'] as String? ?? json['imageUrl'] as String? ?? json['imageBase64'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    String typeStr;
    switch (type) {
      case TransactionType.income:
        typeStr = 'income';
        break;
      case TransactionType.savings:
        typeStr = 'savings';
        break;
      case TransactionType.expense:
        typeStr = 'expense';
        break;
    }

    return {
      'id': id,
      'familyId': familyId,
      'type': typeStr,
      'category': category == LedgerCategory.personal ? 'personal' : 'family',
      'amount': amount,
      'purpose': purpose,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'recordedByUserId': recordedByUserId,
      'recordedByUserName': recordedByUserName,
      'imagePath': imageUrl,
      'imageUrl': imageUrl,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
