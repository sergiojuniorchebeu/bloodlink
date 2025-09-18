import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../request/request_details_page.dart';

class UrgencesPage extends StatelessWidget {
  const UrgencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Toutes les demandes approuvées / ouvertes
    final q = FirebaseFirestore.instance
        .collection('requests')
        .where('status', whereIn: ['approved', 'open']);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snap.data?.docs ?? [];

        // Tri local DESC par createdAt (évite index composite)
        docs.sort((a, b) {
          final ta = a.data()['createdAt'] as Timestamp?;
          final tb = b.data()['createdAt'] as Timestamp?;
          final va = ta?.millisecondsSinceEpoch ?? 0;
          final vb = tb?.millisecondsSinceEpoch ?? 0;
          return vb.compareTo(va);
        });

        if (docs.isEmpty) {
          return const Center(child: Text('Aucune demande disponible pour le moment.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final m = docs[i].data();
            final deadline = (m['deadline'] as Timestamp?)?.toDate();
            final chips = <String>[
              '${m['bloodGroup'] ?? '-'}${m['rhesus'] ?? ''}',
              '${m['unitsNeeded'] ?? '?'} poches',
              if (deadline != null) 'Avant $deadline',
            ];

            return _UrgenceCard(
              title:
              '${m['bloodGroup'] ?? '-'}${m['rhesus'] ?? ''} – ${m['patientAlias'] ?? 'Patient'}',
              city:
              '${m['city'] ?? '—'} • ${m['unitsMatched'] ?? 0}/${m['unitsNeeded'] ?? 0}',
              chips: chips,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestDetailPage(requestId: m['id']),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _UrgenceCard extends StatelessWidget {
  final String title;
  final String city;
  final List<String> chips;
  final VoidCallback onTap;

  const _UrgenceCard({
    required this.title,
    required this.city,
    required this.chips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bloodtype_rounded, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(city, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: -6,
                      children: chips
                          .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(c,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.black.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
