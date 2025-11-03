import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'auth_service.dart';

class PerfilUsuario {
  final String nombre;
  final String rol;
  final String area;
  final String email;
  final String estado;
  final String telefono;
  final String direccion;
  final String fechaNacimiento;

  PerfilUsuario({
    required this.nombre,
    required this.rol,
    required this.area,
    required this.email,
    required this.estado,
    required this.telefono,
    required this.direccion,
    required this.fechaNacimiento,
  });
}

class PerfilService {
  Future<PerfilUsuario> getPerfil() async {
    if (debugUseMockApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      return PerfilUsuario(
        nombre: 'Demo User',
        rol: 'Supervisor',
        area: 'Producción',
        email: 'demo@example.com',
        estado: 'Activo',
        telefono: '70000000',
        direccion: 'Calle Falsa 123',
        fechaNacimiento: '1990-01-01',
      );
    }
    // Backend real: decodificar JWT para obtener id y username,
    // luego pedir datos del empleado para enriquecer nombre/área.
    try {
      final token = AuthService().token;
      if (token == null || token.isEmpty) {
        throw Exception('No hay token de sesión');
      }

      // 1) Decodificar payload del JWT sin dependencias adicionales
      final payload = _decodeJwtPayload(token);
      final userId = payload['id'] as int?;
      final username = (payload['name_user'] ?? '') as String;
      final tipoUsuario = (payload['tipo_usuario'] ?? '') as String;

      String nombre = username;
      String area = 'N/A';
      String email = '';
      String estado = '';
      String telefono = '';
      String direccion = '';
      String fechaNacimiento = '';

      // 2) Intentar obtener datos de empleado por id de usuario
      if (userId != null) {
        final url = Uri.parse('$baseUrl/api/personal/getEmpleadoID/$userId');
        final headers = <String, String>{'Content-Type': 'application/json'};
        // El endpoint no exige auth, pero si tenemos token lo enviamos
        headers['Authorization'] = 'Bearer $token';

        final resp = await http.get(url, headers: headers);
        if (resp.statusCode == 200 && resp.body.isNotEmpty) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final nombreCompleto = (data['nombre_completo'] ?? '') as String;
          final rolEmpleado = (data['rol'] ?? '') as String;
          telefono = (data['telefono'] ?? '') as String? ?? '';
          direccion = (data['direccion'] ?? '') as String? ?? '';
          fechaNacimiento = (data['fecha_nacimiento'] ?? '') as String? ?? '';
          if (nombreCompleto.isNotEmpty) nombre = nombreCompleto;
          if (rolEmpleado.isNotEmpty)
            area = rolEmpleado; // En el back usan rol como área
        }

        // 3) Obtener datos del usuario (email, estado)
        final urlUser = Uri.parse('$baseUrl/api/usuario/getUser/$userId');
        final respUser = await http.get(urlUser, headers: headers);
        if (respUser.statusCode == 200 && respUser.body.isNotEmpty) {
          final dataUser = jsonDecode(respUser.body) as Map<String, dynamic>;
          email = (dataUser['email'] ?? '') as String? ?? '';
          estado = (dataUser['estado'] ?? '') as String? ?? '';
        }
      }

      return PerfilUsuario(
        nombre: nombre,
        rol: tipoUsuario,
        area: area,
        email: email,
        estado: estado,
        telefono: telefono,
        direccion: direccion,
        fechaNacimiento: fechaNacimiento,
      );
    } catch (e) {
      // En caso de error, devolvemos los mínimos posibles
      try {
        final token = AuthService().token;
        final payload = token != null
            ? _decodeJwtPayload(token)
            : <String, dynamic>{};
        return PerfilUsuario(
          nombre: (payload['name_user'] ?? '') as String,
          rol: (payload['tipo_usuario'] ?? '') as String,
          area: 'N/A',
          email: '',
          estado: '',
          telefono: '',
          direccion: '',
          fechaNacimiento: '',
        );
      } catch (_) {
        return PerfilUsuario(
          nombre: '',
          rol: '',
          area: 'N/A',
          email: '',
          estado: '',
          telefono: '',
          direccion: '',
          fechaNacimiento: '',
        );
      }
    }
  }
}

Map<String, dynamic> _decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('Token JWT inválido');
  }
  final payload = parts[1];
  // Ajustar padding de base64url si es necesario
  String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
  while (normalized.length % 4 != 0) {
    normalized += '=';
  }
  final payloadBytes = base64Decode(normalized);
  final payloadMap = jsonDecode(utf8.decode(payloadBytes));
  if (payloadMap is! Map<String, dynamic>) {
    throw Exception('Payload de JWT no es un mapa');
  }
  return payloadMap;
}
