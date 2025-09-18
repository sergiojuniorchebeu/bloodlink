import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_service.dart';

class VerificationRequestsPage extends StatelessWidget {
  const VerificationRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('verification_requests')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Aucune demande de vérification.'));
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (_, c) => DataTable(
              columns: const [
                DataColumn(label: Text('Utilisateur')),
                DataColumn(label: Text('Statut')),
                DataColumn(label: Text('Pièce')),
                DataColumn(label: Text('Actions')),
              ],
              rows: docs.map((d) {
                final m = d.data();
                final uid = m['uid'] as String? ?? d.id;
                final status = (m['status'] ?? 'pending') as String;
                final url = m['idImageUrl'] as String? ?? '';
                return DataRow(cells: [
                  DataCell(Text(uid)),
                  DataCell(_StatusPill(status)),
                  DataCell(url.isEmpty
                      ? const Text('—')
                      : TextButton(
                    onPressed: () => _preview(context, url),
                    child: const Text('Voir'),
                  )),
                  DataCell(Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          await AdminService.I.approveVerification(uid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vérification approuvée')),
                          );
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Approuver'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final reason = await _askReason(context);
                          await AdminService.I.rejectVerification(uid, reason: reason);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vérification rejetée')),
                          );
                        },
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Refuser'),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  static void _preview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 720,
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  static Future<String?> _askReason(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motif (optionnel)'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Ex: photo floue…')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Valider')),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg;
    switch (status) {
      case 'approved': bg = const Color(0xFFE7F8EF); fg = const Color(0xFF146C43); break;
      case 'rejected': bg = const Color(0xFFFFE7E7); fg = const Color(0xFF8A1E1E); break;
      case 'pending':
      default: bg = const Color(0xFFFFF7E6); fg = const Color(0xFF8A6D1E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(status, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
