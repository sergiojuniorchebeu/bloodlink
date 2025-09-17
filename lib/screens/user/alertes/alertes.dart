import 'package:flutter/material.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: const [
        _AlertTile(
          title: 'Demande O− près de vous',
          subtitle: 'Laquintinie • 2.1 km • il y a 5 min',
        ),
        _AlertTile(
          title: 'Votre profil a été vu 3 fois',
          subtitle: 'Cette semaine',
        ),
        _AlertTile(
          title: 'Rappel d’éligibilité',
          subtitle: 'Vous pouvez redonner à partir du 12/10',
        ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final String title;
  final String subtitle;
  const _AlertTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: cs.primary.withOpacity(0.10),
        child: Icon(Icons.notifications_rounded, color: cs.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }
}
