import 'package:flutter/material.dart';
import '../widgets/chips_status.dart';


class ProfilePage extends StatelessWidget {
  final bool isVerified;
  final String? verificationStatus;
  final String role; // NEW

  const ProfilePage({super.key, this.isVerified = false, this.verificationStatus, this.role = 'donneur'});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          elevation: 0,
          color: const Color(0xFFF7F7F8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  child: Text('Paulin\nO− • Douala',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.2)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ChipStatus.from(isVerified: isVerified, status: verificationStatus),
                    const SizedBox(height: 6),
                    _RoleChip(role: role), // NEW
                  ],
                ),
              ],
            ),
          ),
        ),
        // ... settings tiles inchangés
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    late String label;
    switch (role) {
      case 'admin':
        bg = const Color(0xFFE9F1FF);
        fg = const Color(0xFF1E4FBF);
        label = 'Admin';
        break;
      case 'receveur':
        bg = const Color(0xFFEFFAF5);
        fg = const Color(0xFF146C43);
        label = 'Receveur';
        break;
      default:
        bg = const Color(0xFFF7F7F8);
        fg = const Color(0xFF333333);
        label = 'Donneur';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

