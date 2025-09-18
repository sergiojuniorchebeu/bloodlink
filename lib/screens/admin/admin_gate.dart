import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projetdonsanguin/screens/admin/pages/admin_login.dart';

import '../hopital/hopital_shell.dart';
import 'admin_shell.dart';


class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) return const _Splash();
        final user = authSnap.data;
        if (user == null) return const AdminLoginPage();
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (_, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting) return const _Splash();
            final role = docSnap.data?.data()?['role'] as String? ?? 'donneur';
            if (role == 'admin') return const AdminShell();
            if (role == 'hopital') return const HospitalShell();
            return const _Forbidden();
          },
        );
      },
    );
  }
}


class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _Forbidden extends StatelessWidget {
  const _Forbidden();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 48),
                const SizedBox(height: 12),
                const Text('Accès refusé', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 8),
                const Text('Cette section est réservée aux administrateurs.'),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
                    child: const Text('Retour')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
