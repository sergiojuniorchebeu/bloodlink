import 'package:flutter/material.dart';

import 'h_appointments_page.dart';
import 'h_drafs_page.dart';
import 'h_pledges_page.dart';


class HospitalShell extends StatefulWidget {
  const HospitalShell({super.key});
  @override State<HospitalShell> createState() => _HospitalShellState();
}

class _HospitalShellState extends State<HospitalShell> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = const [
      _Nav('À valider', Icons.assignment_turned_in_rounded, HDraftsPage()),
      _Nav('Candidatures', Icons.how_to_reg_rounded, HPledgesPage()),
      _Nav('Rendez-vous', Icons.event_available_rounded, HAppointmentsPage()),
    ];
    final i = _index.clamp(0, pages.length-1);
    return Scaffold(
      appBar: AppBar(title: Text('Hôpital · ${pages[i].label}', style: const TextStyle(fontWeight: FontWeight.w800))),
      body: Row(children: [
        NavigationRail(
          selectedIndex: i, onDestinationSelected: (v)=>setState(()=>_index=v),
          labelType: NavigationRailLabelType.all,
          destinations: [for (final p in pages) NavigationRailDestination(icon: Icon(p.icon), label: Text(p.label))],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: pages[i].page),
      ]),
    );
  }
}
class _Nav { final String label; final IconData icon; final Widget page; const _Nav(this.label,this.icon,this.page); }
