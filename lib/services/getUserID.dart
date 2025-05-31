import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> getUserIdByEmail(String email) async {
  try {
    print("🔍 getUserIdByEmail called with: '$email'");
    final normalizedEmail = email.trim().toLowerCase();
    print("🔍 Normalized email: '$normalizedEmail'");

    print("🔍 Starting Firestore query...");
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();

    print("🔍 Firestore query completed");
    print("🔍 Number of documents found: ${snapshot.docs.length}");

    if (snapshot.docs.isNotEmpty) {
      final docId = snapshot.docs.first.id;
      final docData = snapshot.docs.first.data();
      print("🔍 Found document ID: $docId");
      print("🔍 Document data: $docData");
      return docId;
    } else {
      print("🔍 No documents found for email: $normalizedEmail");

      // Let's also try to fetch all users to see what emails exist
      print("🔍 Fetching all users to debug...");
      final allUsers =
          await FirebaseFirestore.instance.collection('users').limit(10).get();

      print("🔍 All users in collection:");
      for (var doc in allUsers.docs) {
        final data = doc.data();
        print("  - ID: ${doc.id}, Email: ${data['email']}, Data: $data");
      }
    }

    return null;
  } catch (e, stackTrace) {
    print("❌ Error in getUserIdByEmail: $e");
    print("❌ Stack trace: $stackTrace");
    return null;
  }
}
