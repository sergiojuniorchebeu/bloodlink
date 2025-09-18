import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';


class HospitalsPage extends StatelessWidget {
  const HospitalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('hospitals')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _openEditor(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un hôpital'),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('Aucun hôpital.'))
                    : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nom')),
                      DataColumn(label: Text('Ville')),
                      DataColumn(label: Text('Téléphone')),
                      DataColumn(label: Text('Compte')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: docs.map((d) {
                      final m = d.data();
                      final id = d.id;
                      final hasAccount = (m['accountUid'] ?? '').toString().isNotEmpty;
                      return DataRow(cells: [
                        DataCell(Text(m['name'] ?? '—')),
                        DataCell(Text(m['city'] ?? '—')),
                        DataCell(Text(m['phone'] ?? '—')),
                        DataCell(Row(
                          children: [
                            Icon(
                              hasAccount ? Icons.verified_user_rounded : Icons.help_outline_rounded,
                              color: hasAccount ? const Color(0xFF146C43) : const Color(0xFF8A6D1E),
                            ),
                            const SizedBox(width: 6),
                            Flexible(child: Text(hasAccount ? (m['accountUid'] ?? '') : 'Non assigné')),
                          ],
                        )),
                        DataCell(Row(children: [
                          TextButton.icon(
                            onPressed: () => _openEditor(context, id: id, initial: m),
                            icon: const Icon(Icons.edit),
                            label: const Text('Éditer'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _assignDialog(context, hospitalId: id),
                            icon: const Icon(Icons.account_circle_rounded),
                            label: const Text('Assigner / Créer'),
                          ),
                          const SizedBox(width: 8),
                          if (hasAccount)
                            TextButton(
                              onPressed: () async {
                                await AdminService.I.unassignHospitalAccount(hospitalId: id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Compte retiré')),
                                  );
                                }
                              },
                              child: const Text('Retirer compte'),
                            ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final ok = await _confirm(context, 'Supprimer cet hôpital ?');
                              if (ok != true) return;
                              await AdminService.I.deleteHospital(id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Hôpital supprimé')),
                                );
                              }
                            },
                            icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFB00020)),
                            label: const Text('Supprimer', style: TextStyle(color: Color(0xFFB00020))),
                          ),
                        ])),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditor(BuildContext context, {String? id, Map<String, dynamic>? initial}) async {
    final name = TextEditingController(text: initial?['name'] ?? '');
    final city = TextEditingController(text: initial?['city'] ?? '');
    final phone = TextEditingController(text: initial?['phone'] ?? '');
    final email = TextEditingController(text: initial?['contactEmail'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id == null ? 'Nouvel hôpital' : 'Éditer l’hôpital'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom')),
              const SizedBox(height: 8),
              TextField(controller: city, decoration: const InputDecoration(labelText: 'Ville')),
              const SizedBox(height: 8),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Téléphone')),
              const SizedBox(height: 8),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email de contact (optionnel)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty || city.text.trim().isEmpty) return;
              if (id == null) {
                await AdminService.I.createHospital(
                  name: name.text, city: city.text, phone: phone.text, contactEmail: email.text,
                );
              } else {
                await AdminService.I.updateHospital(
                  id, name: name.text, city: city.text, phone: phone.text, contactEmail: email.text,
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignDialog(BuildContext context, {required String hospitalId}) async {
    final emailCtrl = TextEditingController();
    final nameCtrl  = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pwdCtrl   = TextEditingController();
    final cpwdCtrl  = TextEditingController();
    bool createNew = false;
    bool obscure = true;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Assigner / Créer un compte hôpital'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Switch(
                          value: createNew,
                          onChanged: (v) => setState(() => createNew = v),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Créer un NOUVEAU compte avec email + mot de passe'),
                        ),
                      ],
                    ),
                    if (createNew) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nom affiché (ex: Hôpital Général)'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: pwdCtrl,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe (≥ 6 caractères)',
                          suffixIcon: IconButton(
                            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => obscure = !obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: cpwdCtrl,
                        obscureText: obscure,
                        decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              FilledButton(
                child: Text(createNew ? 'Créer & Assigner' : 'Assigner'),
                onPressed: () async {
                  final email = emailCtrl.text.trim();
                  if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email invalide.')));
                    return;
                  }

                  try {
                    if (!createNew) {
                      await AdminService.I.assignHospitalAccount(
                        hospitalId: hospitalId,
                        userEmail: email,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte assigné.')));
                      }
                    } else {
                      final pwd  = pwdCtrl.text;
                      final cpwd = cpwdCtrl.text;
                      if (pwd.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mot de passe trop court.')));
                        return;
                      }
                      if (pwd != cpwd) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les mots de passe ne correspondent pas.')));
                        return;
                      }
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom requis.')));
                        return;
                      }

                      await AdminService.I.createHospitalUserAndLink(
                        hospitalId: hospitalId,
                        email: email,
                        password: pwd,
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte hôpital créé & assigné.')));
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final msg = e.toString().contains('email-already-in-use')
                          ? 'Email déjà utilisé. Choisissez “Assigner” ou un autre email.'
                          : e.toString();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $msg')));
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool?> _confirm(BuildContext context, String text) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
        ],
      ),
    );
  }
}
