// lib/models/payment_method.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String details; // always masked

  PaymentMethod({required this.id, required this.name, required this.details});

  factory PaymentMethod.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final raw = data['details'] as String;

    // re-mask to last 4 digits only
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final suffix =
        digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    final masked = '**** $suffix';

    return PaymentMethod(
      id: doc.id,
      name: data['name'] as String,
      details: masked,
    );
  }
}
