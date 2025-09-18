import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Veuillez vous connecter.'));
    }

    final apptStream = FirebaseFirestore.instance
        .collection('appointments')
        .where('donorUid', isEqualTo: uid)
        .snapshots();

    final pledgesStream = FirebaseFirestore.instance
        .collection('pledges')
        .where('donorUid', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: apptStream,
      builder: (context, apptSnap) {
        if (apptSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final appts = apptSnap.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: pledgesStream,
          builder: (context, pledgesSnap) {
            if (pledgesSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final pledges = pledgesSnap.data?.docs ?? [];

            final items = <_AlertItem>[];

            // 1) RDV programmés
            for (final d in appts) {
              final m = d.data();
              final time = (m['time'] as Timestamp?)?.toDate();
              items.add(_AlertItem(
                type: _AlertType.appointment,
                title: 'RDV programmé',
                subtitle: _formatApptSubtitle(m, time),
                when: time ?? (m['createdAt'] as Timestamp?)?.toDate(),
                payload: {
                  'appointmentId': d.id,
                  'requestId': m['requestId'],
                  'donorUid': m['donorUid'],
                },
              ));
            }

            // 2) Candidatures acceptées
            for (final d in pledges) {
              final m = d.data();
              final when = (m['updatedAt'] as Timestamp?)?.toDate() ??
                  (m['createdAt'] as Timestamp?)?.toDate();
              items.add(_AlertItem(
                type: _AlertType.pledgeAccepted,
                title: 'Candidature acceptée',
                subtitle:
                'Votre candidature pour la demande ${m['requestId']} a été acceptée.',
                when: when,
                payload: {
                  'pledgeId': d.id,
                  'requestId': m['requestId'],
                  'donorUid': m['donorUid'],
                },
              ));
            }

            // Tri décroissant (récent en haut)
            items.sort((a, b) {
              final va = a.when?.millisecondsSinceEpoch ?? 0;
              final vb = b.when?.millisecondsSinceEpoch ?? 0;
              return vb.compareTo(va);
            });

            if (items.isEmpty) {
              return const Center(child: Text('Aucune alerte pour le moment.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (context, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final it = items[i];
                return _AlertTile.dynamic(
                  type: it.type,
                  title: it.title,
                  subtitle: it.subtitle,
                  onTap: () {
                    // Remplace par ta navigation si besoin
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(it.title)),
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

  String _formatApptSubtitle(Map<String, dynamic> m, DateTime? time) {
    final reqId = (m['requestId'] ?? '—').toString();
    final hosp = (m['hospitalId'] ?? '—').toString();
    final datePart = time != null ? '${time.toLocal()}' : 'bientôt';
    return 'Demande: $reqId • Hôpital: $hosp • $datePart';
  }
}

enum _AlertType { appointment, pledgeAccepted }

class _AlertItem {
  final _AlertType type;
  final String title;
  final String subtitle;
  final DateTime? when;
  final Map<String, dynamic> payload;

  _AlertItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.when,
    required this.payload,
  });
}

class _AlertTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _AlertTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  factory _AlertTile.dynamic({
    required _AlertType type,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    switch (type) {
      case _AlertType.appointment:
        return _AlertTile(
          title: title,
          subtitle: subtitle,
          icon: Icons.event_available_rounded,
          onTap: onTap,
        );
      case _AlertType.pledgeAccepted:
        return _AlertTile(
          title: title,
          subtitle: subtitle,
          icon: Icons.how_to_reg_rounded,
          onTap: onTap,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: cs.primary.withOpacity(0.10),
        child: Icon(icon, color: cs.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
