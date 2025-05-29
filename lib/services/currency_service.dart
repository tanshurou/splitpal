import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CurrencyService {
  // Singleton
  static final CurrencyService instance = CurrencyService._internal();
  CurrencyService._internal();
  factory CurrencyService() => instance;

  /// Supported currencies & their USD exchange rates
  static const supported = ['\$', '€', 'RM'];
  static const Map<String, double> _rates = {
    '\$': 1.0, // USD base
    '€': 0.92, // 1 USD = 0.92 EUR
    'RM': 4.50, // 1 USD = 4.50 MYR
  };

  String _current = supported.first;
  String get current => _current;
  double get rate => _rates[_current] ?? 1.0;
  String symbolFor(double usdAmount) {
    final converted = usdAmount * rate;
    return '$current${converted.toStringAsFixed(2)}';
  }

  final _db = FirebaseFirestore.instance;
  String? _userDocId;

  Future<String> _resolveUserDocId() async {
    if (_userDocId != null) return _userDocId!;
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || me.email == null) throw Exception('Not authenticated');

    final snap =
        await _db
            .collection('users')
            .where('email', isEqualTo: me.email)
            .limit(1)
            .get();

    if (snap.docs.isNotEmpty) {
      _userDocId = snap.docs.first.id;
    } else {
      _userDocId = me.uid;
      await _db.collection('users').doc(_userDocId).set({
        'email': me.email,
        'fullName': me.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return _userDocId!;
  }

  Future<void> loadCurrency() async {
    final docId = await _resolveUserDocId();
    final snap = await _db.collection('users').doc(docId).get();
    final data = snap.data() ?? {};
    final c = data['currency'] as String?;
    if (c != null && supported.contains(c)) {
      _current = c;
    }
  }

  Future<void> updateCurrency(String newCurrency) async {
    if (!supported.contains(newCurrency)) return;
    _current = newCurrency;

    final docId = await _resolveUserDocId();
    final ref = _db.collection('users').doc(docId);

    try {
      await ref.update({'currency': newCurrency});
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        await ref.set({'currency': newCurrency}, SetOptions(merge: true));
      } else {
        rethrow;
      }
    }
  }
}
