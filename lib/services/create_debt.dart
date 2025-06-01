import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> checkAndCreateDebts(String expenseId) async {
  final expenseRef = FirebaseFirestore.instance
      .collection('expenses')
      .doc(expenseId);
  final expenseSnapshot = await expenseRef.get();

  if (!expenseSnapshot.exists) return;

  final data = expenseSnapshot.data()!;
  final approvalStatus = Map<String, dynamic>.from(data['approvalStatus']);
  final userAmounts = Map<String, dynamic>.from(data['userAmounts']);
  final splitAmong = List<String>.from(data['splitAmong']);
  final paidBy = data['paidBy'];
  final groupId = data['groupId'];
  final title = data['title'];
  final Timestamp date = data['date'];

  // Check if all are approved
  final allApproved = approvalStatus.values.every(
    (status) => status == 'approved',
  );
  if (!allApproved) return;

  final batch = FirebaseFirestore.instance.batch();

  // Does not create debt for payer
  for (final uid in splitAmong) {
    final debtAmount = (userAmounts[uid] ?? 0).toDouble();
    final isPayer = uid == paidBy;

    // Debtor Activity (for non-payers)
    if (!isPayer) {
      final activityRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('activityLog')
              .doc();
      batch.set(activityRef, {
        'action': 'unpaid',
        'amount': debtAmount,
        'category': 'owe',
        'date': date,
        'group': groupId,
        'userID': paidBy,
        'expenseID': expenseId,
      });

      final debtRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('debt')
              .doc();
      batch.set(debtRef, {
        'amount': debtAmount,
        'groupID': groupId,
        'payTo': paidBy,
        'paymentDate': date,
        'paymentMethod': 'card',
        'status': 'unpaid',
        'title': title,
        'expenseID': expenseId,
      });

      final userSummaryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('userSummary')
          .doc('userSummary');
      batch.set(userSummaryRef, {
        'owe': FieldValue.increment(debtAmount),
      }, SetOptions(merge: true));

      // Payer's owed activity (for each debtor)
      final payerOwedRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(paidBy)
              .collection('activityLog')
              .doc();
      batch.set(payerOwedRef, {
        'action': 'unpaid',
        'amount': debtAmount,
        'category': 'owed',
        'date': date,
        'group': groupId,
        'userID': uid,
        'expenseID': expenseId,
      });

      final payerSummaryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(paidBy)
          .collection('userSummary')
          .doc('userSummary');
      batch.set(payerSummaryRef, {
        'owed': FieldValue.increment(debtAmount),
      }, SetOptions(merge: true));
    }
  }

  final groupSummaryRef = FirebaseFirestore.instance
      .collection('group')
      .doc(groupId)
      .collection('groupSummary')
      .doc('groupSummary');

  batch.set(groupSummaryRef, {
    'totalDebts': FieldValue.increment(splitAmong.length - 1),
    'unsettledDebts': FieldValue.increment(splitAmong.length - 1),
  }, SetOptions(merge: true));

  // Update approvalStatus to prevent duplicate creation
  batch.update(expenseRef, {
    'approvalStatus': {
      for (var uid in approvalStatus.keys) uid: 'debt created',
    },
    // Optional: also update payer's payment status
    'paymentStatus.$paidBy': 'paid',
  });

  await batch.commit();
}
