import 'package:flutter/material.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();

  final List<String> _allFriends = [
    'Alice',
    'Bob',
    'Charlie',
    'Diana',
    'Ethan',
    'Fiona',
  ];

  final Set<String> _selectedFriends = {};

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _groupNameController.text.trim().isNotEmpty && _selectedFriends.isNotEmpty;

  void _toggleFriendSelection(String friend) {
    setState(() {
      if (_selectedFriends.contains(friend)) {
        _selectedFriends.remove(friend);
      } else {
        _selectedFriends.add(friend);
      }
    });
  }

  void _onCreate() {
    final groupName = _groupNameController.text.trim();
    final members = _selectedFriends.toList();

    Navigator.of(context).pop({'name': groupName, 'members': members});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group Name', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                hintText: 'Enter group name',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            const Text('Add Members', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _allFriends.length,
                itemBuilder: (context, index) {
                  final friend = _allFriends[index];
                  final selected = _selectedFriends.contains(friend);
                  return ListTile(
                    title: Text(friend),
                    trailing: selected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    onTap: () => _toggleFriendSelection(friend),
                  );
                },
              ),
            ),
            if (_selectedFriends.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _selectedFriends
                    .map((name) => Chip(
                          label: Text(name),
                          onDeleted: () => _toggleFriendSelection(name),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _canCreate ? _onCreate : null,
                  child: const Text('Create'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
