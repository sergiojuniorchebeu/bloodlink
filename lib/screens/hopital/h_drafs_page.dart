import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/demande/requestservices.dart';

class HDraftsPage extends StatelessWidget {
  const HDraftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // L’utilisateur hôpital doit avoir users/{uid}.hospitalRef == id de l’hôpital
    final futureHospitalId = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get()
        .then((d) => d.data()?['hospitalRef'] as String? ?? '');

    return FutureBuilder<String>(
      future: futureHospitalId,
      builder: (_, f) {
        if (f.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final hospitalId = f.data ?? '';

        if (hospitalId.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.info_outline_rounded, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Ce compte n’est lié à aucun hôpital.\nAssignez un “hospitalRef” depuis le panneau Admin.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // ⚠️ Pas de orderBy ici -> pas d’index composite requis pour la démo
        final q = FirebaseFirestore.instance
            .collection('requests')
            .where('hospitalId', isEqualTo: hospitalId)
            .where('status', isEqualTo: 'draft');

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: q.snapshots(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var docs = snap.data?.docs ?? [];

            // Tri local DESC par createdAt si présent
            docs.sort((a, b) {
              final ta = (a.data()['createdAt'] as Timestamp?);
              final tb = (b.data()['createdAt'] as Timestamp?);
              final va = ta?.millisecondsSinceEpoch ?? 0;
              final vb = tb?.millisecondsSinceEpoch ?? 0;
              return vb.compareTo(va);
            });

            if (docs.isEmpty) {
              return const Center(child: Text('Aucune demande à valider.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const Divider(),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final m = docs[i].data();
                final deadline = (m['deadline'] as Timestamp?)?.toDate();
                return ListTile(
                  title: Text('${m['patientAlias'] ?? 'Patient'} • ${m['bloodGroup']}${m['rhesus']}'),
                  subtitle: Text(
                    'Ville: ${m['city']} • Poches: ${m['unitsNeeded']}'
                        '${deadline != null ? ' • Deadline: $deadline' : ''}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('requests')
                              .doc(m['id'])
                              .update({'status': 'cancelled'});
                          if (_isMounted(context)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Demande refusée.')),
                            );
                          }
                        },
                        child: const Text('Refuser'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          await RequestService.I.approve(m['id'], approvedByHospitalUid: uid);
                          await RequestService.I.open(m['id']); // diffusion
                          if (_isMounted(context)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Demande approuvée.')),
                            );
                          }
                        },
                        child: const Text('Approuver'),
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

  bool _isMounted(BuildContext context) => context.mounted;
}
