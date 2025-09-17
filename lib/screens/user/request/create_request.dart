import 'package:flutter/material.dart';

class CreateRequestPage extends StatelessWidget {
  const CreateRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          const _SectionTitle('Créer une demande'),
          const SizedBox(height: 12),
          const _Field(label: 'Hôpital / Clinique', hint: 'Ex: Laquintinie'),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _Field(label: 'Groupe', hint: 'O / A / B / AB')),
              SizedBox(width: 12),
              Expanded(child: _Field(label: 'Rh', hint: '+ / -')),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _Field(label: 'Poches', hint: 'Ex: 2')),
              SizedBox(width: 12),
              Expanded(child: _Field(label: 'Deadline', hint: 'Ex: 16:00')),
            ],
          ),
          const SizedBox(height: 12),
          const _Field(label: 'Localisation', hint: 'Quartier / Ville'),
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

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  const _Field({required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(decoration: InputDecoration(labelText: label, hintText: hint));
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
    );
  }
}
