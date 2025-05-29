import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/debt.dart';

class DebtService {
  final _db = FirebaseFirestore.instance;
  String? _userDocId;

  /// 1) Resolve (and cache) the Firestore doc-ID for the signed-in user
  Future<String> _getUserDocId() async {
    if (_userDocId != null) return _userDocId!;

    final me = FirebaseAuth.instance.currentUser;
    if (me == null || me.email == null) {
      throw Exception('Not authenticated');
    }

    // Look up by email
    final snap =
        await _db
            .collection('users')
            .where('email', isEqualTo: me.email)
            .limit(1)
            .get();

    if (snap.docs.isNotEmpty) {
      _userDocId = snap.docs.first.id;
      print(
        '⤷ [DebtService] mapped auth-email ${me.email} → docID=$_userDocId',
      );
    } else {
      // Fallback: create a user-doc under auth UID
      _userDocId = me.uid;
      await _db.collection('users').doc(_userDocId).set({
        'email': me.email,
        'fullName': me.displayName ?? '',
        'friends': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print(
        '⤷ [DebtService] no existing doc for ${me.email}, created new docID=$_userDocId',
      );
    }

    return _userDocId!;
  }

  /// 2) Fetch unpaid debts under users/{docId}/debt
  Future<List<Debt>> fetchDebts() async {
    final uid = await _getUserDocId();
    print('⤷ [DebtService] loading debts for Firestore user-doc: $uid');

    final coll = _db.collection('users').doc(uid).collection('debt');
    final snap = await coll.where('status', isEqualTo: 'unpaid').get();

    print(
      '⤷ [DebtService] found ${snap.docs.length} unpaid debts: '
      '${snap.docs.map((d) => d.id).toList()}',
    );

    return snap.docs.map((d) => Debt.fromFirestore(d)).toList();
  }

  /// 3) Settle a debt: batch-update debt.status, your userSummary, their userSummary, and groupSummary
  Future<void> settleDebt(Debt debt) async {
    final uid = await _getUserDocId();
    final batch = _db.batch();

    // mark debt paid
    final debtRef = _db
        .collection('users')
        .doc(uid)
        .collection('debt')
        .doc(debt.id);
    batch.update(debtRef, {
      'status': 'paid',
      'paymentDate': FieldValue.serverTimestamp(),
    });

    // your summary: owe -= amount
    final mySumRef = _db
        .collection('users')
        .doc(uid)
        .collection('userSummary')
        .doc('userSummary');
    batch.update(mySumRef, {'owe': FieldValue.increment(-debt.amount)});

    // their summary: owed -= amount
    final theirSumRef = _db
        .collection('users')
        .doc(debt.payTo)
        .collection('userSummary')
        .doc('userSummary');
    batch.update(theirSumRef, {'owed': FieldValue.increment(-debt.amount)});

    // group summary
    final grpSumRef = _db
        .collection('group')
        .doc(debt.groupID)
        .collection('groupSummary')
        .doc('groupSummary');
    batch.update(grpSumRef, {
      'settleDebts': FieldValue.increment(1),
      'unsettledDebts': FieldValue.increment(-1),
    });

    await batch.commit();
    print(
      '⤷ [DebtService] settled debt ${debt.id} for $uid; updated summaries.',
    );
  }
}
