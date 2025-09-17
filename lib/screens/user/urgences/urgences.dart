import 'package:flutter/material.dart';

class UrgencesPage extends StatelessWidget {
  const UrgencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SearchBarCard(
          hint: 'Rechercher hôpital / groupe…',
          onTapFilter: () {},
        ),
        const SizedBox(height: 12),
        _UrgenceCard(
          title: 'O− urgent – Laquintinie',
          city: 'Douala • 2.1 km',
          chips: const ['O−', '2 poches', 'Avant 16:00'],
          onTap: () {},
        ),
        _UrgenceCard(
          title: 'A+ – Hôpital Général',
          city: 'Douala • 5.4 km',
          chips: const ['A+', '1 poche', 'Avant 18:30'],
          onTap: () {},
        ),
        _UrgenceCard(
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

class _SearchBarCard extends StatelessWidget {
  final String hint;
  final VoidCallback onTapFilter;
  const _SearchBarCard({required this.hint, required this.onTapFilter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 22),
                const SizedBox(width: 8),
                Text(hint, style: TextStyle(color: Colors.black.withOpacity(0.55))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTapFilter,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.tune_rounded, color: cs.primary),
          ),
        ),
      ],
    );
  }
}

class _UrgenceCard extends StatelessWidget {
  final String title;
  final String city;
  final List<String> chips;
  final VoidCallback onTap;

  const _UrgenceCard({
    required this.title,
    required this.city,
    required this.chips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bloodtype_rounded, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(city, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: -6,
                      children: chips
                          .map(
                            (c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.black.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
