import 'package:flutter/material.dart';
import '../widgets/alert_tile.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: const [
        AlertTile(
          title: 'Demande O− près de vous',
          subtitle: 'Laquintinie • 2.1 km • il y a 5 min',
        ),
        AlertTile(
          title: 'Votre profil a été vu 3 fois',
          subtitle: 'Cette semaine',
        ),
        AlertTile(
          title: 'Rappel d’éligibilité',
          subtitle: 'Vous pouvez redonner à partir du 12/10',
        ),
      ],
    );
  }
}