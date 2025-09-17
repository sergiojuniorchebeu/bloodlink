import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/auth/authservices.dart';


class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _group; // A, B, AB, O
  String? _rh; // +, -
  bool _loading = false;

  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email invalide.';
      case 'email-already-in-use':
        return 'Email déjà utilisé.';
      case 'weak-password':
        return 'Mot de passe trop faible.';
      case 'operation-not-allowed':
        return 'Méthode de connexion désactivée.';
      default:
        return 'Erreur: ${e.message ?? e.code}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_group == null || _rh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez votre groupe & Rh')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text,
      );

      await cred.user?.updateDisplayName(_nameCtrl.text.trim());

      await UserService.I.createProfile(
        user: cred.user!,
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        bloodGroup: _group!,
        rh: _rh!,
        role: 'donneur', // par défaut
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte créé. Bienvenue !')),
      );
      // L’AuthGate sur /home chargera le profil et affichera HomeShell
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapAuthError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un compte"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 15 / 10,
                    child: Image.asset('assets/img/Blood donation-bro.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
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
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email obligatoire';
                    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                    if (!ok) return 'Email invalide';
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pwdCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 6) return 'Au moins 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                  validator: (v) {
                    if (v != _pwdCtrl.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _loading
                      ? const SizedBox(
                      height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("S'inscrire"),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed:
                  _loading ? null : () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text("J'ai déjà un compte"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
