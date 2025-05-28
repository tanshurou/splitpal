// lib/services/payment_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_method.dart'; // ← import the model here

class PaymentService {
  PaymentService._();
  static final instance = PaymentService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _methodsRef {
    final uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('payment_methods');
  }

  /// Fetches all saved payment methods for the current user.
  Future<List<PaymentMethod>> fetchMethods() async {
    final snap = await _methodsRef.get();
    return snap.docs.map((d) => PaymentMethod.fromDoc(d)).toList();
  }

  /// Adds a new method, storing only the last-4 digits as "**** 1234".
  Future<void> addMethod(String name, String rawNumber) {
    final digits = rawNumber.replaceAll(RegExp(r'\D'), '');
    final suffix =
        digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    final masked = '**** $suffix';

    return _methodsRef.add({'name': name, 'details': masked});
  }

  /// Deletes the method with the given Firestore document ID.
  Future<void> deleteMethod(String id) {
    return _methodsRef.doc(id).delete();
  }
}
