import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class AuthService {
  // Login
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/usuario/login');

    final datos = {
      'name_user': username, // ← Cambiado de "username" a "name_user"
      'password': password,
    };

    print('Enviando datos de login: $datos');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );

    print('Respuesta del servidor login: ${response.statusCode}');
    print('Cuerpo de la respuesta login: ${response.body}');

    if (response.statusCode == 200) {
      print('Login exitoso: ${response.body}');
      // Aquí puedes guardar el token si lo necesitas
      return true;
    } else {
      print('Error de login: ${response.statusCode}');
      return false;
    }
  }

  // Registro
  Future<bool> register(
    String username,
    String password,
    String email,
    String tipoUsuario,
  ) async {
    final url = Uri.parse('$baseUrl/api/usuario/register');

    // Datos que vamos a enviar
    final datos = {
      'name_user': username, // ← Cambiado de "username" a "name_user"
      'password': password,
      'email': email,
      'tipo_usuario': tipoUsuario, // ← Agregado
      'estado': 'Activo', // ← Agregado
    };

    print('Enviando datos: $datos'); // <-- Agrega esta línea

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(datos),
    );

    print('Respuesta del servidor: ${response.statusCode}');
    print('Cuerpo de la respuesta: ${response.body}'); // <-- Agrega esta línea

    if (response.statusCode == 201) {
      print('Registro exitoso: ${response.body}');
      return true;
    } else {
      print('Error de registro: ${response.statusCode}');
      return false;
    }
  }
}
