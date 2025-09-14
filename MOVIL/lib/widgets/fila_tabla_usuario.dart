import 'package:flutter/material.dart';
import 'etiqueta_estado.dart';

class FilaTablaUsuario extends StatelessWidget {
  final String nombre, id, email, estado, tipo;
  final Widget? acciones;
  const FilaTablaUsuario({
    required this.nombre,
    required this.id,
    required this.email,
    required this.estado,
    required this.tipo,
    this.acciones,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String iniciales = nombre.split(' ').map((e) => e[0]).take(2).join();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Avatar y nombre
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(iniciales, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('ID: $id', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Email
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(email, style: const TextStyle(fontSize: 14)),
            ),
          ),
          // Estado
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: EtiquetaEstado(estado: estado),
            ),
          ),
          // Tipo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(tipo, style: const TextStyle(fontSize: 14)),
            ),
          ),
          // Acciones
          if (acciones != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: acciones!,
            ),
        ],
      ),
    );
  }
}
