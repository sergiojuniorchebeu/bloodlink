import 'package:cloud_firestore/cloud_firestore.dart';

class PledgeService {
  static final PledgeService I = PledgeService._();
  PledgeService._();
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('pledges');

  Future<String> create({
    required String requestId,
    required String donorUid,
    String? note,
  }) async {
    final id = _col.doc().id;
    await _col.doc(id).set({
      'id': id,
      'requestId': requestId,
      'donorUid': donorUid,
      'status': 'pending', // pending -> accepted -> fulfilled / no_show / cancelled
      'note': note ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamForRequest(String requestId) {
    return _col.where('requestId', isEqualTo: requestId).orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> accept(String pledgeId) async {
    await _col.doc(pledgeId).update({'status': 'accepted', 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> fulfill(String pledgeId) async {
    await _col.doc(pledgeId).update({'status': 'fulfilled', 'updatedAt': FieldValue.serverTimestamp()});
  }
}
