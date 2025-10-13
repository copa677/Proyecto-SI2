import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

/// Servicio para interactuar con el backend relativo a usuarios.
///
/// Proporciona métodos para obtener la lista de usuarios, registrar
/// un nuevo usuario y actualizar la información de un usuario asociado
/// a un empleado. La URL base se toma de [baseUrl] definida en
/// `constants.dart`.
class UserService {
  /// Recupera todos los usuarios del sistema.
  ///
  /// Hace un GET a `/api/usuario/getuser` y devuelve la lista de
  /// usuarios como una colección de mapas. Si la respuesta tiene
  /// código distinto de 200 lanzará una excepción.
  Future<List<dynamic>> getUsuarios() async {
    if (debugUseMockApi) {
      await Future.delayed(const Duration(milliseconds: 250));
      return [
        {
          'id': 1,
          'name_user': 'admin',
          'email': 'admin@demo.com',
          'estado': 'activo',
          'tipo_usuario': 'Administrador',
        },
        {
          'id': 2,
          'name_user': 'supervisor',
          'email': 'supervisor@demo.com',
          'estado': 'activo',
          'tipo_usuario': 'Supervisor',
        },
        {
          'id': 3,
          'name_user': 'operario1',
          'email': 'operario1@demo.com',
          'estado': 'inactivo',
          'tipo_usuario': 'Operario',
        },
      ];
    }
    final url = Uri.parse('$baseUrl/api/usuario/getuser');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error al obtener usuarios: ${response.statusCode}');
    }
  }

  /// Registra un nuevo usuario en el sistema.
  ///
  /// Envia un POST a `/api/usuario/register` con los campos:
  /// - `name_user`: nombre de usuario
  /// - `password`: contraseña del usuario
  /// - `email`: dirección de correo
  /// - `tipo_usuario`: tipo de usuario (Operario, Supervisor, Administrador)
  /// - `estado`: estado del usuario (Activo o Inactivo)
  ///
  /// Retorna `true` si la respuesta tiene status 201, `false` en
  /// cualquier otro caso. Para saber el motivo del fallo consulta
  /// `response.body` cuando el resultado sea `false`.
  Future<bool> registerUsuario(Map<String, dynamic> datos) async {
    if (debugUseMockApi) {
      await Future.delayed(const Duration(milliseconds: 250));
      return true;
    }
    final url = Uri.parse('$baseUrl/api/usuario/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );

    if (response.statusCode == 201) {
      return true;
    }
    return false;
  }

  /// Actualiza los datos de un usuario asociado a un empleado.
  ///
  /// Este método envía un POST a `/api/usuario/actualizarEmpleadoUsuario` con
  /// los campos esperados por el backend:
  /// - `id_usuario`: id del usuario a actualizar
  /// - `nombre_completo`: nombre completo del empleado
  /// - `email`: correo electrónico del usuario
  /// - `telefono`: número de teléfono
  /// - `direccion`: dirección
  /// - `fecha_nacimiento`: fecha en formato YYYY-MM-DD
  ///
  /// Retorna `true` si el servidor responde con código 200. Si
  /// devuelve otro código se retorna `false` y el detalle del error
  /// puede obtenerse en `response.body`.
  Future<bool> actualizarEmpleadoUsuario(Map<String, dynamic> datos) async {
    if (debugUseMockApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    }
    final url = Uri.parse('$baseUrl/api/usuario/actualizarEmpleadoUsuario');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );

    return response.statusCode == 200;
  }

  /// Elimina un usuario y su asociado personal.
  ///
  /// El backend actual no expone un endpoint exclusivo para borrar un
  /// usuario. Para eliminar un usuario se debe llamar al endpoint
  /// `/api/personal/eliminar` pasando el `id_usuario` en el cuerpo de la
  /// petición. Puedes implementar ese método aquí si tu interfaz de
  /// Usuarios permite eliminar usuarios.
  ///
  /// Future<bool> eliminarUsuario(int idUsuario) async {
  ///   final url = Uri.parse('$baseUrl/api/personal/eliminar');
  ///   final response = await http.post(
  ///     url,
  ///     headers: {'Content-Type': 'application/json'},
  ///     body: jsonEncode({'id_usuario': idUsuario}),
  ///   );
  ///   return response.statusCode == 200;
  /// }
}
