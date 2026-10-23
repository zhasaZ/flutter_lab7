import 'package:firebase_database/firebase_database.dart';

class UserRepository {
  final DatabaseReference _users = FirebaseDatabase.instance.ref('users');

  Future<String> saveUser({
    required String name,
    required String email,
    String? fcmToken,
  }) async {
    final ref = _users.push();
    await ref.set({
      'name': name,
      'email': email,
      'fcmToken': fcmToken,
      'createdAt': ServerValue.timestamp,
    });
    return ref.key!;
  }
}
