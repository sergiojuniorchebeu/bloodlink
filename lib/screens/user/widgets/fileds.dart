import 'package:flutter/material.dart';

class Field extends StatelessWidget {
  final String label;
  final String hint;
  const Field({required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}