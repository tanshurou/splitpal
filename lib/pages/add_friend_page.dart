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
  final _searchController = TextEditingController();

  bool _loadingMe = true;
  bool _isSearching = false;
  bool _isAdding = false;

  String? _myDocId; // your Firestore document ID
  _UserResult? _foundUser; // result of searching by email

  @override
  void initState() {
    super.initState();
    _initMyProfile();
  }

  Future<void> _initMyProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null || authUser.email == null) {
      setState(() => _loadingMe = false);
      return;
    }

    final col = FirebaseFirestore.instance.collection('users');
    final snap =
        await col.where('email', isEqualTo: authUser.email).limit(1).get();

    if (snap.docs.isNotEmpty) {
      _myDocId = snap.docs.first.id;
    } else {
      // fallback: create a user-doc under your auth UID
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

  Future<void> _addFriend() async {
    if (_foundUser == null || _myDocId == null) return;

    final friendUid = _foundUser!.uid;
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    if (friendUid == myUid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("You can't add yourself.")));
      return;
    }

    setState(() => _isAdding = true);

    final docRef = FirebaseFirestore.instance.collection('users').doc(_myDocId);

    try {
      // read existing friends
      final snap = await docRef.get();
      final data = snap.data() ?? {};
      final List existing = List.from(data['friends'] ?? []);

      if (existing.contains(friendUid)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Already friends.')));
        return;
      }

      // attempt update
      try {
        await docRef.update({
          'friends': FieldValue.arrayUnion([friendUid]),
        });
      } on FirebaseException catch (e) {
        if (e.code == 'not-found') {
          // doc was missing? create with merge
          await docRef.set({
            'friends': [friendUid],
          }, SetOptions(merge: true));
        } else {
          rethrow;
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend added!')));
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
            // ─── Search Input ───────────────────
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

            // ─── Search Result ──────────────────
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
                    backgroundColor: Colors.deepPurple, // was `primary`
                    foregroundColor: Colors.white, // was `onPrimary`
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

/// Simple container for a found user’s info
class _UserResult {
  final String uid, name, email;
  _UserResult({required this.uid, required this.name, required this.email});
}
