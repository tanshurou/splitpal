import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

/// Shared method to generate the next expense ID like E001, E002, ...
Future<String> getNextExpenseId() async {
  final snapshot =
      await FirebaseFirestore.instance
          .collection('expenses')
          .orderBy(FieldPath.documentId)
          .get();

  int maxId = 0;
  for (var doc in snapshot.docs) {
    final id = doc.id;
    if (id.startsWith('E')) {
      final numPart = int.tryParse(id.substring(1));
      if (numPart != null && numPart > maxId) {
        maxId = numPart;
      }
    }
  }
  return 'E${(maxId + 1).toString().padLeft(3, '0')}';
}

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Saves an expense and logs the bill split request in the group's activity log.
  Future<String> saveExpense({required Expense expense}) async {
    final expenseId = await getNextExpenseId();
    final activityId = 'A${DateTime.now().millisecondsSinceEpoch}';
    final now = Timestamp.now();

    // Save the expense document
    await _db.collection('expenses').doc(expenseId).set({
      ...expense.toMap(),
      'expenseId': expenseId,
    });

    // Log the activity in the group's activity log
    await _db
        .collection('group')
        .doc(expense.groupId)
        .collection('activityLog')
        .doc(activityId)
        .set({
          'type': 'bill_split_request',
          'activityId': activityId,
          'expenseId': expenseId,
          'title': expense.title,
          'createdBy': expense.createdBy,
          'timestamp': now,
          'amount': expense.amount,
          'splitAmong': expense.splitAmong,
          'approvalStatus': expense.approvalStatus,
        });

    return expenseId;
  }

  /// Fetches a specific expense from Firestore.
  Future<Expense?> fetchExpense(String expenseId) async {
    final doc = await _db.collection('expenses').doc(expenseId).get();
    if (doc.exists) {
      return Expense.fromMap(doc.data()!);
    }
    return null;
  }
}
