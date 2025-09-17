import 'package:flutter/material.dart';

import '../widgets/fileds.dart';
import '../widgets/section_tile.dart';

class CreateRequestPage extends StatelessWidget {
  const CreateRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          SectionTitle('Créer une demande'),
          const SizedBox(height: 12),
          Field(label: 'Hôpital / Clinique', hint: 'Ex: Laquintinie'),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: Field(label: 'Groupe', hint: 'O / A / B / AB')),
              SizedBox(width: 12),
              Expanded(child: Field(label: 'Rh', hint: '+ / -')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: Field(label: 'Poches', hint: 'Ex: 2')),
              SizedBox(width: 12),
              Expanded(child: Field(label: 'Deadline', hint: 'Ex: 16:00')),
            ],
          ),
          const SizedBox(height: 12),
          Field(label: 'Localisation', hint: 'Quartier / Ville'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Envoi (UI demo)')),
                );
              },
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Publier la demande'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les notifications seront envoyées aux donneurs compatibles.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}