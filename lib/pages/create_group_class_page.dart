import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameController = TextEditingController();
  final List<String> _selectedUserIds = [];
  bool _isCreating = false;
  String _selectedIcon = '👥';

  final List<String> _availableIcons = ['🛍️', '🎂', '🍽️', '✈️', '👥'];

  Future<void> _createGroup() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final groupName = _nameController.text.trim();

    if (currentUser == null || groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name.')),
      );
      return;
    }

    setState(() => _isCreating = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: currentUser.email)
        .get();

    if (snapshot.docs.isEmpty) {
      setState(() => _isCreating = false);
      return;
    }

    final currentUserId = snapshot.docs.first.id;
    final memberList = {currentUserId, ..._selectedUserIds}.toList();

    final groupId = await _getNextGroupId();
    await FirebaseFirestore.instance.collection('group').doc(groupId).set({
      'name': groupName,
      'createdBy': currentUserId,
      'date': Timestamp.now(),
      'icon': _selectedIcon,
      'members': memberList,
    });

    setState(() => _isCreating = false);
    Navigator.pop(context);
  }

  Future<String> _getNextGroupId() async {
    final snapshot = await FirebaseFirestore.instance.collection('group').get();
    final count = snapshot.docs.length;
    return 'G${(count + 1).toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: 20),
            const Text('Select Icon:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _availableIcons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return ChoiceChip(
                  label: Text(icon, style: const TextStyle(fontSize: 24)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedIcon = icon),
                  selectedColor: Colors.purple.shade100,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Add Members:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final currentUser = FirebaseAuth.instance.currentUser;
                  final users = snapshot.data!.docs.where((doc) =>
                      (doc.data() as Map<String, dynamic>)['email'] != currentUser?.email);

                  return ListView(
                    children: users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final uid = doc.id;
                      final name = data['fullName'] ?? 'Unknown';
                      final isSelected = _selectedUserIds.contains(uid);

                      return CheckboxListTile(
                        title: Text(name),
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedUserIds.add(uid);
                            } else {
                              _selectedUserIds.remove(uid);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createGroup,
                child: _isCreating
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
