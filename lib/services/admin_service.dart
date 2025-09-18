import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final AdminService I = AdminService._();
  AdminService._();

  final _db = FirebaseFirestore.instance;

  Future<void> approveVerification(String uid) async {
    final batch = _db.batch();
    final userRef = _db.collection('users').doc(uid);
    final reqRef  = _db.collection('verification_requests').doc(uid);
    batch.update(userRef, {
      'isVerified': true,
      'verificationStatus': 'verified',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(reqRef, {
      'uid': uid,
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> rejectVerification(String uid, {String? reason}) async {
    final batch = _db.batch();
    final userRef = _db.collection('users').doc(uid);
    final reqRef  = _db.collection('verification_requests').doc(uid);
    batch.update(userRef, {
      'isVerified': false,
      'verificationStatus': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(reqRef, {
      'uid': uid,
      'status': 'rejected',
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> setUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({
      'role': role, // 'donneur' | 'receveur' | 'admin'
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setUserVerified(String uid, bool isVerified) async {
    await _db.collection('users').doc(uid).update({
      'isVerified': isVerified,
      'verificationStatus': isVerified ? 'verified' : 'unverified',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> closeRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
