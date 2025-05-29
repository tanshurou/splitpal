import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CurrencyService {
  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();

  // List of supported currency codes
  final List<String> supported = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'RM'];

  // Currently selected currency (defaults to USD)
  String _current = 'USD';
  String get current => _current;

  /// Load the saved currency from Firestore (if any).
  Future<void> loadCurrency() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (data.containsKey('currency') &&
          supported.contains(data['currency'])) {
        _current = data['currency'];
      }
    }
  }

  /// Update the local value *and* write it back to Firestore.
  Future<void> updateCurrency(String newCurrency) async {
    if (!supported.contains(newCurrency)) return;
    _current = newCurrency;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'currency': newCurrency,
    });
  }
}
