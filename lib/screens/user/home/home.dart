import 'package:flutter/material.dart';

import '../alertes/alertes.dart';
import '../profile/profile_page.dart';
import '../request/create_request.dart';
import '../urgences/urgences.dart';


class HomeShell extends StatefulWidget {
  final bool isVerified;
  final String role; // 'donneur' | 'receveur' | 'admin'
  const HomeShell({super.key, required this.isVerified, required this.role});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Demande visible si vérifié ET pas admin
    final canCreateRequest = widget.isVerified && widget.role != 'admin';

    final items = <_NavItem>[
      _NavItem(label: 'Urgences', icon: Icons.emergency_rounded, page: const UrgencesPage()),
      if (canCreateRequest)
        _NavItem(label: 'Demande', icon: Icons.add_circle_rounded, page: const CreateRequestPage()),
      _NavItem(label: 'Alertes', icon: Icons.notifications_rounded, page: const AlertsPage()),
      _NavItem(
        label: 'Profil',
        icon: Icons.person_rounded,
        page: ProfilePage(
          isVerified: widget.isVerified,
          verificationStatus: widget.isVerified ? 'verified' : 'unverified',
          role: widget.role,
        ),
      ),
    ];

    final safeIndex = _index.clamp(0, items.length - 1);
    final titles = items.map((e) => e.label).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(titles[safeIndex], style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (safeIndex == 0)
            IconButton(onPressed: () {}, tooltip: 'Filtrer', icon: const Icon(Icons.tune_rounded)),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: items[safeIndex].page,
      ),
      floatingActionButton: (!canCreateRequest || safeIndex != 0)
          ? null
          : FloatingActionButton.extended(
        onPressed: () {
          final i = items.indexWhere((e) => e.label == 'Demande');
          if (i != -1) setState(() => _index = i);
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
        destinations: [for (final it in items) NavigationDestination(icon: Icon(it.icon), label: it.label)],
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






















