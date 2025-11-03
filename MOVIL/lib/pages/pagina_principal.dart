import 'package:flutter/material.dart';
import '../widgets/barra_navegacion.dart';
import 'dashboard.dart';
// import 'Usuarios.dart'; // ocultado temporalmente
import 'Configuracion.dart';
// import 'personal_g.dart'; // ocultado temporalmente
import 'asistenciasturnos.dart';
import 'ordenes_produccion.dart';
import 'perfil_usuario.dart';
// import 'pedidos_internos.dart'; // removido para producción
// import 'pruebas.dart'; // removido

class PaginaPrincipal extends StatelessWidget {
  const PaginaPrincipal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BarraNavegacion(
      paginas: [
        // 1. Dashboard
        const Dashboard(),
        // 2. Órdenes
        const OrdenesProduccionPage(),
        // 3. Asistencia y Turnos
        const AsistenciasTurnosPage(),
        // 4. Configuración
        const ConfiguracionPage(),
        // 5. Perfil
        const PerfilUsuarioPage(),
        // Ocultos temporalmente (no borrar):
        // const PersonalGestion(),
        // UsuariosPage(),
        // const PedidosInternosPage(), // removido para producción
      ],
    );
  }
}
