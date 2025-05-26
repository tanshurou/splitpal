import 'package:flutter/material.dart';
import 'create_group_class_page.dart'; // Import your create group page

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final List<Map<String, dynamic>> groups = [
    {'name': 'Family', 'members': 4},
    {'name': 'Friends', 'members': 6},
    {'name': 'Work', 'members': 10},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        centerTitle: true,
      ),
      body: groups.isEmpty
          ? const Center(
              child: Text(
                'No groups yet.\nTap + to create a group.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(group['name'][0]),
                  ),
                  title: Text(group['name']),
                  subtitle: Text('${group['members']} members'),
                  onTap: () {
                    // TODO: Navigate to Group Detail page
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newGroup = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateGroupPage()),
          );
          if (newGroup != null) {
            setState(() {
              groups.add(newGroup);
            });
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Group',
      ),
    );
  }
}
