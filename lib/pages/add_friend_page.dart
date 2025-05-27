// lib/pages/add_friend_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple User model
class User {
  final String id;
  final String name;
  final String email;
  User({required this.id, required this.name, required this.email});
}

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final _searchCtrl = TextEditingController();
  List<User> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final term = _searchCtrl.text.trim();
    if (term.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);

    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: term)
              .limit(1)
              .get();

      final list =
          snap.docs.map((doc) {
            final data = doc.data();
            final email = data['email'] as String;
            return User(id: doc.id, name: email, email: email);
          }).toList();

      setState(() => _results = list);
    } catch (e) {
      debugPrint('Firestore search error: $e');
      setState(() => _results = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _sendRequest(User u) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Friend request sent to ${u.email}!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gradientStart = Color(0xFF7B5FFF);
    const gradientEnd = Color(0xFFFB56A5);

    return Scaffold(
      body: Column(
        children: [
          // ─── HEADER ──────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 24,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Row(
              children: [
                BackButton(color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Add a Friend',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ─── SEARCH BAR ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Search by email',
                      hintStyle: GoogleFonts.poppins(color: Colors.black38),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black54,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _doSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _doSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gradientEnd,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            'Go',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                ),
              ],
            ),
          ),

          // ─── RESULTS ─────────────────────
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchCtrl.text.trim().isEmpty
                    ? Center(
                      child: Text(
                        'Enter an email above',
                        style: GoogleFonts.poppins(color: Colors.black38),
                      ),
                    )
                    : _results.isEmpty
                    ? Center(
                      child: Text(
                        'No users found',
                        style: GoogleFonts.poppins(color: Colors.black38),
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final u = _results[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(u.email[0].toUpperCase()),
                            ),
                            title: Text(
                              u.email,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _sendRequest(u),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: gradientStart,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                'Add',
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
