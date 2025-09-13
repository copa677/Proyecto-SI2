import 'package:flutter/material.dart';

class DropdownPersonalizado extends StatelessWidget {
  final List<String> items;
  final String? valorSeleccionado;
  final ValueChanged<String?>? onChanged;
  final String? hint;
  const DropdownPersonalizado({Key? key, required this.items, this.valorSeleccionado, this.onChanged, this.hint}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: valorSeleccionado ?? items.first,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        filled: true,
        fillColor: Colors.grey[100],
        hintText: hint,
      ),
    );
  }
}
