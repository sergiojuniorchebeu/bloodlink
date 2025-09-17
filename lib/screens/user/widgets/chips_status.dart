import 'package:flutter/material.dart';

class ChipStatus extends StatelessWidget {
  final Color bg;
  final Color fg;
  final String text;
  final IconData? icon;

  const ChipStatus._(this.bg, this.fg, this.text, [this.icon]);

  factory ChipStatus.verified() =>
      const ChipStatus._(Color(0xFFE7F8EF), Color(0xFF146C43), 'Vérifié', Icons.verified_rounded);

  factory ChipStatus.pending() =>
      const ChipStatus._(Color(0xFFFFF7E6), Color(0xFF8A6D1E), 'En cours', Icons.hourglass_top_rounded);

  factory ChipStatus.rejected() =>
      const ChipStatus._(Color(0xFFFFE7E7), Color(0xFF8A1E1E), 'Rejeté', Icons.error_rounded);

  factory ChipStatus.unknown() =>
      const ChipStatus._(Color(0xFFFFF2CC), Color(0xFF8A6D1E), 'Non vérifié');

  factory ChipStatus.from({required bool? isVerified, String? status}) {
    switch (status) {
      case 'verified':
        return ChipStatus.verified();
      case 'pending':
        return ChipStatus.pending();
      case 'rejected':
        return ChipStatus.rejected();
    }
    if (isVerified == true) return ChipStatus.verified();
    if (isVerified == false) return ChipStatus.unknown();
    return ChipStatus.unknown();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
