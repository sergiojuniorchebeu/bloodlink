import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/pledge_service.dart';

class RequestDetailPage extends StatelessWidget {
  final String requestId;
  const RequestDetailPage({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('requests').doc(requestId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(body: Center(child: Text('Demande introuvable.')));
        }

        final m = snap.data!.data()!;
        final done = m['status'] == 'closed';
        final deadline = (m['deadline'] as Timestamp?)?.toDate();
        final hospitalId = (m['hospitalId'] as String?) ?? '';

        return Scaffold(
          appBar: AppBar(title: const Text('Détail demande')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${m['bloodGroup'] ?? '-'}${m['rhesus'] ?? ''} • ${m['patientAlias'] ?? 'Patient'}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),

              // ⬇️ Récupération du nom de l’hôpital
              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('hospitals').doc(hospitalId).get(),
                builder: (context, hSnap) {
                  String hospitalLabel = hospitalId;
                  if (hSnap.hasData && hSnap.data!.exists) {
                    hospitalLabel = (hSnap.data!.data()?['name'] as String?) ?? hospitalId;
                  }
                  return Text('Hôpital: $hospitalLabel • Ville: ${m['city'] ?? '—'}');
                },
              ),

              const SizedBox(height: 8),
              Text('Poches: ${(m['unitsMatched'] ?? 0)}/${m['unitsNeeded'] ?? 0}'),
              const SizedBox(height: 8),
              if (deadline != null) Text('Deadline: $deadline'),
              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: done
                    ? null
                    : () async {
                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  await PledgeService.I.create(requestId: requestId, donorUid: uid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Candidature envoyée')),
                    );
                  }
                },
                icon: const Icon(Icons.volunteer_activism_rounded),
                label: const Text('Je peux donner'),
              ),

              const SizedBox(height: 16),
              const Text('Candidatures', style: TextStyle(fontWeight: FontWeight.w800)),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: PledgeService.I.streamForRequest(requestId),
                builder: (_, ps) {
                  if (ps.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    );
                  }
                  final pledges = ps.data?.docs ?? [];
                  if (pledges.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Aucune candidature pour le moment.'),
                    );
                  }
                  return Column(
                    children: pledges.map((p) {
                      final pm = p.data();
                      return ListTile(
                        title: Text(pm['donorUid'] ?? '—'),
                        subtitle: Text(pm['status'] ?? 'pending'),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
