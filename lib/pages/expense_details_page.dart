import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseDetailsPage extends StatelessWidget {
  final String expenseId;
  const ExpenseDetailsPage({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context) {
    final expenseRef = FirebaseFirestore.instance.collection('expenses').doc(expenseId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF4F3FD),
      body: FutureBuilder<DocumentSnapshot>(
        future: expenseRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text("Expense not found"));

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final title = data['title'] ?? 'Untitled';
          final amount = data['amount']?.toDouble() ?? 0;
          final paidBy = data['paidBy'] ?? '';
          final approvalStatus = Map<String, dynamic>.from(data['approvalStatus'] ?? {});
          final paymentStatus = Map<String, dynamic>.from(data['paymentStatus'] ?? {});
          final splitAmong = List<String>.from(data['splitAmong'] ?? []);

          // Fetch usernames
          return FutureBuilder<Map<String, String>>(
            future: _fetchUserNames(splitAmong),
            builder: (context, namesSnapshot) {
              if (!namesSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userNames = namesSnapshot.data!;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Total Amount: RM${amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    // Display fullName for paidBy
                    Text('Paid By: ${userNames[paidBy] ?? paidBy}'),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('Participants:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: splitAmong.length,
                        itemBuilder: (context, index) {
                          final uid = splitAmong[index];
                          final approve = approvalStatus[uid] ?? 'pending';
                          final paid = paymentStatus[uid] ?? 'unpaid';
                          final oweAmount = data['userAmounts'][uid]?.toDouble() ?? 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text('User: ${userNames[uid] ?? uid}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Approval Status: $approve'),
                                  Text('Payment Status: $paid'),
                                  Text('Amount: RM${oweAmount.toStringAsFixed(2)}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Fetch the usernames of the users involved in the expense
  Future<Map<String, String>> _fetchUserNames(List<String> userIds) async {
    final userNames = <String, String>{};
    for (var userId in userIds) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        userNames[userId] = userDoc.data()?['fullName'] ?? userId;
      }
    }
    return userNames;
  }
}
