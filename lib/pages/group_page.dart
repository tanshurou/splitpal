import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_dashboard_page.dart';
import 'create_group_class_page.dart';

class GroupPage extends StatelessWidget {
  const GroupPage({super.key});

  Future<String?> _getCustomUserId(String email) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return FutureBuilder<String?>(
      future: _getCustomUserId(currentUser.email!),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final userId = userSnapshot.data!;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F3FD),
          appBar: AppBar(
            title: const Text('Your Groups', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFF4F3FD),
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('group')
                .where('members', arrayContains: userId)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Something went wrong"));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final groups = snapshot.data!.docs;

              if (groups.isEmpty) {
                return const Center(
                  child: Text('No groups yet. Tap + to create one.', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final doc = groups[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final groupName = data['name'] ?? 'Unnamed';
                  final groupIcon = data['icon'] ?? '👥';
                  final groupId = doc.id;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.purple.shade100,
                        child: Text(groupIcon, style: const TextStyle(fontSize: 24)),
                      ),
                      title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Tap to view dashboard'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GroupDashboardPage(groupId: groupId)),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFFBCA7FF),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupPage()));
            },
            icon: const Icon(Icons.add),
            label: const Text("Add Group"),
          ),
        );
      },
    );
  }
}
