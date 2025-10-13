import 'package:flutter/material.dart';
import '../widgets/barra_navegacion.dart';
import 'dashboard.dart';
import 'Usuarios.dart';
import 'Configuracion.dart';
import 'personal_g.dart';
import 'asistenciasturnos.dart';
import 'ordenes_produccion.dart';
import 'perfil_usuario.dart';
import 'pedidos_internos.dart';
import 'pruebas.dart';

class PaginaPrincipal extends StatelessWidget {
  const PaginaPrincipal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BarraNavegacion(
      paginas: [
        const Dashboard(),
        const PersonalGestion(),
        const AsistenciasTurnosPage(),
        UsuariosPage(),
        const ConfiguracionPage(),
        const OrdenesProduccionPage(),
        const PedidosInternosPage(),
        const PerfilUsuarioPage(),
        const PruebasPage(),
      ],
    );
  }
}
