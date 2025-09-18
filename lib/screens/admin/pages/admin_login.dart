import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pwd.dispose();
    super.dispose();
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email': return 'Email invalide.';
      case 'user-not-found': return 'Aucun compte trouvé.';
      case 'wrong-password':
      case 'invalid-credential': return 'Identifiants incorrects.';
      case 'too-many-requests': return 'Trop de tentatives, réessayez plus tard.';
      default: return e.message ?? e.code;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pwd.text,
      );

      final uid = cred.user!.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = (doc.data()?['role'] ?? 'donneur') as String;

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
        return;
      }
      if (role == 'hopital') {
        // si ton AdminGate route déjà hopital -> HospitalShell
        Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
        return;
      }

      // Rôle non autorisé pour cet espace
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accès refusé.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_mapError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez un email valide d’abord.')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de réinitialisation envoyé.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_mapError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings_rounded, color: cs.primary),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Espace sécurisé Admin',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
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
                    TextFormField(
                      controller: _pwd,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Se connecter'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _loading ? null : _reset, child: const Text('Mot de passe oublié ?')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
