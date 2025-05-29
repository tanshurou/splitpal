import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// Shared method to generate the next expense ID
Future<String> getNextExpenseId(String groupId) async {
  final snapshot =
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('expenses')
          .get();

  final count = snapshot.docs.length + 1;
  return 'E${count.toString().padLeft(3, '0')}';
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

    final expenseId = await getNextExpenseId(_selectedGroupId!);

    final newExpenseRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('expenses')
        .doc(expenseId);

    await newExpenseRef.set({
      'title': _titleController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate),
      'createdBy': widget.userId,
      'paidBy': widget.userId,
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
                    FirebaseFirestore.instance
                        .collection('group')
                        .where('members', arrayContains: widget.userId)
                        .snapshots(),
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
                        leading: const Icon(Icons.group),
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
  bool _isUploading = false;

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

  Future<void> _uploadAndContinue() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'receipts/${widget.expenseId}.jpg',
      );

      await storageRef.putFile(_imageFile!);
      final downloadURL = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('expenses')
          .doc(widget.expenseId)
          .update({'receiptURL': downloadURL});

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
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _skipStep() {
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
              "Scan Receipt",
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

            if (_isUploading)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _skipStep,
                    icon: const Icon(Icons.double_arrow),
                    label: const Text("Skip"),
                  ),
                  ElevatedButton(
                    onPressed: _imageFile != null ? _uploadAndContinue : null,
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

class ConfirmExpensePage extends StatelessWidget {
  final String userId;
  final String groupId;
  final String expenseId;
  final String title;
  final String? receiptUrl;
  final double totalAmount;
  final List<Map<String, dynamic>> selectedMembers;
  final Map<String, dynamic> paymentStatus;
  final Map<String, dynamic> approvalStatus;
  final Map<String, dynamic> userAmounts;

  const ConfirmExpensePage({
    super.key,
    required this.userId,
    required this.groupId,
    required this.expenseId,
    required this.title,
    required this.totalAmount,
    required this.selectedMembers,
    required this.paymentStatus,
    required this.approvalStatus,
    required this.userAmounts,
    required this.receiptUrl,
  });

  Future<void> _submitFinalData(BuildContext context) async {
    final activityId = 'A${DateTime.now().millisecondsSinceEpoch}';

    await FirebaseFirestore.instance
        .collection('groups')
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
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .doc(expenseId)
        .update({
          'amount': totalAmount,
          'splitAmong': selectedMembers.map((e) => e['uid']).toList(),
          'paymentStatus': paymentStatus,
          'approvalStatus': approvalStatus,
          'userAmounts': userAmounts,
        });

    Navigator.pop(context); // Pops ConfirmExpensePage
    Navigator.pop(context); // Pops AddExpenseStep3Page
    Navigator.pop(context); // Pops AddExpenseStep2Page
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bill split request sent successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Title: $title", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Total Amount: RM${totalAmount.toStringAsFixed(2)}"),
            const SizedBox(height: 8),
            if (receiptUrl != null && receiptUrl!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Receipt:"),
                  const SizedBox(height: 8),
                  Image.network(receiptUrl!, height: 150),
                ],
              ),
            const SizedBox(height: 16),
            const Text("Members and Amounts:"),
            Expanded(
              child: ListView(
                children:
                    selectedMembers.map((member) {
                      final uid = member['uid'];
                      final name = member['name'];
                      final amt =
                          userAmounts[uid]?.toStringAsFixed(2) ?? '0.00';
                      return ListTile(
                        title: Text(name),
                        trailing: Text("RM$amt"),
                      );
                    }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: () => _submitFinalData(context),
              child: const Text("Confirm & Send"),
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

    if (!groupDoc.exists || groupDoc.data() == null) return;

    final memberIds = List<String>.from(groupDoc.data()!['members'] ?? []);
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

  Widget _buildSplitInput(String uid) {
    if (_splitMethod == SplitMethod.percentage) {
      return SizedBox(
        width: 60,
        child: TextFormField(
          initialValue: _percentages[uid]?.toString() ?? '',
          keyboardType: TextInputType.number,
          onChanged: (val) {
            setState(() {
              _percentages[uid] = double.tryParse(val) ?? 0.0;
            });
          },
          decoration: const InputDecoration(suffixText: "%"),
        ),
      );
    } else if (_splitMethod == SplitMethod.custom) {
      return SizedBox(
        width: 80,
        child: TextFormField(
          initialValue: _customAmounts[uid]?.toString() ?? '',
          keyboardType: TextInputType.number,
          onChanged: (val) {
            setState(() {
              _customAmounts[uid] = double.tryParse(val) ?? 0.0;
            });
          },
          decoration: const InputDecoration(prefixText: "RM"),
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

    for (var uid in splitAmong) {
      paymentStatus[uid] = 'unpaid';
      approvalStatus[uid] = 'pending';
    }

    if (_splitMethod == SplitMethod.equally) {
      for (var uid in splitAmong) {
        userAmounts[uid] = perPersonAmount;
      }
    } else if (_splitMethod == SplitMethod.percentage) {
      double totalPercent = _percentages.values.fold(0, (a, b) => a + b);
      if (totalPercent != 100) {
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

    final expenseDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('expenses')
            .doc(widget.expenseId)
            .get();

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

                    ToggleButtons(
                      isSelected: [
                        _splitMethod == SplitMethod.equally,
                        _splitMethod == SplitMethod.percentage,
                        _splitMethod == SplitMethod.custom,
                      ],
                      onPressed: (index) {
                        setState(() {
                          _splitMethod = SplitMethod.values[index];
                        });
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Equally"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Percentage"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Custom"),
                        ),
                      ],
                    ),
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

// ConfirmExpensePage was defined earlier and does not change.
