import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/expense_entity.dart';
import '../models/expense_model.dart';

class ExpenseFirestoreDatasource {
  final FirestoreService _service;

  ExpenseFirestoreDatasource([FirestoreService? service])
      : _service = service ?? FirestoreService();

  Future<void> saveExpenseToFirestore(ExpenseEntity expense) async {
    final model = ExpenseModel.fromEntity(expense);
    await _service.saveDocument(
      collectionPath: 'families/${expense.familyId}/expenses',
      docId: expense.id,
      data: model.toFirestore(),
    );
  }

  Future<void> deleteExpenseFromFirestore({
    required String familyId,
    required String expenseId,
  }) async {
    await _service.deleteDocument(
      collectionPath: 'families/$familyId/expenses',
      docId: expenseId,
    );
  }

  Stream<List<ExpenseEntity>> streamExpenses(String familyId) {
    return _service
        .streamCollection(
          collectionPath: 'families/$familyId/expenses',
          orderByField: 'date',
          descending: true,
        )
        .map(
          (docs) => docs
              .map((data) => ExpenseModel.fromFirestore(data, data['id'] ?? ''))
              .toList(),
        );
  }

  Future<void> saveReminderToFirestore(String familyId, Map<String, dynamic> reminderData) async {
    final id = reminderData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _service.saveDocument(
      collectionPath: 'families/$familyId/reminders',
      docId: id,
      data: reminderData,
    );
  }

  Future<void> deleteReminderFromFirestore(String familyId, String reminderId) async {
    await _service.deleteDocument(
      collectionPath: 'families/$familyId/reminders',
      docId: reminderId,
    );
  }

  Stream<List<Map<String, dynamic>>> streamReminders(String familyId) {
    return _service.streamCollection(
      collectionPath: 'families/$familyId/reminders',
      orderByField: 'dueDate',
      descending: false,
    );
  }
}
