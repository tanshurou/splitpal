import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String details;

  PaymentMethod({required this.id, required this.name, required this.details});

  factory PaymentMethod.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PaymentMethod(
      id: doc.id,
      name: data['name'] as String,
      details: data['details'] as String,
    );
  }
}
