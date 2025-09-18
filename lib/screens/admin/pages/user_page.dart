import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Rechercher (uid, nom, email, tél)…',
            ),
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snap.data?.docs ?? [];
              if (_q.isNotEmpty) {
                docs = docs.where((d) {
                  final m = d.data();
                  final s = [
                    d.id,
                    m['name'] ?? '',
                    m['email'] ?? '',
                    m['phone'] ?? '',
                    m['role'] ?? '',
                    (m['bloodGroup'] ?? '') + (m['rhesus'] ?? ''),
                  ].join(' ').toLowerCase();
                  return s.contains(_q);
                }).toList();
              }
              if (docs.isEmpty) {
                return const Center(child: Text('Aucun utilisateur.'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('UID')),
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Téléphone')),
                    DataColumn(label: Text('Groupe')),
                    DataColumn(label: Text('Rôle')),
                    DataColumn(label: Text('Vérif.')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: docs.map((d) {
                    final m = d.data();
                    final uid = d.id;
                    final role = (m['role'] ?? 'donneur') as String;
                    final isV = (m['isVerified'] ?? false) as bool;
                    final blood = (m['bloodGroup'] ?? '-') as String;
                    final rh = (m['rhesus'] ?? '-') as String;

                    // Rôles supportés (inclut 'hopital')
                    final supportedRoles = const ['donneur', 'receveur', 'admin', 'hopital'];
                    // Si le rôle venant de Firestore n'est pas dans la liste, on met null pour éviter l'assertion
                    final safeRoleValue = supportedRoles.contains(role) ? role : null;

                    return DataRow(cells: [
                      DataCell(SelectableText(uid, maxLines: 1)),
                      DataCell(Text(m['name'] ?? '—')),
                      DataCell(Text(m['email'] ?? '—')),
                      DataCell(Text(m['phone'] ?? '—')),
                      DataCell(Text('$blood$rh')),
                      DataCell(
                        DropdownButton<String>(
                          value: safeRoleValue,
                          hint: const Text('Rôle'),
                          items: supportedRoles
                              .toSet() // supprime tout doublon éventuel
                              .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r),
                          ))
                              .toList(),
                          onChanged: (v) async {
                            if (v == null) return;
                            await AdminService.I.setUserRole(uid, v);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Rôle mis à jour.')),
                            );
                          },
                        ),
                      ),
                      DataCell(Row(
                        children: [
                          Icon(
                            isV ? Icons.verified_rounded : Icons.help_outline_rounded,
                            color: isV ? const Color(0xFF146C43) : const Color(0xFF8A6D1E),
                          ),
                          const SizedBox(width: 4),
                          Text(isV ? 'Vérifié' : 'Non vérifié'),
                        ],
                      )),
                      DataCell(Row(
                        children: [
                          FilledButton(
                            onPressed: isV
                                ? null
                                : () async {
                              await AdminService.I.setUserVerified(uid, true);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Compte vérifié.')),
                              );
                            },
                            child: const Text('Valider'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: !isV
                                ? null
                                : () async {
                              await AdminService.I.setUserVerified(uid, false);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vérification retirée.')),
                              );
                            },
                            child: const Text('Retirer'),
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
