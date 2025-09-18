import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projetdonsanguin/firebase_options.dart';

class AdminService {
  static final AdminService I = AdminService._();
  AdminService._();

  final _db = FirebaseFirestore.instance;
  FirebaseAuth? _secondaryAuth;

  // ================== EXISTANT ==================

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
      'role': role, // 'donneur' | 'receveur' | 'admin' | 'hopital'
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

  // ================== AJOUT HÔPITAUX ==================

  Future<FirebaseAuth> _getSecondaryAuth() async {
    if (_secondaryAuth != null) return _secondaryAuth!;
    FirebaseApp app;
    try {
      app = Firebase.app('adminSecondary');
    } catch (_) {
      app = await Firebase.initializeApp(
        name: 'adminSecondary',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _secondaryAuth = FirebaseAuth.instanceFor(app: app);
    return _secondaryAuth!;
  }

  /// CRUD: créer un hôpital
  Future<String> createHospital({
    required String name,
    required String city,
    String? phone,
    String? contactEmail,
  }) async {
    final doc = _db.collection('hospitals').doc();
    await doc.set({
      'id': doc.id,
      'name': name.trim(),
      'city': city.trim(),
      'phone': (phone ?? '').trim(),
      'contactEmail': (contactEmail ?? '').trim(),
      'accountUid': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// CRUD: mettre à jour un hôpital
  Future<void> updateHospital(
      String id, {
        required String name,
        required String city,
        String? phone,
        String? contactEmail,
      }) async {
    await _db.collection('hospitals').doc(id).update({
      'name': name.trim(),
      'city': city.trim(),
      'phone': (phone ?? '').trim(),
      'contactEmail': (contactEmail ?? '').trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// CRUD: supprimer un hôpital
  Future<void> deleteHospital(String id) async {
    await _db.collection('hospitals').doc(id).delete();
  }

  /// Assigner un utilisateur EXISTANT (via email) comme compte hôpital
  Future<void> assignHospitalAccount({
    required String hospitalId,
    required String userEmail,
  }) async {
    final users = await _db
        .collection('users')
        .where('email', isEqualTo: userEmail.trim())
        .limit(1)
        .get();
    if (users.docs.isEmpty) {
      throw 'Aucun utilisateur avec cet email.';
    }
    final uid = users.docs.first.id;
    await assignHospitalAccountByUid(hospitalId: hospitalId, uid: uid);
  }

  /// Assigner par UID (si tu l’as déjà)
  Future<void> assignHospitalAccountByUid({
    required String hospitalId,
    required String uid,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(uid), {
      'role': 'hopital',
      'hospitalRef': hospitalId,
      'isVerified': true,
      'verificationStatus': 'verified',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('hospitals').doc(hospitalId), {
      'accountUid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Retirer l’assignation (redevient donneur)
  Future<void> unassignHospitalAccount({required String hospitalId}) async {
    final h = await _db.collection('hospitals').doc(hospitalId).get();
    final uid = h.data()?['accountUid'] as String?;
    final batch = _db.batch();
    if (uid != null && uid.isNotEmpty) {
      batch.update(_db.collection('users').doc(uid), {
        'role': 'donneur',
        'hospitalRef': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.update(_db.collection('hospitals').doc(hospitalId), {
      'accountUid': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Créer un NOUVEAU compte Auth (email+password) pour l’hôpital
  /// sans déconnecter l’admin (app Firebase secondaire),
  /// puis créer/lier le profil Firestore et l’hôpital.
  Future<String> createHospitalUserAndLink({
    required String hospitalId,
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final sec = await _getSecondaryAuth();

    // 1) AUTH (app secondaire)
    final cred = await sec.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(name.trim());

    // 2) PROFIL Firestore
    final now = FieldValue.serverTimestamp();
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email.trim(),
      'name': name.trim(),
      'phone': (phone ?? '').trim(),
      'role': 'hopital',
      'isVerified': true,
      'verificationStatus': 'verified',
      'hospitalRef': hospitalId,
      'bloodGroup': null,
      'rhesus': null,
      'available': true,
      'city': null,
      'radiusKm': 20,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    // 3) Lier l’hôpital
    await _db.collection('hospitals').doc(hospitalId).update({
      'accountUid': uid,
      'updatedAt': now,
    });

    // 4) Nettoyage
    await sec.signOut();

    return uid;
  }
}
