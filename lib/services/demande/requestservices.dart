import 'package:cloud_firestore/cloud_firestore.dart';

class RequestService {
  static final RequestService I = RequestService._();
  RequestService._();
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('requests');

  Future<String> createDraft({
    required String createdBy,
    required String patientGroup,
    required String patientRh,
    required String hospitalId,
    required String city,
    required int unitsNeeded,
    required DateTime deadline,
    String? patientAlias,
  }) async {
    final doc = _col.doc();
    await doc.set({
      'id': doc.id,
      'createdBy': createdBy,
      'patientAlias': patientAlias ?? '—',
      'bloodGroup': patientGroup, // receveur
      'rhesus': patientRh,
      'hospitalId': hospitalId,
      'city': city,
      'unitsNeeded': unitsNeeded,
      'unitsMatched': 0,
      'status': 'draft', // draft -> approved -> open/partially_fulfilled -> closed
      'createdAt': FieldValue.serverTimestamp(),
      'deadline': Timestamp.fromDate(deadline),
    });
    return doc.id;
  }

  Future<void> approve(String requestId, {required String approvedByHospitalUid}) async {
    await _col.doc(requestId).update({
      'status': 'approved',
      'approvedBy': approvedByHospitalUid,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> open(String requestId) async {
    await _col.doc(requestId).update({'status': 'open'});
  }

  Future<void> close(String requestId) async {
    await _col.doc(requestId).update({'status': 'closed', 'closedAt': FieldValue.serverTimestamp()});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamForCityApproved(String city) {
    return _col
        .where('city', isEqualTo: city)
        .where('status', whereIn: ['approved', 'open'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> incrementMatched(String requestId, {int by = 1}) async {
    await _col.doc(requestId).update({'unitsMatched': FieldValue.increment(by)});
    final doc = await _col.doc(requestId).get();
    final m = doc.data()!;
    if ((m['unitsMatched'] ?? 0) >= (m['unitsNeeded'] ?? 0)) {
      await close(requestId);
    } else {
      await open(requestId);
    }
  }
}
