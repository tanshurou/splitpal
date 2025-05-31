import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String email;
  final String fullName;
  final String currency;
  final List<String> friends;
  final DateTime? createdAt;

  User({
    required this.email,
    required this.fullName,
    required this.currency,
    required this.friends,
    this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      currency: data['currency'] ?? 'RM',
      friends: List<String>.from(data['friends'] ?? []),
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'currency': currency,
      'friends': friends,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}

Future<Map<String, User>> fetchUsersByIds(List<String> userIds) async {
  final Map<String, User> userMap = {};
  final firestore = FirebaseFirestore.instance;

  for (String uid in userIds) {
    final doc = await firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      userMap[uid] = User.fromMap(doc.data()!);
    }
  }

  return userMap;
}
