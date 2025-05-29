import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String action; // e.g. "owes" or "paid"
  final double amount;
  final String category; // e.g. "owe", "owed", "group"
  final DateTime date;
  final String group; // this is the group ID
  final String userId; // this is the user ID

  Activity({
    required this.action,
    required this.amount,
    required this.category,
    required this.date,
    required this.group,
    required this.userId,
  });

  /// Factory constructor to build an Activity from Firestore DocumentSnapshot
  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null ||
        !data.containsKey('action') ||
        !data.containsKey('amount') ||
        !data.containsKey('category') ||
        !data.containsKey('date') ||
        !data.containsKey('group') ||
        !data.containsKey('userID')) {
      throw FormatException('Missing fields in activity document');
    }

    return Activity(
      action: data['action'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      group: data['group'] ?? '',
      userId: data['userID'].toString().trim(),
    );
  }
}
