import 'package:flutter/material.dart';

class SearchBarCard extends StatelessWidget {
  final String hint;
  final VoidCallback onTapFilter;
  const SearchBarCard({required this.hint, required this.onTapFilter});

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
                Text(hint,
                    style: TextStyle(color: Colors.black.withOpacity(0.55))),
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