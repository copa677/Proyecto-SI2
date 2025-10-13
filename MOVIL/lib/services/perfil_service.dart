import 'dart:async';
import '../constants.dart';

class PerfilUsuario {
  final String nombre;
  final String rol;
  final String area;

  PerfilUsuario({required this.nombre, required this.rol, required this.area});
}

class PerfilService {
  Future<PerfilUsuario> getPerfil() async {
    if (debugUseMockApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      return PerfilUsuario(
        nombre: 'Demo User',
        rol: 'Supervisor',
        area: 'Producción',
      );
    }
    // TODO: Llamar backend real cuando esté disponible.
    // final resp = await http.get(Uri.parse('$baseUrl/api/perfil'));
    // ...
    return PerfilUsuario(nombre: '', rol: '', area: '');
  }
}
