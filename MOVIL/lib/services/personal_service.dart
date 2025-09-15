// lib/services/personal_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

/// Servicio para interactuar con el backend relacionado al personal.
class PersonalService {
  /// Devuelve una lista de empleados.
  Future<List<dynamic>> getEmpleados() async {
    final url = Uri.parse('$baseUrl/api/personal/getEmpleados');
    final resp = await http.get(url);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    } else {
      throw Exception('Error al obtener empleados: ${resp.statusCode}');
    }
  }

  /// Registra un nuevo empleado.
  Future<bool> registrarEmpleado(Map<String, dynamic> datos) async {
    final url = Uri.parse('$baseUrl/api/personal/registrar');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );
    return resp.statusCode == 200;
  }

  /// Actualiza un empleado existente.
  Future<bool> actualizarEmpleado(Map<String, dynamic> datos) async {
    final url = Uri.parse('$baseUrl/api/personal/actualizar');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );
    return resp.statusCode == 200;
  }

  /// Elimina un empleado junto con su usuario.
  Future<bool> eliminarEmpleado(int idUsuario) async {
    final url = Uri.parse('$baseUrl/api/personal/eliminar');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_usuario': idUsuario}),
    );
    return resp.statusCode == 200;
  }

  // --- Endpoints adicionales (aún no usados en la app) ---
  // El backend tiene definidos en personal/urls.py las rutas:
  //  - api/personal/getEmpleado/<nombre>         -> obtener_empleado_nombre
  //  - api/personal/getEmpleadoID/<id_usuario>   -> obtener_empleado_por_usuario
  // Estas rutas permiten traer un empleado concreto por nombre o por ID,
  // pero de momento no se utilizan en la interfaz actual.
  // Si en el futuro necesitas ver o editar un único empleado, debes implementar
  // aquí métodos similares a getEmpleados() que hagan peticiones GET a esas URLs.
}
