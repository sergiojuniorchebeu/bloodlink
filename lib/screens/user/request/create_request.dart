import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/demande/requestservices.dart';

class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({super.key});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController(text: '2');

  String? _group;
  String? _rh;
  String? _hospitalId;
  DateTime _deadline = DateTime.now().add(const Duration(hours: 24));
  bool _busy = false;

  @override
  void dispose() {
    _patientCtrl..dispose();
    _hospitalCtrl..dispose();
    _cityCtrl..dispose();
    _unitsCtrl..dispose();
    super.dispose();
  }

  Future<void> _pickHospital() async {
    final snap = await FirebaseFirestore.instance.collection('hospitals').orderBy('name').get();
    final items = snap.docs.map<Map<String, String>>((d) {
      final m = d.data();
      return {
        'id': d.id,
        'name': (m['name'] as String?) ?? '—',
        'city': (m['city'] as String?) ?? '—',
      };
    }).toList();

    final res = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (_) => _HospitalPicker(items: items),
    );

    if (res != null) {
      setState(() {
        _hospitalId = res['id'];
        _hospitalCtrl.text = res['name'] ?? '';
        _cityCtrl.text = res['city'] ?? '';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_hospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un hôpital')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await RequestService.I.createDraft(
        createdBy: uid,
        patientGroup: _group!,
        patientRh: _rh!,
        hospitalId: _hospitalId!,
        city: _cityCtrl.text.trim(),
        unitsNeeded: int.tryParse(_unitsCtrl.text.trim()) ?? 1,
        deadline: _deadline,
        patientAlias: _patientCtrl.text.trim().isEmpty ? null : _patientCtrl.text.trim(),
      );

      if (!mounted) return;

      // ✅ Pas de pop : succès + reset du formulaire
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande créée avec succès. En attente de validation.')),
      );

      _formKey.currentState!.reset();
      setState(() {
        _patientCtrl.clear();
        _hospitalCtrl.clear();
        _cityCtrl.clear();
        _unitsCtrl.text = '2';
        _group = null;
        _rh = null;
        _hospitalId = null;
        _deadline = DateTime.now().add(const Duration(hours: 24));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 12 / 10,
                child: Image.asset('assets/img/Blood donation-bro.png'),
              ),
            ),
            const SizedBox(height: 10),
            const _SectionTitle('Créer une demande'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _patientCtrl,
              decoration: const InputDecoration(labelText: 'Patient (alias, optionnel)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _group,
                    decoration: const InputDecoration(labelText: 'Groupe'),
                    items: const ['O', 'A', 'B', 'AB']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _group = v),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    value: _rh,
                    decoration: const InputDecoration(labelText: 'Rh'),
                    items: const ['+', '-']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _rh = v),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hospitalCtrl,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Hôpital (sélection)'),
              onTap: _pickHospital,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityCtrl,
              decoration: const InputDecoration(labelText: 'Ville'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unitsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Poches nécessaires'),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Nombre > 0',
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deadline'),
              subtitle: Text(_deadline.toString()),
              trailing: IconButton(
                icon: const Icon(Icons.edit_calendar_rounded),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 14)),
                    initialDate: _deadline,
                  );
                  if (d != null) {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_deadline),
                    );
                    if (t != null) {
                      setState(() => _deadline = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _submit,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Envoyer pour validation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
  );
}

class _HospitalPicker extends StatelessWidget {
  final List<Map<String, String>> items;
  const _HospitalPicker({super.key, required this.items});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final it = items[i];
          return ListTile(
            title: Text(it['name'] ?? '—'),
            subtitle: Text(it['city'] ?? '—'),
            onTap: () => Navigator.pop(context, it),
          );
        },
      ),
    );
  }
}
