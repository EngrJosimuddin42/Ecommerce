import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updateLastLogin(String uid) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'lastLogin': FieldValue.serverTimestamp(),
  });
}
