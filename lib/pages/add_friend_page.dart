// lib/pages/add_friend_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({Key? key}) : super(key: key);

  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _loadingMe = true;
  bool _isSearching = false;
  bool _isAdding = false;

  String? _myDocId; // ← your Firestore doc ID
  _UserResult? _foundUser; // holds the search result

  @override
  void initState() {
    super.initState();
    _initMyProfile();
  }

  /// 1) Figure out which Firestore doc is *you* (by email),
  ///    or create it under your Auth UID if it doesn’t exist.
  Future<void> _initMyProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null || authUser.email == null) {
      setState(() => _loadingMe = false);
      return;
    }

    final col = FirebaseFirestore.instance.collection('users');
    final snap =
        await col.where('email', isEqualTo: authUser.email!).limit(1).get();

    if (snap.docs.isNotEmpty) {
      _myDocId = snap.docs.first.id;
    } else {
      // fallback: create a new user‐doc under your authUID
      _myDocId = authUser.uid;
      await col.doc(_myDocId).set({
        'email': authUser.email,
        'fullName': authUser.displayName ?? '',
        'friends': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    setState(() => _loadingMe = false);
  }

  /// 2) Search for another user by email and store their doc-id
  Future<void> _searchUser() async {
    final email = _searchController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
    });

    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (snap.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No user found.')));
      } else {
        final doc = snap.docs.first;
        final data = doc.data();
        setState(() {
          _foundUser = _UserResult(
            uid: doc.id,
            name: (data['fullName'] ?? '') as String,
            email: data['email'] as String,
          );
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Search failed.')));
    } finally {
      setState(() => _isSearching = false);
    }
  }

  /// 3) Add friend *both* ways, using Firestore doc IDs
  Future<void> _addFriend() async {
    if (_foundUser == null || _myDocId == null) return;

    final theirDocId = _foundUser!.uid;
    final myDocId = _myDocId!;

    if (theirDocId == myDocId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("You can't add yourself.")));
      return;
    }

    setState(() => _isAdding = true);

    final meRef = FirebaseFirestore.instance.collection('users').doc(myDocId);
    final themRef = FirebaseFirestore.instance
        .collection('users')
        .doc(theirDocId);

    try {
      // — add them to you —
      try {
        await meRef.update({
          'friends': FieldValue.arrayUnion([theirDocId]),
        });
      } on FirebaseException catch (e) {
        if (e.code == 'not-found') {
          await meRef.set({
            'friends': [theirDocId],
          }, SetOptions(merge: true));
        } else {
          rethrow;
        }
      }

      // — add you to them —
      try {
        await themRef.update({
          'friends': FieldValue.arrayUnion([myDocId]),
        });
      } on FirebaseException catch (e) {
        if (e.code == 'not-found') {
          await themRef.set({
            'friends': [myDocId],
          }, SetOptions(merge: true));
        } else {
          rethrow;
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend added mutually!')));
    } catch (e) {
      debugPrint('Add friend error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add friend.')));
    } finally {
      setState(() => _isAdding = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingMe) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Friend')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── search bar ──────────────────────────
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (_) => _searchUser(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isSearching ? null : _searchUser,
              child:
                  _isSearching
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Search'),
            ),

            const SizedBox(height: 24),

            // ── result tile ─────────────────────────
            if (_foundUser != null)
              ListTile(
                leading: CircleAvatar(
                  child: Text(_foundUser!.email[0].toUpperCase()),
                ),
                title: Text(
                  _foundUser!.name.isNotEmpty
                      ? _foundUser!.name
                      : _foundUser!.email,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(_foundUser!.email),
                trailing: ElevatedButton(
                  onPressed: _isAdding ? null : _addFriend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child:
                      _isAdding
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text('Add', style: GoogleFonts.poppins()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Simple holder for a found user's info
class _UserResult {
  final String uid, name, email;
  _UserResult({required this.uid, required this.name, required this.email});
}
