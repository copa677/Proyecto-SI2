import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'auth_service.dart';

/// Modelo de Trazabilidad basado en el backend
class Trazabilidad {
  final int idTrazabilidad;
  final String proceso;
  final String descripcionProceso;
  final DateTime fechaRegistro;
  final String horaInicio;
  final String horaFin;
  final int cantidad;
  final String estado;
  final int idPersonal;
  final int idOrden;
  final String? nombrePersonal;
  final String? rolPersonal;

  Trazabilidad({
    required this.idTrazabilidad,
    required this.proceso,
    required this.descripcionProceso,
    required this.fechaRegistro,
    required this.horaInicio,
    required this.horaFin,
    required this.cantidad,
    required this.estado,
    required this.idPersonal,
    required this.idOrden,
    this.nombrePersonal,
    this.rolPersonal,
  });

  factory Trazabilidad.fromJson(Map<String, dynamic> json) {
    return Trazabilidad(
      idTrazabilidad: json['id_trazabilidad'] as int,
      proceso: json['proceso'] as String,
      descripcionProceso: json['descripcion_proceso'] as String,
      fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
      horaInicio: json['hora_inicio'] as String,
      horaFin: json['hora_fin'] as String,
      cantidad: json['cantidad'] as int,
      estado: json['estado'] as String,
      idPersonal: json['id_personal'] as int,
      idOrden: json['id_orden'] as int,
      nombrePersonal: json['nombre_personal'] as String?,
      rolPersonal: json['rol_personal'] as String?,
    );
  }
}

/// Modelo para las etapas de producción
class EtapaProduccion {
  final String nombre;
  final String descripcion;
  final int orden;
  final String estado; // pendiente, en_proceso, completado
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? operario;
  final int? cantidad;

  EtapaProduccion({
    required this.nombre,
    required this.descripcion,
    required this.orden,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    this.operario,
    this.cantidad,
  });

  bool get estaPendiente => estado == 'pendiente';
  bool get estaEnProceso => estado == 'en_proceso';
  bool get estaCompletada => estado == 'completado';
}

/// Servicio para gestionar trazabilidad
class TrazabilidadService {
  static const List<String> etapasProduccion = [
    'Corte',
    'Costura',
    'Estampado',
    'Acabado',
    'Empaque',
  ];

  /// Obtener todas las trazabilidades (con filtro opcional por orden)
  Future<List<Trazabilidad>> getTrazabilidades({int? idOrden}) async {
    try {
      final token = AuthService().token;
      if (token == null || token.isEmpty) {
        throw Exception('No hay token de sesión');
      }

      final url = Uri.parse('$baseUrl/api/trazabilidad/trazabilidades/');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        List<Trazabilidad> trazas = jsonList
            .map((json) => Trazabilidad.fromJson(json))
            .toList();

        // Filtrar por orden si se especifica
        if (idOrden != null) {
          trazas = trazas.where((t) => t.idOrden == idOrden).toList();
        }

        return trazas;
      } else if (response.statusCode == 401) {
        throw Exception('Token expirado o inválido');
      } else {
        throw Exception(
          'Error al cargar trazabilidades: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Registrar nueva trazabilidad (iniciar o finalizar etapa)
  Future<void> registrarTrazabilidad({
    required String proceso,
    required String descripcionProceso,
    required DateTime fechaRegistro,
    required String horaInicio,
    required String horaFin,
    required int cantidad,
    required String estado,
    required String nombrePersonal,
    required int idOrden,
  }) async {
    try {
      final token = AuthService().token;
      if (token == null || token.isEmpty) {
        throw Exception('No hay token de sesión');
      }

      final url = Uri.parse(
        '$baseUrl/api/trazabilidad/trazabilidades/insertar/',
      );
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'id_trazabilidad': 0, // Se genera automáticamente
        'proceso': proceso,
        'descripcion_proceso': descripcionProceso,
        'fecha_registro': fechaRegistro.toIso8601String().split('T')[0],
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'cantidad': cantidad,
        'estado': estado,
        'nombre_personal': nombrePersonal,
        'id_orden': idOrden,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        // Éxito
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Token expirado o inválido');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ?? 'Error al registrar trazabilidad',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Generar lista de etapas de producción basada en trazabilidades existentes
  List<EtapaProduccion> generarEtapasProduccion(List<Trazabilidad> trazas) {
    List<EtapaProduccion> etapas = [];

    for (int i = 0; i < etapasProduccion.length; i++) {
      final nombreEtapa = etapasProduccion[i];

      // Buscar trazabilidades para esta etapa
      final trazasEtapa = trazas
          .where((t) => t.proceso.toLowerCase() == nombreEtapa.toLowerCase())
          .toList();

      String estado = 'pendiente';
      DateTime? fechaInicio;
      DateTime? fechaFin;
      String? operario;
      int? cantidad;

      if (trazasEtapa.isNotEmpty) {
        // Ordenar por fecha de registro para obtener la más reciente
        trazasEtapa.sort((a, b) => a.fechaRegistro.compareTo(b.fechaRegistro));
        final trazaReciente = trazasEtapa.last;

        if (trazaReciente.estado.toLowerCase() == 'completado') {
          estado = 'completado';
        } else {
          estado = 'en_proceso';
        }

        fechaInicio = trazaReciente.fechaRegistro;
        if (estado == 'completado') {
          fechaFin = trazaReciente.fechaRegistro;
        }
        operario = trazaReciente.nombrePersonal;
        cantidad = trazaReciente.cantidad;
      } else {
        // Si no hay trazas para esta etapa, verificar si la anterior está completada
        if (i > 0) {
          final etapaAnterior = etapas[i - 1];
          if (!etapaAnterior.estaCompletada) {
            estado = 'pendiente';
          }
        }
      }

      etapas.add(
        EtapaProduccion(
          nombre: nombreEtapa,
          descripcion: _getDescripcionEtapa(nombreEtapa),
          orden: i,
          estado: estado,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          operario: operario,
          cantidad: cantidad,
        ),
      );
    }

    return etapas;
  }

  /// Calcular progreso real basado en etapas completadas
  int calcularProgresoReal(List<EtapaProduccion> etapas, int cantidadTotal) {
    if (etapas.isEmpty) return 0;

    // Contar etapas completadas
    int etapasCompletadas = etapas.where((e) => e.estaCompletada).length;

    // Progreso = (etapas completadas / total etapas) * 100
    return ((etapasCompletadas / etapas.length) * 100).round();
  }

  /// Obtener la etapa actual (la primera que no está completada)
  String? getEtapaActual(List<EtapaProduccion> etapas) {
    for (final etapa in etapas) {
      if (!etapa.estaCompletada) {
        return etapa.nombre;
      }
    }
    return etapas.isNotEmpty && etapas.last.estaCompletada
        ? 'Completado'
        : null;
  }

  String _getDescripcionEtapa(String nombre) {
    switch (nombre.toLowerCase()) {
      case 'corte':
        return 'Corte de piezas y preparación de materiales';
      case 'costura':
        return 'Ensamblaje y costura de las piezas';
      case 'estampado':
        return 'Aplicación de diseños y estampados';
      case 'acabado':
        return 'Terminaciones y control de calidad';
      case 'empaque':
        return 'Empaquetado y preparación para envío';
      default:
        return 'Etapa de producción';
    }
  }

  /// Formatear tiempo para el backend (HH:mm:ss)
  String formatearHora(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}
