class ExpenseReminder {
  final String id;
  final String title;
  final double amount;
  final String targetPerson;
  final String purpose;
  final DateTime dueDate;
  final String details;
  final bool isResolved;
  final String alarmTime;

  const ExpenseReminder({
    required this.id,
    required this.title,
    required this.amount,
    required this.targetPerson,
    required this.purpose,
    required this.dueDate,
    required this.details,
    this.isResolved = false,
    this.alarmTime = '09:00 AM',
  });

  ExpenseReminder copyWith({
    String? id,
    String? title,
    double? amount,
    String? targetPerson,
    String? purpose,
    DateTime? dueDate,
    String? details,
    bool? isResolved,
    String? alarmTime,
  }) {
    return ExpenseReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      targetPerson: targetPerson ?? this.targetPerson,
      purpose: purpose ?? this.purpose,
      dueDate: dueDate ?? this.dueDate,
      details: details ?? this.details,
      isResolved: isResolved ?? this.isResolved,
      alarmTime: alarmTime ?? this.alarmTime,
    );
  }
}
