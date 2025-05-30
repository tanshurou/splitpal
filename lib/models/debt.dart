import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Debt {
  final String id;
  final String title;
  final double amount;
  final String payTo;
  final String groupID;
  final String status;
  final String expenseID; // ← NEW!
  final Timestamp? paymentDate;

  bool get iOwe => FirebaseAuth.instance.currentUser!.uid != payTo;

  Debt({
    required this.id,
    required this.title,
    required this.amount,
    required this.payTo,
    required this.groupID,
    required this.status,
    required this.expenseID,
    this.paymentDate,
  });

  factory Debt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;

    // safely parse paymentDate
    Timestamp? parsedDate;
    final rawDate = data['paymentDate'];
    if (rawDate is Timestamp) parsedDate = rawDate;

    return Debt(
      id: doc.id,
      title: data['title'] as String? ?? '(no title)',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      payTo: data['payTo'] as String? ?? '',
      groupID: data['groupID'] as String? ?? '',
      status: data['status'] as String? ?? 'unpaid',
      expenseID: data['expenseID'] as String? ?? '', // ← NEW!
      paymentDate: parsedDate,
    );
  }
}
