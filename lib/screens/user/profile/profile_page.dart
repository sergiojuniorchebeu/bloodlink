import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/auth/authservices.dart';
import '../../../services/storage/storage_services.dart';
import '../widgets/chips_status.dart';
import '../widgets/settings_tile.dart';



class ProfilePage extends StatefulWidget {
  final bool isVerified;
  final String? verificationStatus;
  final String role; // 'donneur' | 'receveur' | 'admin'

  const ProfilePage({
    super.key,
    this.isVerified = false,
    this.verificationStatus,
    this.role = 'donneur',
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;
    return StreamBuilder<Map<String, dynamic>?>(
      stream: UserService.I.streamProfile(user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data ?? {};
        final name = (data['name'] ?? user.displayName ?? 'Utilisateur') as String;
        final email = (data['email'] ?? user.email ?? '') as String;
        final phone = (data['phone'] ?? '') as String;
        final blood = (data['bloodGroup'] ?? '-') as String;
        final rh = (data['rhesus'] ?? '-') as String;
        final city = (data['city'] ?? '—') as String?;
        final radiusKm = (data['radiusKm'] ?? 20) as int;
        final isVerified = (data['isVerified'] ?? widget.isVerified) as bool;
        final status = (data['verificationStatus'] ?? widget.verificationStatus ?? 'unverified') as String;
        final role = (data['role'] ?? widget.role) as String;
        final available = (data['available'] ?? true) as bool;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _HeaderCard(
              name: name,
              subtitle: '$blood$rh • ${city ?? "Ville ?"}',
              isVerified: isVerified,
              status: status,
              role: role,
            ),
            const SizedBox(height: 16),

            // Édition du profil
            SettingTile(
              icon: Icons.edit_rounded,
              title: 'Éditer le profil',
              subtitle: '$email · $phone',
              onTap: _busy ? (){} : () => _openEditProfile(name, phone, blood, rh),
            ),

            // Disponibilité
            Card(
              elevation: 0,
              color: Colors.white,
              surfaceTintColor: Colors.white,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SwitchListTile.adaptive(
                dense: false,
                secondary: const Icon(Icons.toggle_on_rounded),
                title: const Text('Disponible pour donner'),
                subtitle: const Text('Recevoir des alertes compatibles'),
                value: available,
                onChanged: _busy ? null : (val) async {
                  setState(() => _busy = true);
                  try {
                    await UserService.I.setAvailability(user.uid, val);
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
              ),
            ),

            // Ville & rayon
            SettingTile(
              icon: Icons.place_rounded,
              title: 'Ville & rayon',
              subtitle: '${city ?? "—"} • $radiusKm km',
              onTap: _busy ? (){} : () => _openLocation(city ?? '', radiusKm),
            ),

            // Vérification
            SettingTile(
              icon: Icons.verified_user_rounded,
              title: 'Vérification du profil',
              subtitle: _verifySubtitle(isVerified, status),
              onTap: _busy || isVerified ? (){} : _pickAndSubmitId,
            ),

            // Sécurité
            SettingTile(
              icon: Icons.lock_reset_rounded,
              title: 'Changer le mot de passe',
              subtitle: 'Recevoir un email de réinitialisation',
              onTap: _busy ? (){} : _resetPassword,
            ),

            // Déconnexion
            SettingTile(
              icon: Icons.logout_rounded,
              title: 'Déconnexion',
              subtitle: 'Se déconnecter de ce dispositif',
              onTap: _busy ? (){} : _signOut,
            ),

            // Danger zone (optionnel)
            Card(
              elevation: 0,
              color: const Color(0xFFFFF4F4),
              margin: const EdgeInsets.only(top: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFB00020)),
                title: const Text('Supprimer mon compte', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Action irréversible (peut nécessiter une reconnexion récente)'),
                onTap: _busy ? null : _deleteAccount,
              ),
            ),
          ],
        );
      },
    );
  }

  String _verifySubtitle(bool isVerified, String status) {
    if (isVerified || status == 'verified') return 'Votre compte est déjà vérifié';
    if (status == 'pending') return 'Vérification en cours…';
    if (status == 'rejected') return 'Vérification rejetée — renvoyez une pièce';
    return 'Ajoutez une pièce d’identité pour déverrouiller “Demande”';
  }

  Future<void> _openEditProfile(String name, String phone, String blood, String rh) async {
    final result = await showModalBottomSheet<_EditProfileResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditProfileSheet(
        name: name,
        phone: phone,
        bloodGroup: blood,
        rh: rh,
      ),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      final uid = _auth.currentUser!.uid;
      await UserService.I.updateProfile(
        uid,
        name: result.name,
        phone: result.phone,
        bloodGroup: result.group,
        rh: result.rh,
      );
      if (mounted && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(result.name);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLocation(String city, int radiusKm) async {
    final res = await showModalBottomSheet<_LocationResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditLocationSheet(city: city, radiusKm: radiusKm),
    );
    if (res == null) return;
    setState(() => _busy = true);
    try {
      await UserService.I.setCityRadius(_auth.currentUser!.uid, city: res.city, radiusKm: res.radiusKm);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Localisation mise à jour.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAndSubmitId() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (x == null) return;
      setState(() => _busy = true);
      final file = File(x.path);
      final url = await StorageService.I.uploadIdImage(file: file, uid: _auth.currentUser!.uid);
      await UserService.I.markVerificationPending(_auth.currentUser!.uid, idUrl: url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pièce envoyée. En cours de vérification.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec de l’envoi: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun email lié au compte.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email de réinitialisation envoyé.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); // Landing
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: const Text('Cette action est irréversible. Vos données seront supprimées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      final uid = _auth.currentUser!.uid;
      // Supprimer la fiche profil (les fichiers Storage ne sont pas supprimés ici)
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      // Supprimer le compte Auth (peut nécessiter une reconnexion récente)
      await _auth.currentUser!.delete();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = (e.code == 'requires-recent-login')
          ? 'Veuillez vous reconnecter puis réessayer.'
          : 'Erreur: ${e.message ?? e.code}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isVerified;
  final String status;
  final String role;

  const _HeaderCard({
    required this.name,
    required this.subtitle,
    required this.isVerified,
    required this.status,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: const Color(0xFFF7F7F8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: cs.primary.withOpacity(0.12),
              child: Icon(Icons.bloodtype_rounded, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name.isEmpty ? 'Utilisateur' : name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.2),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ChipStatus.from(isVerified: isVerified, status: status),
                const SizedBox(height: 6),
                _RoleChip(role: role),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    late String label;
    switch (role) {
      case 'admin':
        bg = const Color(0xFFE9F1FF);
        fg = const Color(0xFF1E4FBF);
        label = 'Admin';
        break;
      case 'receveur':
        bg = const Color(0xFFEFFAF5);
        fg = const Color(0xFF146C43);
        label = 'Receveur';
        break;
      default:
        bg = const Color(0xFFF7F7F8);
        fg = const Color(0xFF333333);
        label = 'Donneur';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

/// ==== Bottom sheets ====

class EditProfileSheet extends StatefulWidget {
  final String name;
  final String phone;
  final String bloodGroup;
  final String rh;

  const EditProfileSheet({
    super.key,
    required this.name,
    required this.phone,
    required this.bloodGroup,
    required this.rh,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  String? _group;
  String? _rh;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
    _phone = TextEditingController(text: widget.phone);
    _group = widget.bloodGroup;
    _rh = widget.rh;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Éditer le profil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nom complet'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Téléphone obligatoire';
                  final ok = RegExp(r'^[0-9+\s]{8,}$').hasMatch(v.trim());
                  if (!ok) return 'Numéro invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _group,
                      decoration: const InputDecoration(labelText: 'Groupe'),
                      items: const [
                        DropdownMenuItem(value: 'O', child: Text('O')),
                        DropdownMenuItem(value: 'A', child: Text('A')),
                        DropdownMenuItem(value: 'B', child: Text('B')),
                        DropdownMenuItem(value: 'AB', child: Text('AB')),
                      ],
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
                      items: const [
                        DropdownMenuItem(value: '+', child: Text('+')),
                        DropdownMenuItem(value: '-', child: Text('-')),
                      ],
                      onChanged: (v) => setState(() => _rh = v),
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(context, _EditProfileResult(
                    name: _name.text.trim(),
                    phone: _phone.text.trim(),
                    group: _group!,
                    rh: _rh!,
                  ));
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileResult {
  final String name;
  final String phone;
  final String group;
  final String rh;
  _EditProfileResult({required this.name, required this.phone, required this.group, required this.rh});
}

class EditLocationSheet extends StatefulWidget {
  final String city;
  final int radiusKm;

  const EditLocationSheet({super.key, required this.city, required this.radiusKm});

  @override
  State<EditLocationSheet> createState() => _EditLocationSheetState();
}

class _EditLocationSheetState extends State<EditLocationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _city;
  double _radius = 20;

  @override
  void initState() {
    super.initState();
    _city = TextEditingController(text: widget.city);
    _radius = widget.radiusKm.toDouble();
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Ville & rayon', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'Ville / Quartier'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ville obligatoire' : null,
              ),
              const SizedBox(height: 12),
              Text('Rayon de recherche : ${_radius.round()} km',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: _radius,
                min: 5,
                max: 100,
                divisions: 19,
                label: '${_radius.round()} km',
                onChanged: (v) => setState(() => _radius = v),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(context, _LocationResult(city: _city.text.trim(), radiusKm: _radius.round()));
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationResult {
  final String city;
  final int radiusKm;
  _LocationResult({required this.city, required this.radiusKm});
}
