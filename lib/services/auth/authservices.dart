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
      'isVerified': false,
      'verificationStatus': 'unverified', // 'pending' | 'verified' | 'rejected'
      'available': true,
      'city': null,
      'radiusKm': 20,
      'lastDonationAt': null,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> streamProfile(String uid) =>
      _col.doc(uid).snapshots().map((d) => d.data());

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final snap = await _col.doc(uid).get();
    return snap.data();
  }

  Future<void> updateProfile(String uid, {
    String? name,
    String? phone,
    String? bloodGroup,
    String? rh,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (rh != null) 'rhesus': rh,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _col.doc(uid).update(data);
  }

  Future<void> setAvailability(String uid, bool available) async {
    await _col.doc(uid).update({
      'available': available,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setCityRadius(String uid, {required String city, required int radiusKm}) async {
    await _col.doc(uid).update({
      'city': city,
      'radiusKm': radiusKm,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markVerificationPending(String uid, {required String idUrl}) async {
    await _db.collection('verification_requests').doc(uid).set({
      'uid': uid,
      'status': 'pending',
      'idImageUrl': idUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _col.doc(uid).update({
      'verificationStatus': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> touchUpdatedAt(String uid) async {
    await _col.doc(uid).update({'updatedAt': FieldValue.serverTimestamp()});
  }
}
