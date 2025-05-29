import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitpal/models/activity.dart';

/// Stream user-specific activities ordered by date.
/// Safely maps documents and skips invalid entries.
Stream<List<Activity>> userActivityStream(String userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('activityLog')
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) {
                  try {
                    return Activity.fromFirestore(doc);
                  } catch (e) {
                    print(
                      'Skipping invalid activity document: ${doc.id}, error: $e',
                    );
                    return null;
                  }
                })
                .whereType<Activity>() // filters out nulls
                .toList(),
      );
}
