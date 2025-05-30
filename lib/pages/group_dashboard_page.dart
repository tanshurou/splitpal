import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:splitpal/pages/expense_details_page.dart';

class GroupDashboardPage extends StatefulWidget {
  final String groupId;
  const GroupDashboardPage({super.key, required this.groupId});

  @override
  State<GroupDashboardPage> createState() => _GroupDashboardPageState();
}

class _GroupDashboardPageState extends State<GroupDashboardPage> {
  bool showSplit = true;
  String? currentUserId;
  Map<String, String> userNames = {};
  List<String> groupMembers = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchGroupMembers();
  }

  Future<void> _fetchCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (userSnap.docs.isEmpty) return;

    setState(() {
      currentUserId = userSnap.docs.first.id;
    });

    final allUsers = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      userNames = {
        for (var doc in allUsers.docs)
          doc.id: (doc.data()['fullName'] ?? doc.id) as String,
      };
    });
  }

  Future<void> _fetchGroupMembers() async {
    final groupDoc = await FirebaseFirestore.instance
        .collection('group')
        .doc(widget.groupId)
        .get();

    if (groupDoc.exists) {
      setState(() {
        groupMembers = List<String>.from(groupDoc.data()?['members'] ?? []);
      });
    }
  }

  Future<Map<String, double>> _calculateUserUnpaidAmounts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('groupId', isEqualTo: widget.groupId)
        .get();

    final Map<String, double> userTotals = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final paymentStatus = Map<String, dynamic>.from(data['paymentStatus'] ?? {});
      final userAmounts = Map<String, dynamic>.from(data['userAmounts'] ?? {});

      for (var entry in paymentStatus.entries) {
        if (entry.value == 'unpaid') {
          final uid = entry.key;
          final amount = (userAmounts[uid] ?? 0).toDouble();
          userTotals[uid] = (userTotals[uid] ?? 0) + amount;
        }
      }
    }

    return userTotals;
  }

  // Function to handle leaving the group with confirmation
  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Are you sure you want to leave?"),
        content: const Text("Please confirm that you want to leave the group."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Leave"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final groupRef = FirebaseFirestore.instance.collection('group').doc(widget.groupId);
      await groupRef.update({
        'members': FieldValue.arrayRemove([currentUserId]), // Remove the user from the group
      });

      setState(() {
        groupMembers.remove(currentUserId); // Update the UI to reflect leaving the group
      });
      Navigator.pop(context); // Close the page after leaving the group.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final expensesQuery = FirebaseFirestore.instance
        .collection('expenses')
        .where('groupId', isEqualTo: widget.groupId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF4F3FD),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<Map<String, double>>(
              future: _calculateUserUnpaidAmounts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 180);

                final data = snapshot.data!;
                final total = data.values.fold(0.0, (a, b) => a + b);
                final colors = [const Color(0xFF90EE90), const Color(0xFFFFC0CB)];

                final pieSections = <PieChartSectionData>[];
                int colorIndex = 0;

                for (var entry in data.entries) {
                  final uid = entry.key;
                  final name = userNames[uid] ?? uid;
                  final amount = entry.value;
                  pieSections.add(
                    PieChartSectionData(
                      color: colors[colorIndex % colors.length],
                      value: amount,
                      radius: 50,
                      title: '$name\nRM${amount.toStringAsFixed(0)}',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                  colorIndex++;
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('RM${total.toStringAsFixed(2)} unpaid debt',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 40,
                            sections: pieSections,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => showSplit = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: showSplit ? Colors.pink.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          if (showSplit)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Bill Split',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: showSplit ? Colors.pink : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => showSplit = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !showSplit ? Colors.pink.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          if (!showSplit)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Pending',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !showSplit ? Colors.pink : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: expensesQuery.orderBy('date', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              final filtered = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final approval = Map<String, dynamic>.from(data['approvalStatus'] ?? {});
                final userApproval = approval[currentUserId];

                // Approving logic
                final hasApproved = userApproval == 'approved' || userApproval == 'debt_created';

                return showSplit ? hasApproved : !hasApproved;
              }).toList();

              if (filtered.isEmpty) return const Center(child: Text("No items to show"));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Untitled';
                  final amount = data['amount'] ?? 0;
                  final approval = Map<String, dynamic>.from(data['approvalStatus'] ?? {});
                  final splitAmong = List<String>.from(data['splitAmong'] ?? []);
                  final approvedCount = splitAmong
                      .where((uid) => approval[uid] == 'approved' || approval[uid] == 'debt_created')
                      .length;

                  // Function to handle approval
                  Future<void> _approveExpense(String expenseId) async {
                    final expenseRef = FirebaseFirestore.instance.collection('expenses').doc(expenseId);

                    try {
                      await expenseRef.update({
                        'approvalStatus.$currentUserId': 'approved', // Mark as approved
                      });
                    } catch (e) {
                      print("Error approving expense: $e");
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpenseDetailsPage(expenseId: doc.id),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.receipt_long, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(title,
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                Text('RM${amount.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: splitAmong.isEmpty
                                  ? 0
                                  : approvedCount / splitAmong.length,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF90EE90)),
                            ),
                            const SizedBox(height: 4),
                            Text('$approvedCount / ${splitAmong.length} approved',
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 8),
                            ...splitAmong.map((uid) {
                              final name = userNames[uid] ?? uid;
                              final status = approval[uid] ?? 'pending';
                              final color = status == 'approved' || status == 'debt_created'
                                  ? const Color(0xFF90EE90)
                                  : Colors.pink;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, size: 16, color: color),
                                    const SizedBox(width: 4),
                                    Text(name),
                                    const SizedBox(width: 4),
                                    Text('– $status', style: TextStyle(color: color)),
                                  ],
                                ),
                              );
                            }),
                            if (approval[currentUserId] == 'pending')
                              ElevatedButton(
                                onPressed: () => _approveExpense(doc.id),
                                child: const Text("Approve"),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        )

        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _leaveGroup,
        backgroundColor: Colors.red,
        child: const Icon(Icons.exit_to_app),
      ),
    );
  }
}
