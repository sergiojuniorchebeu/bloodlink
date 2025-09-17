import 'package:flutter/material.dart';

import '../widgets/chips_status.dart';
import '../widgets/settings_tile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          elevation: 0,
          color: const Color(0xFFF7F7F8),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: cs.primary.withOpacity(0.12),
                  child: Icon(Icons.bloodtype_rounded, color: cs.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Paulin\nO− • Douala',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                ),
                ChipStatus.unknown(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SettingTile(
          icon: Icons.verified_user_rounded,
          title: 'Vérification du profil',
          subtitle: 'Ajoutez une pièce d’identité pour déverrouiller “Demande”',
          onTap: () {},
        ),
        SettingTile(
          icon: Icons.place_rounded,
          title: 'Ville & rayon',
          subtitle: 'Douala • 20 km',
          onTap: () {},
        ),
        SettingTile(
          icon: Icons.lock_rounded,
          title: 'Confidentialité',
          subtitle: 'Numéro masqué par défaut',
          onTap: () {},
        ),
        SettingTile(
          icon: Icons.logout_rounded,
          title: 'Déconnexion',
          subtitle: '—',
          onTap: () {},
        ),
      ],
    );
  }
}