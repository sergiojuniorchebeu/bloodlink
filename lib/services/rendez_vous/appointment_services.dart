import 'package:cloud_firestore/cloud_firestore.dart';
import '../demande/requestservices.dart';

class AppointmentService {
  static final AppointmentService I = AppointmentService._();
  AppointmentService._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('appointments');

  /// Crée un RDV et passe le pledge en "accepted"
  Future<String> schedule({
    required String requestId,
    required String donorUid,
    required String hospitalId,
    required DateTime time,
    required String pledgeId, // doit être non-null ici
  }) async {
    final id = _col.doc().id;
    final batch = _db.batch();
    final aRef = _col.doc(id);

    batch.set(aRef, {
      'id': id,
      'requestId': requestId,
      'donorUid': donorUid,
      'hospitalId': hospitalId,
      'time': Timestamp.fromDate(time),
      'status': 'scheduled', // scheduled -> done / no_show
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(
      _db.collection('pledges').doc(pledgeId),
      {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
    return id;
  }

  /// Marque le don "done". `pledgeId` peut être null (si introuvable).
  Future<void> markDone({
    required String appointmentId,
    required String requestId,
    String? pledgeId, // <-- rendu optionnel
  }) async {
    final batch = _db.batch();

    batch.update(
      _col.doc(appointmentId),
      {
        'status': 'done',
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    if (pledgeId != null && pledgeId.isNotEmpty) {
      batch.update(
        _db.collection('pledges').doc(pledgeId),
        {
          'status': 'fulfilled',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();
    await RequestService.I.incrementMatched(requestId, by: 1);
  }

  Future<void> markNoShow(String appointmentId) async {
    await _col.doc(appointmentId).update({
      'status': 'no_show',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamForHospital(String hospitalId) {
    // (Pense à créer l’index composite: collection appointments, fields: hospitalId (Asc), time (Desc))
    return _col
        .where('hospitalId', isEqualTo: hospitalId)
        .orderBy('time', descending: true)
        .snapshots();
  }
}
