import 'package:flutter/material.dart';

class CabeceraTabla extends StatelessWidget {
  final List<String> columnas;
  const CabeceraTabla({Key? key, required this.columnas}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: columnas
            .map((col) => Expanded(
                  child: Text(col, style: const TextStyle(fontWeight: FontWeight.bold)),
                ))
            .toList(),
      ),
    );
  }
}
