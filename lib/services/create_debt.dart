import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> checkAndCreateDebts(String expenseId) async {
  final expenseRef = FirebaseFirestore.instance
      .collection('expenses')
      .doc(expenseId);
  final expenseSnapshot = await expenseRef.get();

  if (!expenseSnapshot.exists) return;

  final data = expenseSnapshot.data()!;
  final approvalStatus = Map<String, dynamic>.from(data['approvalStatus']);
  final paymentStatus = Map<String, dynamic>.from(data['paymentStatus']);
  final userAmounts = Map<String, dynamic>.from(data['userAmounts']);
  final splitAmong = List<String>.from(data['splitAmong']);
  final paidBy = data['paidBy'];
  final createdBy = data['createdBy'];
  final groupId = data['groupId'];
  final title = data['title'];
  final amount = data['amount']?.toDouble() ?? 0;
  final Timestamp date = data['date'];

  // ✅ Ensure all users approved
  final allApproved = approvalStatus.values.every(
    (status) => status == 'approved',
  );
  if (!allApproved) return;

  final batch = FirebaseFirestore.instance.batch();

  for (final uid in splitAmong) {
    final debtAmount = (userAmounts[uid] ?? 0).toDouble();
    final isPayer = uid == paidBy;

    if (!isPayer) {
      // 📜 Log activity for debtor
      final activityRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('activityLog')
              .doc();

      batch.set(activityRef, {
        'action': 'owe',
        'amount': debtAmount,
        'category': 'owe',
        'date': date,
        'group': groupId,
        'userID': uid,
      });

      // 🧾 Add debt document
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
        'paymentDate': null,
        'paymentMethod': 'card',
        'status': 'unpaid',
        'title': title,
      });

      // 🔢 Update userSummary for debtor
      final userSummaryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('userSummary')
          .doc('userSummary');

      batch.set(userSummaryRef, {
        'owe': FieldValue.increment(debtAmount),
      }, SetOptions(merge: true));
    }

    // 💸 Log activity for payer (once per debtor)
    if (!isPayer) {
      final payerActivityRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(paidBy)
              .collection('activityLog')
              .doc();

      batch.set(payerActivityRef, {
        'action': 'paid',
        'amount': debtAmount,
        'category': 'owe',
        'date': date,
        'group': groupId,
        'userID': paidBy,
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

  // 📊 Update group summary
  final groupSummaryRef = FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('groupSummary')
      .doc('groupSummary');

  batch.set(groupSummaryRef, {
    'totalDebts': FieldValue.increment(splitAmong.length - 1),
    'unsettledDebts': FieldValue.increment(splitAmong.length - 1),
  }, SetOptions(merge: true));

  // ✅ Prevent future duplication
  batch.update(expenseRef, {
    'approvalStatus': {
      for (var uid in approvalStatus.keys) uid: 'debt_created',
    },
  });

  await batch.commit();
}
