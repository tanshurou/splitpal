import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> getUserIdByEmail(String email) async {
  final snapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

  if (snapshot.docs.isNotEmpty) {
    return snapshot.docs.first.id; // returns U001, U002, etc.
  }

  return null; // Not found
}
