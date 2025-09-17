import 'package:flutter/material.dart';

import '../alertes/alertes.dart';
import '../profile/profile_page.dart';
import '../request/create_request.dart';
import '../urgences/urgences.dart';

class HomeShell extends StatefulWidget {
  final bool isVerified; // contrôle l’affichage de l’onglet Demande
  const HomeShell({super.key, this.isVerified = false});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final items = <_NavItem>[
      _NavItem(
        label: 'Urgences',
        icon: Icons.emergency_rounded,
        page: const UrgencesPage(),
      ),
      if (widget.isVerified)
        _NavItem(
          label: 'Demande',
          icon: Icons.add_circle_rounded,
          page: const CreateRequestPage(),
        ),
      _NavItem(
        label: 'Alertes',
        icon: Icons.notifications_rounded,
        page: const AlertsPage(),
      ),
      _NavItem(
        label: 'Profil',
        icon: Icons.person_rounded,
        page: const ProfilePage(),
      ),
    ];

    // sécurité index si la liste d’onglets change
    final safeIndex = _index.clamp(0, items.length - 1);

    final titles = items.map((e) => e.label).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          titles[safeIndex],
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (safeIndex == 0)
            IconButton(
              onPressed: () {},
              tooltip: 'Filtrer',
              icon: const Icon(Icons.tune_rounded),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: items[safeIndex].page,
      ),
      floatingActionButton: (!widget.isVerified || safeIndex != 0)
          ? null
          : FloatingActionButton.extended(
        onPressed: () {
          // accès rapide à la création (visible seulement si vérifié)
          final demandeIndex =
          items.indexWhere((e) => e.label == 'Demande');
          if (demandeIndex != -1) {
            setState(() => _index = demandeIndex);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fonction bientôt dispo.')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle demande'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        surfaceTintColor: Colors.transparent,
        destinations: [
          for (final it in items)
            NavigationDestination(icon: Icon(it.icon), label: it.label),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final Widget page;
  _NavItem({required this.label, required this.icon, required this.page});
}



















