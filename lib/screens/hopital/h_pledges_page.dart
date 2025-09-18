import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/rendez_vous/appointment_services.dart';

class HPledgesPage extends StatelessWidget {
  const HPledgesPage({super.key});

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

        final pledges = FirebaseFirestore.instance
            .collection('pledges')
            .orderBy('createdAt', descending: true) // tri client possible sinon
            .snapshots();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: pledges,
          builder: (_, pSnap) {
            if (pSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final ps = pSnap.data?.docs ?? [];
            if (ps.isEmpty) return const Center(child: Text('Aucune candidature.'));

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: ps.length,
              itemBuilder: (_, i) {
                final pledge = ps[i].data();

                return FutureBuilder<_JoinRow>(
                  future: _loadJoin(pledge),
                  builder: (context, joinSnap) {
                    if (joinSnap.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        title: Text('Chargement…'),
                        subtitle: LinearProgressIndicator(),
                      );
                    }
                    if (!joinSnap.hasData) {
                      return const SizedBox.shrink();
                    }
                    final row = joinSnap.data!;
                    final req = row.request;

                    // ⛔️ Filtre ici: ne montre que les pledges de MON hôpital
                    if ((req['hospitalId'] ?? '') != hospitalId) {
                      return const SizedBox.shrink();
                    }

                    final demandeur = row.requester;
                    final donneur = row.donor;
                    final deadline = (req['deadline'] as Timestamp?)?.toDate();
                    final reqBlood = '${req['bloodGroup'] ?? '-'}${req['rhesus'] ?? ''}';

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          'Donneur: ${donneur['name'] ?? donneur['email'] ?? donneur['uid']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Demande: ${req['patientAlias'] ?? 'Patient'} • $reqBlood'),
                              const SizedBox(height: 4),
                              Text('Ville: ${req['city'] ?? '—'} • Poches: ${req['unitsNeeded'] ?? '?'}'
                                  '${deadline != null ? ' • Deadline: $deadline' : ''}'),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: -6,
                                children: [
                                  _chip('Statut: ${pledge['status'] ?? 'pending'}'),
                                  _chip('Demandeur: ${demandeur['name'] ?? demandeur['email'] ?? demandeur['uid']}'),
                                  if ((donneur['bloodGroup'] ?? '') != '' || (donneur['rhesus'] ?? '') != '')
                                    _chip('Donneur: ${(donneur['bloodGroup'] ?? '-')}${(donneur['rhesus'] ?? '')}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: FilledButton(
                          onPressed: (pledge['status'] == 'accepted')
                              ? null
                              : () async {
                            final dt = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 7)),
                              initialDate: DateTime.now(),
                            );
                            if (dt == null) return;
                            final tm = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (tm == null) return;
                            final time = DateTime(dt.year, dt.month, dt.day, tm.hour, tm.minute);

                            await AppointmentService.I.schedule(
                              requestId: req['id'],
                              donorUid: donneur['uid'],
                              hospitalId: req['hospitalId'] ?? '',
                              time: time,
                              pledgeId: pledge['id'],
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('RDV programmé')),
                              );
                            }
                          },
                          child: const Text('Programmer RDV'),
                        ),
                        onTap: () => _showDetailsBottomSheet(context, row),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<_JoinRow> _loadJoin(Map<String, dynamic> pledge) async {
    final reqId = pledge['requestId'] as String;
    final donorUid = pledge['donorUid'] as String;

    final reqDoc = await FirebaseFirestore.instance.collection('requests').doc(reqId).get();
    final request = reqDoc.data() ?? {};
    request['id'] = reqDoc.id;

    final requesterUid = (request['createdBy'] ?? '') as String? ?? '';
    final requesterDoc = requesterUid.isNotEmpty
        ? await FirebaseFirestore.instance.collection('users').doc(requesterUid).get()
        : null;
    final donorDoc = await FirebaseFirestore.instance.collection('users').doc(donorUid).get();

    final requester = requesterDoc?.data() ?? {'uid': requesterUid};
    requester['uid'] = requesterUid;

    final donor = donorDoc.data() ?? {'uid': donorUid};
    donor['uid'] = donorUid;

    return _JoinRow(pledge: pledge, request: request, requester: requester, donor: donor);
  }

  void _showDetailsBottomSheet(BuildContext context, _JoinRow row) {
    final req = row.request;
    final demandeur = row.requester;
    final donneur = row.donor;
    final deadline = (req['deadline'] as Timestamp?)?.toDate();
    final reqBlood = '${req['bloodGroup'] ?? '-'}${req['rhesus'] ?? ''}';

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Détails candidature', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            _kv('Demande', '${req['patientAlias'] ?? 'Patient'} • $reqBlood'),
            _kv('Ville', req['city'] ?? '—'),
            _kv('Poches', '${req['unitsMatched'] ?? 0}/${req['unitsNeeded'] ?? 0}'),
            if (deadline != null) _kv('Deadline', '$deadline'),
            const Divider(height: 24),
            const Text('Demandeur (créateur)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _kv('Nom', demandeur['name'] ?? '—'),
            _kv('Email', demandeur['email'] ?? '—'),
            _kv('Téléphone', demandeur['phone'] ?? '—'),
            const Divider(height: 24),
            const Text('Donneur (candidat)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _kv('Nom', donneur['name'] ?? '—'),
            _kv('Email', donneur['email'] ?? '—'),
            _kv('Téléphone', donneur['phone'] ?? '—'),
            _kv('Groupe', '${donneur['bloodGroup'] ?? '-'}${donneur['rhesus'] ?? ''}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F7F8),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(width: 130, child: Text(k, style: const TextStyle(color: Colors.black54))),
        Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    ),
  );
}

class _JoinRow {
  final Map<String, dynamic> pledge;
  final Map<String, dynamic> request;
  final Map<String, dynamic> requester;
  final Map<String, dynamic> donor;
  _JoinRow({required this.pledge, required this.request, required this.requester, required this.donor});
}
