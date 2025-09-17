import 'package:flutter/material.dart';
import '../widgets/search_bar.dart';
import '../widgets/urgence_card.dart';

class UrgencesPage extends StatelessWidget {
  const UrgencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SearchBarCard(
          hint: 'Rechercher hôpital / groupe…',
          onTapFilter: () {},
        ),
        const SizedBox(height: 12),
        UrgenceCard(
          title: 'O− urgent – Laquintinie',
          city: 'Douala • 2.1 km',
          chips: const ['O−', '2 poches', 'Avant 16:00'],
          onTap: () {},
        ),
        UrgenceCard(
          title: 'A+ – Hôpital Général',
          city: 'Douala • 5.4 km',
          chips: const ['A+', '1 poche', 'Avant 18:30'],
          onTap: () {},
        ),
        UrgenceCard(
          title: 'B− – Clinique du Littoral',
          city: 'Bonapriso • 3.2 km',
          chips: const ['B−', '3 poches', 'Demain 09:00'],
          onTap: () {},
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualiser'),
          ),
        )
      ],
    );
  }
}