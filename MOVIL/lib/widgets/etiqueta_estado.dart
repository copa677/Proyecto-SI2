import 'package:flutter/material.dart';

class EtiquetaEstado extends StatelessWidget {
  final String estado;
  const EtiquetaEstado({Key? key, required this.estado}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color colorFondo = estado == 'Activo'
        ? Colors.green[100]!
        : Colors.grey[300]!;
    Color colorTexto = estado == 'Activo'
        ? Colors.green[800]!
        : Colors.grey[700]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: colorTexto,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
