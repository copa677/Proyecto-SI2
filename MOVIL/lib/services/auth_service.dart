import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class AuthService {
  static String? _token; // Token compartido en memoria temporal

  // Login
  Future<bool> login(String username, String password) async {
    if (debugUseMockApi) {
      // Mock: solo acepta usuario "demo" y contraseña "demo".
      await Future.delayed(const Duration(milliseconds: 300));
      return username == 'demo' && password == 'demo';
    }
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
      try {
        final body = jsonDecode(response.body);
        final token = body['token'] as String?;
        if (token != null && token.isNotEmpty) {
          _token = token; // Guardar en memoria compartida
          return true;
        }
      } catch (_) {}
      return false;
    } else {
      print('Error de login: ${response.statusCode}');
      return false;
    }
  }

  String? get token => _token;

  Future<void> logout() async {
    if (debugUseMockApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      _token = null;
      return;
    }
    final url = Uri.parse('$baseUrl/api/usuario/logout/');
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (_token != null && _token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ' + _token!;
      }
      final resp = await http.post(url, headers: headers);
      print('Logout respuesta: ${resp.statusCode} - ${resp.body}');
    } catch (e) {
      print('Error en logout: $e');
    } finally {
      _token = null; // limpiar siempre lado cliente
    }
  }

  // Registro
  Future<bool> register(
    String username,
    String password,
    String email,
    String tipoUsuario,
  ) async {
    if (debugUseMockApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      return true; // Simula registro exitoso
    }
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
