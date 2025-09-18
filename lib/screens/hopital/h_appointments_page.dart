import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/rendez_vous/appointment_services.dart';

class HAppointmentsPage extends StatelessWidget {
  const HAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final futureHospitalId = FirebaseFirestore.instance
        .collection('users').doc(uid).get()
        .then((d) => (d.data()?['hospitalRef'] as String?) ?? '');

    return FutureBuilder<String>(
      future: futureHospitalId,
      builder: (context, f) {
        if (f.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final hospitalId = f.data ?? '';
        if (hospitalId.isEmpty) {
          return const Center(child: Text('Ce compte n’est lié à aucun hôpital.'));
        }

        final q = FirebaseFirestore.instance
            .collection('appointments')
            .where('hospitalId', isEqualTo: hospitalId)
            .orderBy('time', descending: true);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: q.snapshots(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) return const Center(child: Text('Aucun rendez-vous.'));

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const Divider(),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final m = docs[i].data();
                return ListTile(
                  title: Text('Donneur: ${m['donorUid']} • ${m['status']}'),
                  subtitle: Text('Demande: ${m['requestId']} • ${(m['time'] as Timestamp).toDate()}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: m['status'] == 'done'
                            ? null
                            : () async {
                          final pledges = await FirebaseFirestore.instance
                              .collection('pledges')
                              .where('requestId', isEqualTo: m['requestId'])
                              .where('donorUid', isEqualTo: m['donorUid'])
                              .limit(1)
                              .get();
                          final pledgeId = pledges.docs.isNotEmpty ? pledges.docs.first.id : null;

                          await AppointmentService.I.markDone(
                            appointmentId: m['id'],
                            requestId: m['requestId'],
                            pledgeId: pledgeId,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Don enregistré')),
                            );
                          }
                        },
                        child: const Text('Marquer “Done”'),
                      ),
                      OutlinedButton(
                        onPressed: m['status'] == 'no_show'
                            ? null
                            : () async {
                          await AppointmentService.I.markNoShow(m['id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No-show enregistré')),
                            );
                          }
                        },
                        child: const Text('No-show'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
