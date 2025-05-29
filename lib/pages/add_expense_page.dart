import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddExpenseStep1Page extends StatefulWidget {
  final String userId;

  const AddExpenseStep1Page({super.key, required this.userId});

  @override
  State<AddExpenseStep1Page> createState() => _AddExpenseStep1PageState();
}

class _AddExpenseStep1PageState extends State<AddExpenseStep1Page> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedGroupId;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitExpense() async {
    if (_titleController.text.isEmpty || _selectedGroupId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter all details")));
      return;
    }

    final newExpenseRef =
        FirebaseFirestore.instance.collection('expenses').doc();

    await newExpenseRef.set({
      'title': _titleController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate),
      'createdBy': widget.userId,
      'paidBy': widget.userId,
      'groupId': _selectedGroupId,
      'receiptURL': '',
      'amount': 0, // to be added in later step
      'splitAmong': [],
      'approvalStatus': {},
      'paymentStatus': {},
    });

    // Navigate to next step (replace with your actual page)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseStep2Page(expenseId: newExpenseRef.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add an Expense"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Title", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "Enter expense title",
              ),
            ),
            const SizedBox(height: 20),

            const Text("Date", style: TextStyle(fontWeight: FontWeight.bold)),
            InkWell(
              onTap: _pickDate,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(DateFormat.yMMMd().format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Choose a Group",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('group').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final groups = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final groupName = group['name'];
                      final groupId = group.id;

                      return ListTile(
                        title: Text(groupName),
                        leading: Icon(Icons.group),
                        selected: _selectedGroupId == groupId,
                        onTap: () {
                          setState(() {
                            _selectedGroupId = groupId;
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: _submitExpense,
                child: const Text("Next"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy placeholder for next page
class AddExpenseStep2Page extends StatelessWidget {
  final String expenseId;

  const AddExpenseStep2Page({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text("Step 2 for $expenseId")));
  }
}
