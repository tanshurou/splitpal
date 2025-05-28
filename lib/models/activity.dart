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
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      action: data['action'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      group: data['group'] ?? '',
      userId: data['userID']?.toString().trim() ?? '',
    );
  }

  /// Basic string description. You can use this if you don't want to fetch user/group names.
  String buildDescription(String currentUserId) {
    final name = userId == currentUserId ? 'You' : userId;
    switch (action) {
      case 'owes':
        return '$name owe RM${amount.toStringAsFixed(2)} in $group';
      case 'paid':
        return '$name paid RM${amount.toStringAsFixed(2)} in $group';
      default:
        return '$name $action RM${amount.toStringAsFixed(2)} in $group';
    }
  }
}
