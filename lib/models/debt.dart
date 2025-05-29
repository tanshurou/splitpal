// lib/models/debt.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Debt {
  final String id;
  final String title;
  final double amount;
  final String payTo; // UID of the other user
  final String groupID;
  final String status; // 'unpaid' or 'paid'
  final Timestamp? paymentDate;

  /// True when the *current* user owes someone else
  bool get iOwe => FirebaseAuth.instance.currentUser!.uid != payTo;

  Debt({
    required this.id,
    required this.title,
    required this.amount,
    required this.payTo,
    required this.groupID,
    required this.status,
    this.paymentDate,
  });

  factory Debt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safely parse paymentDate only if it's a Timestamp
    Timestamp? parsedDate;
    final raw = data['paymentDate'];
    if (raw is Timestamp) {
      parsedDate = raw;
    } else {
      parsedDate = null;
    }

    return Debt(
      id: doc.id,
      title: data['title'] as String? ?? '(no title)',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      payTo: data['payTo'] as String? ?? '',
      groupID: data['groupID'] as String? ?? '',
      status: data['status'] as String? ?? 'unpaid',
      paymentDate: parsedDate,
    );
  }
}
