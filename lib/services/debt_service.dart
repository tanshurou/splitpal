import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/debt.dart';

class DebtService {
  final _db = FirebaseFirestore.instance;
  String? _userDocId;

  /// Resolve (and cache) the Firestore doc-ID for the signed-in user.
  Future<String> _getUserDocId() async {
    if (_userDocId != null) return _userDocId!;
    final me = FirebaseAuth.instance.currentUser!;
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
        'friends': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return _userDocId!;
  }

  /// Fetch one-time list of unpaid debts.
  Future<List<Debt>> fetchDebts() async {
    final uid = await _getUserDocId();
    final snap =
        await _db
            .collection('users')
            .doc(uid)
            .collection('debt')
            .where('status', isEqualTo: 'unpaid')
            .get();
    return snap.docs.map((d) => Debt.fromFirestore(d)).toList();
  }

  /// Real‐time stream of unpaid debts—UI will update automatically.
  Stream<List<Debt>> streamDebts() async* {
    final uid = await _getUserDocId();
    yield* _db
        .collection('users')
        .doc(uid)
        .collection('debt')
        .where('status', isEqualTo: 'unpaid')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Debt.fromFirestore(d)).toList());
  }

  /// Settle a debt and atomically update:
  ///  • the debt doc,
  ///  • both users’ summaries,
  ///  • the group summary,
  ///  • **AND** mark this user as paid in `expenses/{expenseID}.paymentStatus.{uid}`.
  Future<void> settleDebt(Debt debt) async {
    final meId = await _getUserDocId();
    final batch = _db.batch();

    // 1) Mark this debt paid
    batch.update(
      _db.collection('users').doc(meId).collection('debt').doc(debt.id),
      {'status': 'paid', 'paymentDate': FieldValue.serverTimestamp()},
    );

    // 2) Decrement your owe
    batch.update(
      _db
          .collection('users')
          .doc(meId)
          .collection('userSummary')
          .doc('userSummary'),
      {'owe': FieldValue.increment(-debt.amount)},
    );

    // 3) Decrement their owed
    batch.update(
      _db
          .collection('users')
          .doc(debt.payTo)
          .collection('userSummary')
          .doc('userSummary'),
      {'owed': FieldValue.increment(-debt.amount)},
    );

    // 4) Update group summary
    batch.update(
      _db
          .collection('group')
          .doc(debt.groupID)
          .collection('groupSummary')
          .doc('groupSummary'),
      {
        'settleDebts': FieldValue.increment(1),
        'unsettledDebts': FieldValue.increment(-1),
      },
    );

    // 5) Mark this user as paid in the master expense doc
    batch.update(_db.collection('expenses').doc(debt.expenseID), {
      'paymentStatus.$meId': 'paid',
    });

    // Commit all at once
    await batch.commit();
  }
}
