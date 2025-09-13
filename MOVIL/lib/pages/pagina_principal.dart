import 'package:flutter/material.dart';
import '../widgets/barra_navegacion.dart';
import 'dashboard.dart';
import 'Usuarios.dart';
import 'Configuracion.dart';
import 'personal_g.dart';

class PaginaPrincipal extends StatelessWidget {
  const PaginaPrincipal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BarraNavegacion(
      paginas: [
        const Dashboard(),
        const PersonalGestion(),
        const Placeholder(),
        UsuariosPage(),
        const ConfiguracionPage(),
      ],
    );
  }
}
