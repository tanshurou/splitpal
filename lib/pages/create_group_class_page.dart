import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameController = TextEditingController();
  final List<String> _selectedUserIds = []; // store member UIDs
  bool _isCreating = false;

  Future<void> _createGroup() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _nameController.text.isEmpty) return;

    setState(() => _isCreating = true);

    final groupId = await _getNextGroupId();
    final groupDoc = FirebaseFirestore.instance.collection('group').doc(groupId);

    await groupDoc.set({
      'name': _nameController.text.trim(),
      'createdBy': currentUser.uid,
      'date': Timestamp.now(),
      'members': [currentUser.uid, ..._selectedUserIds],
    });

    setState(() => _isCreating = false);
    Navigator.pop(context); // Go back to GroupPage
  }

  Future<String> _getNextGroupId() async {
    final snapshot = await FirebaseFirestore.instance.collection('group').get();
    final count = snapshot.docs.length;
    final nextId = count + 1;
    return 'G${nextId.toString().padLeft(3, '0')}'; // G001, G002, etc.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isCreating ? null : _createGroup,
              child: _isCreating ? const CircularProgressIndicator() : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
