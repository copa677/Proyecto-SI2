import 'package:flutter/material.dart';

class CabeceraTabla extends StatelessWidget {
  final List<String> columnas;
  const CabeceraTabla({Key? key, required this.columnas}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // USUARIO (avatar+nombre+id)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(columnas[0], style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          // EMAIL
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(columnas[1], style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          // ESTADO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(columnas[2], style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          // TIPO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(columnas[3], style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
