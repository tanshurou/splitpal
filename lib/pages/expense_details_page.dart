import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseDetailsPage extends StatelessWidget {
  final String expenseId;
  const ExpenseDetailsPage({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context) {
    final expenseRef =
        FirebaseFirestore.instance.collection('expenses').doc(expenseId);

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
          final createdBy = data['createdBy'] ?? '';
          final approvalStatus = Map<String, dynamic>.from(data['approvalStatus'] ?? {});
          final paymentStatus = Map<String, dynamic>.from(data['paymentStatus'] ?? {});
          final userAmounts = Map<String, dynamic>.from(data['userAmounts'] ?? {});
          final splitAmong = List<String>.from(data['splitAmong'] ?? []);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Total Amount: RM${amount.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Text('Paid By: $paidBy'),
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
                      final oweAmount = userAmounts[uid]?.toDouble() ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text('User ID: $uid'),
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
      ),
    );
  }
}
