import 'package:flutter/material.dart';

class ChipStatus extends StatelessWidget {
  final Color bg;
  final Color fg;
  final String text;

  const ChipStatus._(this.bg, this.fg, this.text);

  factory ChipStatus.unknown() =>
      const ChipStatus._(Color(0xFFFFF2CC), Color(0xFF8A6D1E), 'Non vérifié');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}