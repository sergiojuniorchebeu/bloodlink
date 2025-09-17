import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final UserService I = UserService._();
  UserService._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  Future<void> createProfile({
    required User user,
    required String name,
    required String phone,
    required String bloodGroup,
    required String rh,
    String role = 'donneur',
  }) async {
    final now = FieldValue.serverTimestamp();
    await _col.doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'phone': phone.trim(),
      'email': user.email,
      'bloodGroup': bloodGroup, // "O","A","B","AB"
      'rhesus': rh,             // "+","-"
      'role': role,             // 'donneur' | 'receveur' | 'admin'
      'isVerified': false,      // validé par admin
      'verificationStatus': 'unverified',
      'city': null,
      'radiusKm': 20,
      'lastDonationAt': null,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final snap = await _col.doc(uid).get();
    return snap.data();
  }

  Future<void> touchUpdatedAt(String uid) async {
    await _col.doc(uid).update({'updatedAt': FieldValue.serverTimestamp()});
  }
}
