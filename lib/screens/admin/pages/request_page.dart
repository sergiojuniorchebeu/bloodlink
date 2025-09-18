import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_service.dart';

class AdminRequestsPage extends StatelessWidget {
  const AdminRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance.collection('requests').orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Aucune demande.'));
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Patient')),
              DataColumn(label: Text('Groupe')),
              DataColumn(label: Text('Poches')),
              DataColumn(label: Text('Hôpital')),
              DataColumn(label: Text('Deadline')),
              DataColumn(label: Text('Statut')),
              DataColumn(label: Text('Actions')),
            ],
            rows: docs.map((d) {
              final m = d.data();
              final id = d.id;
              final g = (m['bloodGroup'] ?? '-') as String;
              final rh = (m['rhesus'] ?? '-') as String;
              final status = (m['status'] ?? 'open') as String;
              return DataRow(cells: [
                DataCell(SelectableText(id)),
                DataCell(Text(m['patientAlias'] ?? '—')),
                DataCell(Text('$g$rh')),
                DataCell(Text('${m['unitsNeeded'] ?? '—'}')),
                DataCell(Text(m['hospital'] ?? '—')),
                DataCell(Text((m['deadline'] ?? '—').toString())),
                DataCell(Text(status)),
                DataCell(Row(
                  children: [
                    if (status != 'closed')
                      OutlinedButton(
                        onPressed: () async {
                          await AdminService.I.closeRequest(id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Demande clôturée.')),
                          );
                        },
                        child: const Text('Clore'),
                      ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
}
