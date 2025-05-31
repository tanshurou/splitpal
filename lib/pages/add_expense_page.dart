import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:splitpal/models/user.dart';

// Shared method to generate the next expense ID
Future<String> getNextExpenseId() async {
  final snapshot =
      await FirebaseFirestore.instance
          .collection('expenses')
          .orderBy(FieldPath.documentId)
          .get();

  int maxId = 0;

  for (var doc in snapshot.docs) {
    final id = doc.id;
    if (id.startsWith('E')) {
      final numPart = int.tryParse(id.substring(1));
      if (numPart != null && numPart > maxId) {
        maxId = numPart;
      }
    }
  }

  return 'E${(maxId + 1).toString().padLeft(3, '0')}';
}

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
  String? _selectedPayerId;
  List<Map<String, dynamic>> _groupMembers = [];

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
    if (_titleController.text.isEmpty ||
        _selectedGroupId == null ||
        _selectedPayerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter all details")));
      return;
    }

    final expenseId = await getNextExpenseId();

    final newExpenseRef = FirebaseFirestore.instance
        .collection('expenses')
        .doc(expenseId);

    await newExpenseRef.set({
      'title': _titleController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate),
      'createdBy': widget.userId,
      'paidBy': _selectedPayerId,
      'groupId': _selectedGroupId,
      'receiptURL': '',
      'amount': 0,
      'splitAmong': [],
      'approvalStatus': {},
      'paymentStatus': {},
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddExpenseStep2Page(
              groupId: _selectedGroupId!,
              expenseId: expenseId,
              userId: widget.userId,
            ),
      ),
    );
  }

  Future<void> _loadGroupMembers(String groupId) async {
    final groupDoc =
        await FirebaseFirestore.instance.collection('group').doc(groupId).get();
    final memberIds = List<String>.from(groupDoc.data()?['members'] ?? []);

    final members = await Future.wait(
      memberIds.map((uid) async {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        return {'uid': uid, 'name': userDoc['fullName'] ?? 'User'};
      }),
    );

    setState(() {
      _groupMembers = members;
      _selectedPayerId = null;
    });
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Title",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('group')
                        .where('members', arrayContains: widget.userId)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();

                  final groups = snapshot.data!.docs;

                  return Column(
                    children:
                        groups.map((group) {
                          final groupId = group.id;
                          final groupName = group['name'];

                          return ListTile(
                            title: Text(groupName),
                            leading: const Icon(Icons.group),
                            selected: _selectedGroupId == groupId,
                            onTap: () {
                              setState(() {
                                _selectedGroupId = groupId;
                                _groupMembers.clear();
                              });
                              _loadGroupMembers(groupId);
                            },
                          );
                        }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              if (_groupMembers.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Who Paid?",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedPayerId,
                      hint: const Text("Select a payer"),
                      items:
                          _groupMembers.map((member) {
                            return DropdownMenuItem<String>(
                              value: member['uid'],
                              child: Text(member['name']),
                            );
                          }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPayerId = val;
                        });
                      },
                    ),
                  ],
                ),

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitExpense,
                  child: const Text("Next"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddExpenseStep2Page extends StatefulWidget {
  final String groupId;
  final String expenseId;
  final String userId;

  const AddExpenseStep2Page({
    super.key,
    required this.groupId,
    required this.expenseId,
    required this.userId,
  });

  @override
  State<AddExpenseStep2Page> createState() => _AddExpenseStep2PageState();
}

class _AddExpenseStep2PageState extends State<AddExpenseStep2Page> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _continueToNextStep() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddExpenseStep3Page(
              groupId: widget.groupId,
              expenseId: widget.expenseId,
              userId: widget.userId,
            ),
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
          children: [
            const Text(
              "Scan Receipt (Optional)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey.shade100,
                ),
                child:
                    _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : const Icon(
                          Icons.camera_alt,
                          size: 80,
                          color: Colors.grey,
                        ),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _continueToNextStep,
                  icon: const Icon(Icons.double_arrow),
                  label: const Text("Skip"),
                ),
                ElevatedButton(
                  onPressed: _continueToNextStep,
                  child: const Text("Continue"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum SplitMethod { equally, percentage, custom }

class AddExpenseStep3Page extends StatefulWidget {
  final String groupId;
  final String expenseId;
  final String userId;

  const AddExpenseStep3Page({
    super.key,
    required this.groupId,
    required this.expenseId,
    required this.userId,
  });

  @override
  State<AddExpenseStep3Page> createState() => _AddExpenseStep3PageState();
}

class _AddExpenseStep3PageState extends State<AddExpenseStep3Page> {
  SplitMethod _splitMethod = SplitMethod.equally;
  double _totalAmount = 0.0;
  final TextEditingController _amountController = TextEditingController();

  List<Map<String, dynamic>> _members = [];
  Set<String> _selectedUserIds = {};

  final Map<String, double> _customAmounts = {};
  final Map<String, double> _percentages = {};

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
  }

  Future<void> _loadGroupInfo() async {
    final groupDoc =
        await FirebaseFirestore.instance
            .collection('group')
            .doc(widget.groupId)
            .get();
    final memberIds = List<String>.from(groupDoc.data()?['members'] ?? []);
    final usersCollection = FirebaseFirestore.instance.collection('users');

    final members = await Future.wait(
      memberIds.map((uid) async {
        final userDoc = await usersCollection.doc(uid).get();
        return {'uid': uid, 'name': userDoc['fullName'] ?? 'User'};
      }),
    );

    setState(() {
      _members = members;
      _selectedUserIds = memberIds.toSet();
    });
  }

  Widget _buildSplitMethodToggle() {
    final labels = ['Equally', 'Percentage', 'Custom'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.purple.shade100,
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final method = SplitMethod.values[index];
          final isSelected = _splitMethod == method;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => setState(() => _splitMethod = method),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient:
                      isSelected
                          ? const LinearGradient(
                            colors: [Color(0xFFB388FF), Color(0xFF7C4DFF)],
                          )
                          : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.purple.shade700,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSplitInput(String uid) {
    if (_splitMethod == SplitMethod.percentage) {
      return SizedBox(
        width: 80,
        child: TextFormField(
          initialValue: _percentages[uid]?.toString() ?? '',
          keyboardType: TextInputType.number,
          onChanged:
              (val) => setState(() {
                _percentages[uid] = double.tryParse(val) ?? 0.0;
              }),
          decoration: const InputDecoration(suffixText: "%"),
        ),
      );
    } else if (_splitMethod == SplitMethod.custom) {
      return SizedBox(
        width: 80,
        child: TextField(
          readOnly: true,
          controller: TextEditingController(
            text: _customAmounts[uid]?.toStringAsFixed(2) ?? '',
          ),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => CalculatorScreen(
                      initialValue: _customAmounts[uid] ?? 0.0,
                    ),
              ),
            );
            if (result != null) {
              setState(() {
                _customAmounts[uid] = result;
              });
            }
          },
          decoration: const InputDecoration(hintText: 'Amount'),
        ),
      );
    }
    return const SizedBox();
  }

  Future<void> _splitAndSave() async {
    if (_amountController.text.isEmpty || _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount and select members')),
      );
      return;
    }

    _totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    final splitAmong = _selectedUserIds.toList();
    final perPersonAmount = _totalAmount / splitAmong.length;

    Map<String, dynamic> paymentStatus = {};
    Map<String, dynamic> approvalStatus = {};
    Map<String, dynamic> userAmounts = {};
    List<Map<String, dynamic>> selectedMembers = [];

    // Fetch the paidBy ID from the expense document
    final expenseDoc =
        await FirebaseFirestore.instance
            .collection('expenses')
            .doc(widget.expenseId)
            .get();

    final paidById = expenseDoc['paidBy'];

    for (var uid in splitAmong) {
      paymentStatus[uid] = (uid == paidById) ? 'paid' : 'unpaid';
      approvalStatus[uid] = 'pending';
    }

    if (_splitMethod == SplitMethod.equally) {
      for (var uid in splitAmong) {
        userAmounts[uid] = perPersonAmount;
      }
    } else if (_splitMethod == SplitMethod.percentage) {
      double totalPercent = splitAmong
          .map((uid) => _percentages[uid] ?? 0.0)
          .fold(0.0, (a, b) => a + b);
      if ((totalPercent - 100.0).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Percentages must total 100%')),
        );
        return;
      }
      for (var uid in splitAmong) {
        userAmounts[uid] = (_percentages[uid] ?? 0) * _totalAmount / 100;
      }
    } else {
      double totalCustom = _customAmounts.values.fold(0, (a, b) => a + b);
      if ((totalCustom - _totalAmount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Custom amounts must total RM$_totalAmount')),
        );
        return;
      }
      userAmounts.addAll(_customAmounts);
    }

    for (var member in _members) {
      if (_selectedUserIds.contains(member['uid'])) {
        selectedMembers.add(member);
      }
    }

    final title = expenseDoc['title'] ?? '';
    final receiptUrl = expenseDoc['receiptURL'] ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ConfirmExpensePage(
              userId: widget.userId,
              groupId: widget.groupId,
              expenseId: widget.expenseId,
              title: title,
              receiptUrl: receiptUrl,
              totalAmount: _totalAmount,
              selectedMembers: selectedMembers,
              paymentStatus: paymentStatus,
              approvalStatus: approvalStatus,
              userAmounts: userAmounts,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Split Bill')),
      body:
          _members.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Amount (RM)"),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: "e.g. 100.0"),
                    ),
                    const SizedBox(height: 16),
                    _buildSplitMethodToggle(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final uid = member['uid'];
                          final name = member['name'];

                          return CheckboxListTile(
                            value: _selectedUserIds.contains(uid),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedUserIds.add(uid);
                                } else {
                                  _selectedUserIds.remove(uid);
                                  _percentages.remove(uid);
                                  _customAmounts.remove(uid);
                                }
                              });
                            },
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [Text(name), _buildSplitInput(uid)],
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _splitAndSave,
                      child: const Text("Split and Review"),
                    ),
                  ],
                ),
              ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  final double initialValue;
  const CalculatorScreen({super.key, required this.initialValue});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String expression = '';

  void _onPressed(String value) {
    setState(() {
      if (value == 'C') {
        expression = '';
      } else if (value == '+/-') {
        if (expression.startsWith('-')) {
          expression = expression.substring(1);
        } else {
          expression = '-$expression';
        }
      } else if (value == '=') {
        try {
          final result = _evaluate(expression);
          Navigator.pop(context, result);
        } catch (_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Invalid expression")));
        }
      } else {
        expression += value;
      }
    });
  }

  double _evaluate(String expr) {
    try {
      String formatted = expr.replaceAll('×', '*').replaceAll('÷', '/');
      Parser p = Parser();
      Expression exp = p.parse(formatted);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      return double.parse(eval.toStringAsFixed(2));
    } catch (_) {
      throw Exception('Invalid expression');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calculator")),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(24),
              child: Text(
                expression.isEmpty
                    ? widget.initialValue.toStringAsFixed(2)
                    : expression,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            children:
                [
                  'C',
                  '+/-',
                  '%',
                  '÷',
                  '7',
                  '8',
                  '9',
                  '×',
                  '4',
                  '5',
                  '6',
                  '-',
                  '1',
                  '2',
                  '3',
                  '+',
                  '0',
                  '00',
                  '.',
                  '=',
                ].map((btn) {
                  return InkWell(
                    onTap: () => _onPressed(btn),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(btn, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class ConfirmExpensePage extends StatelessWidget {
  final String userId, groupId, expenseId, title, receiptUrl;
  final double totalAmount;
  final List<Map<String, dynamic>> selectedMembers;
  final Map<String, dynamic> paymentStatus, approvalStatus, userAmounts;

  const ConfirmExpensePage({
    super.key,
    required this.userId,
    required this.groupId,
    required this.expenseId,
    required this.title,
    required this.receiptUrl,
    required this.totalAmount,
    required this.selectedMembers,
    required this.paymentStatus,
    required this.approvalStatus,
    required this.userAmounts,
  });

  Future<void> _submitFinalData(BuildContext context) async {
    final activityId = 'A${DateTime.now().millisecondsSinceEpoch}';

    await FirebaseFirestore.instance
        .collection('group')
        .doc(groupId)
        .collection('activityLog')
        .doc(activityId)
        .set({
          'type': 'bill_split_request',
          'expenseId': expenseId,
          'title': title,
          'createdBy': userId,
          'timestamp': Timestamp.now(),
          'amount': totalAmount,
          'splitAmong': selectedMembers.map((e) => e['uid']).toList(),
          'approvalStatus': approvalStatus,
        });

    await FirebaseFirestore.instance
        .collection('expenses')
        .doc(expenseId)
        .update({
          'amount': totalAmount,
          'splitAmong': selectedMembers.map((e) => e['uid']).toList(),
          'paymentStatus': paymentStatus,
          'approvalStatus': approvalStatus,
          'userAmounts': userAmounts,
        });

    Navigator.popUntil(context, (route) => route.isFirst);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bill split request sent successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userIds = selectedMembers.map((e) => e['uid'] as String).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Expense')),
      body: FutureBuilder<Map<String, User>>(
        future: fetchUsersByIds(userIds),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Title: $title", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Total Amount: RM${totalAmount.toStringAsFixed(2)}"),
                const SizedBox(height: 8),
                Text("Paid by: ${users[userId]?.fullName ?? userId}"),
                const SizedBox(height: 8),
                if (receiptUrl.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Receipt:"),
                      const SizedBox(height: 8),
                      Image.network(receiptUrl, height: 150),
                    ],
                  ),
                const SizedBox(height: 16),
                const Text("Members and Amounts:"),
                Expanded(
                  child: ListView.builder(
                    itemCount: userIds.length,
                    itemBuilder: (context, index) {
                      final uid = userIds[index];
                      final user = users[uid];
                      final amount =
                          userAmounts[uid]?.toStringAsFixed(2) ?? '0.00';
                      final approval = approvalStatus[uid] ?? 'pending';
                      final payment = paymentStatus[uid] ?? 'unpaid';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(user?.fullName ?? uid),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Approval Status: $approval"),
                              Text("Payment Status: $payment"),
                              Text("Amount: RM$amount"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _submitFinalData(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Send Request",
                    style: TextStyle(fontSize: 16),
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
