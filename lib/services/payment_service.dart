import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_method.dart';

class PaymentService {
  PaymentService._();
  static final instance = PaymentService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _methodsRef {
    final uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('payment_methods');
  }

  Future<List<PaymentMethod>> fetchMethods() async {
    final snap = await _methodsRef.get();
    return snap.docs.map((d) => PaymentMethod.fromDoc(d)).toList();
  }

  Future<void> addMethod(String name, String number) async {
    final last4 =
        number.length >= 4 ? number.substring(number.length - 4) : number;
    final masked = '**** $last4';
    await _methodsRef.add({'name': name, 'details': masked});
  }

  Future<void> deleteMethod(String id) async {
    await _methodsRef.doc(id).delete();
  }
}
