import 'package:flutter/material.dart';
import '../widgets/barra_navegacion.dart';
import 'dashboard.dart';

class PaginaPrincipal extends StatelessWidget {
  const PaginaPrincipal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BarraNavegacion(
      paginas: const [
        Dashboard(),
        Placeholder(), // Aquí puedes poner tu widget de Personal
        Placeholder(), // Aquí puedes poner tu widget de Asistencia y Turnos
        Placeholder(), // Aquí puedes poner tu widget de Usuarios
        Placeholder(), // Aquí puedes poner tu widget de Configuración
      ],
    );
  }
}
