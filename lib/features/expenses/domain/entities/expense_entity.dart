enum LedgerCategory { personal, family }
enum TransactionType { expense, income, savings, loanGiven, loanTaken }

class ExpenseEntity {
  final String id;
  final String familyId;
  final TransactionType type;
  final LedgerCategory category;
  final double amount;
  final String purpose;
  final String description;
  final DateTime date;
  final String recordedByUserId;
  final String recordedByUserName;
  final String? imageUrl;

  const ExpenseEntity({
    required this.id,
    required this.familyId,
    required this.type,
    required this.category,
    required this.amount,
    required this.purpose,
    required this.description,
    required this.date,
    required this.recordedByUserId,
    required this.recordedByUserName,
    this.imageUrl,
  });

  ExpenseEntity copyWith({
    String? id,
    String? familyId,
    TransactionType? type,
    LedgerCategory? category,
    double? amount,
    String? purpose,
    String? description,
    DateTime? date,
    String? recordedByUserId,
    String? recordedByUserName,
    String? imageUrl,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      purpose: purpose ?? this.purpose,
      description: description ?? this.description,
      date: date ?? this.date,
      recordedByUserId: recordedByUserId ?? this.recordedByUserId,
      recordedByUserName: recordedByUserName ?? this.recordedByUserName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
