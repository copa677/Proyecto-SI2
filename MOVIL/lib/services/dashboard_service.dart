// lib/services/dashboard_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

/// Servicio encargado de obtener estadísticas para el dashboard.
///
/// Usa las rutas reales del backend:
/// - Total de personal:  GET  $baseUrl/api/personal/getEmpleados
/// - Total de usuarios:  GET  $baseUrl/api/usuario/getuser
/// - Asistencia de hoy:  (no existe aún un endpoint, se devuelve un placeholder)
class DashboardService {
  /// Devuelve la cantidad total de empleados registrados.
  Future<int> getTotalPersonal() async {
    final url = Uri.parse('$baseUrl/api/personal/getEmpleados');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> empleados =
          jsonDecode(response.body) as List<dynamic>;
      return empleados.length;
    } else {
      throw Exception(
        'Error al obtener el total de personal (código ${response.statusCode})',
      );
    }
  }

  /// Devuelve la cantidad total de usuarios registrados.
  Future<int> getTotalUsuarios() async {
    final url = Uri.parse('$baseUrl/api/usuario/getuser');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> usuarios = jsonDecode(response.body) as List<dynamic>;
      return usuarios.length;
    } else {
      throw Exception(
        'Error al obtener el total de usuarios (código ${response.statusCode})',
      );
    }
  }

  /// Devuelve el texto “Asistencia Hoy” en formato `asistencias/total`.
  ///
  /// Actualmente el backend no tiene un endpoint para asistencias, por lo que
  /// esta función genera un valor de ejemplo (“0/número de personal”). Cuando
  /// implementes el endpoint, puedes modificar este método para contar los
  /// registros de asistencia de hoy.
  Future<String> getAsistenciaHoy() async {
    final totalPersonal = await getTotalPersonal();
    // Placeholder: asume que no hay asistencias registradas.
    final int asistencia = 0;
    return '$asistencia/$totalPersonal';
  }
}
