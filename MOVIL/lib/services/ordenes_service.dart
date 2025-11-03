import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'auth_service.dart';

/// Modelo de Orden de Producción basado en el backend
class OrdenProduccion {
  final int idOrden;
  final String codOrden;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final DateTime fechaEntrega;
  final String estado;
  final String productoModelo;
  final String color;
  final String talla;
  final int cantidadTotal;
  final int idPersonal;

  OrdenProduccion({
    required this.idOrden,
    required this.codOrden,
    required this.fechaInicio,
    required this.fechaFin,
    required this.fechaEntrega,
    required this.estado,
    required this.productoModelo,
    required this.color,
    required this.talla,
    required this.cantidadTotal,
    required this.idPersonal,
  });

  factory OrdenProduccion.fromJson(Map<String, dynamic> json) {
    return OrdenProduccion(
      idOrden: json['id_orden'] as int,
      codOrden: json['cod_orden'] as String,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: DateTime.parse(json['fecha_fin'] as String),
      fechaEntrega: DateTime.parse(json['fecha_entrega'] as String),
      estado: json['estado'] as String,
      productoModelo: json['producto_modelo'] as String,
      color: json['color'] as String,
      talla: json['talla'] as String,
      cantidadTotal: json['cantidad_total'] as int,
      idPersonal: json['id_personal'] as int,
    );
  }

  // Helpers para la UI
  String get productoCompleto => '$productoModelo - $color ($talla)';

  int get progresoEstimado {
    final now = DateTime.now();
    final total = fechaFin.difference(fechaInicio).inDays;
    final transcurrido = now.difference(fechaInicio).inDays;
    if (total <= 0) return 100;
    final progreso = ((transcurrido / total) * 100).clamp(0, 100).round();
    return estado.toLowerCase() == 'completado' ? 100 : progreso;
  }

  String get estadoColor {
    switch (estado.toLowerCase()) {
      case 'planificada':
        return 'azul';
      case 'en proceso':
        return 'naranja';
      case 'completado':
        return 'verde';
      case 'cancelado':
        return 'rojo';
      default:
        return 'gris';
    }
  }
}

/// Servicio para obtener órdenes de producción
class OrdenesService {
  Future<List<OrdenProduccion>> getOrdenes() async {
    if (debugUseMockApi) {
      await Future.delayed(const Duration(milliseconds: 250));
      final now = DateTime.now();
      return [
        OrdenProduccion(
          idOrden: 1,
          codOrden: 'OP-2025-001',
          fechaInicio: now.subtract(const Duration(days: 5)),
          fechaFin: now.add(const Duration(days: 10)),
          fechaEntrega: now.add(const Duration(days: 12)),
          estado: 'En Proceso',
          productoModelo: 'Polera Básica Algodón',
          color: 'Azul',
          talla: 'M',
          cantidadTotal: 150,
          idPersonal: 1,
        ),
        OrdenProduccion(
          idOrden: 2,
          codOrden: 'OP-2025-002',
          fechaInicio: now.subtract(const Duration(days: 3)),
          fechaFin: now.add(const Duration(days: 7)),
          fechaEntrega: now.add(const Duration(days: 9)),
          estado: 'Planificada',
          productoModelo: 'Pantalón Jean Clásico',
          color: 'Negro',
          talla: 'L',
          cantidadTotal: 80,
          idPersonal: 2,
        ),
        OrdenProduccion(
          idOrden: 3,
          codOrden: 'OP-2025-003',
          fechaInicio: now.subtract(const Duration(days: 15)),
          fechaFin: now.subtract(const Duration(days: 2)),
          fechaEntrega: now.subtract(const Duration(days: 1)),
          estado: 'Completado',
          productoModelo: 'Polera Estampada Edición',
          color: 'Blanco',
          talla: 'S',
          cantidadTotal: 200,
          idPersonal: 1,
        ),
        OrdenProduccion(
          idOrden: 4,
          codOrden: 'OP-2025-004',
          fechaInicio: now.subtract(const Duration(days: 8)),
          fechaFin: now.add(const Duration(days: 5)),
          fechaEntrega: now.add(const Duration(days: 7)),
          estado: 'En Proceso',
          productoModelo: 'Camisa Lino Premium',
          color: 'Beige',
          talla: 'XL',
          cantidadTotal: 60,
          idPersonal: 3,
        ),
        OrdenProduccion(
          idOrden: 5,
          codOrden: 'OP-2025-005',
          fechaInicio: now.add(const Duration(days: 2)),
          fechaFin: now.add(const Duration(days: 14)),
          fechaEntrega: now.add(const Duration(days: 16)),
          estado: 'Planificada',
          productoModelo: 'Pack Medias Deportivas',
          color: 'Multicolor',
          talla: 'Único',
          cantidadTotal: 300,
          idPersonal: 2,
        ),
      ];
    }

    // Backend real
    try {
      final token = AuthService().token;
      if (token == null || token.isEmpty) {
        throw Exception('No hay token de sesión');
      }

      final url = Uri.parse('$baseUrl/api/ordenproduccion/ordenes/');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => OrdenProduccion.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Token expirado o inválido');
      } else {
        throw Exception('Error al cargar órdenes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<OrdenProduccion> getOrdenById(int idOrden) async {
    if (debugUseMockApi) {
      final ordenes = await getOrdenes();
      return ordenes.firstWhere((orden) => orden.idOrden == idOrden);
    }

    try {
      final token = AuthService().token;
      if (token == null || token.isEmpty) {
        throw Exception('No hay token de sesión');
      }

      final url = Uri.parse('$baseUrl/api/ordenproduccion/ordenes/$idOrden/');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return OrdenProduccion.fromJson(json);
      } else if (response.statusCode == 404) {
        throw Exception('Orden no encontrada');
      } else {
        throw Exception('Error al cargar orden: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
