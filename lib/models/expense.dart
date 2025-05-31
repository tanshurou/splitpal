import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String title;
  final double amount;
  final String createdBy;
  final String paidBy;
  final String groupId;
  final String receiptURL;
  final DateTime? date;
  final List<String> splitAmong;
  final Map<String, String> approvalStatus;
  final Map<String, String> paymentStatus;
  final Map<String, double> userAmounts;

  Expense({
    required this.title,
    required this.amount,
    required this.createdBy,
    required this.paidBy,
    required this.groupId,
    required this.receiptURL,
    required this.date,
    required this.splitAmong,
    required this.approvalStatus,
    required this.paymentStatus,
    required this.userAmounts,
  });

  factory Expense.fromMap(Map<String, dynamic> data) {
    return Expense(
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      createdBy: data['createdBy'] ?? '',
      paidBy: data['paidBy'] ?? '',
      groupId: data['groupId'] ?? '',
      receiptURL: data['receiptURL'] ?? '',
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : null,
      splitAmong: List<String>.from(data['splitAmong'] ?? []),
      approvalStatus: Map<String, String>.from(data['approvalStatus'] ?? {}),
      paymentStatus: Map<String, String>.from(data['paymentStatus'] ?? {}),
      userAmounts: Map<String, double>.from(
        (data['userAmounts'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'createdBy': createdBy,
      'paidBy': paidBy,
      'groupId': groupId,
      'receiptURL': receiptURL,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'splitAmong': splitAmong,
      'approvalStatus': approvalStatus,
      'paymentStatus': paymentStatus,
      'userAmounts': userAmounts,
    };
  }
}
