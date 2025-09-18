import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projetdonsanguin/screens/admin/pages/hospital_page.dart';
import 'package:projetdonsanguin/screens/admin/pages/request_page.dart';
import 'package:projetdonsanguin/screens/admin/pages/user_page.dart';
import 'package:projetdonsanguin/screens/admin/pages/verification_request_page.dart';


class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _Nav('Vérifications', Icons.verified_user_rounded, VerificationRequestsPage()),
      _Nav('Utilisateurs', Icons.people_alt_rounded, UsersPage()),
      _Nav('Demandes', Icons.format_list_bulleted_rounded, AdminRequestsPage()),
      _Nav('Hôpitaux', Icons.local_hospital_rounded, HospitalsPage()),
    ];
    final safe = _index.clamp(0, pages.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin · ${pages[safe].label}', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: safe,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            groupAlignment: -0.9,
            destinations: [
              for (final p in pages)
                NavigationRailDestination(icon: Icon(p.icon), label: Text(p.label)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[safe].page),
        ],
      ),
    );
  }
}

class _Nav {
  final String label; final IconData icon; final Widget page;
  const _Nav(this.label, this.icon, this.page);
}
