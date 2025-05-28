import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitpal/models/activity.dart';

Stream<List<Activity>> userActivityStream(String userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('activityLog')
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList(),
      );
}
