import 'dart:async';
import '../constants.dart';

class Incidencia {
  final String ordenId;
  final String lote;
  final String producto;
  final String etapa;
  final String tipoDefecto;
  final String descripcion;
  final String severidad; // Baja/Media/Alta
  final String responsable;
  final DateTime fechaHora;
  final String? imagenPath; // ruta local de imagen seleccionada (mock)

  Incidencia({
    required this.ordenId,
    required this.lote,
    required this.producto,
    required this.etapa,
    required this.tipoDefecto,
    required this.descripcion,
    required this.severidad,
    required this.responsable,
    required this.fechaHora,
    this.imagenPath,
  });
}

class IncidenciasService {
  Future<bool> registrarIncidencia(Incidencia inc) async {
    if (debugUseMockApi) {
      // Simula latencia y éxito
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    }

    // TODO: Implementar llamada HTTP real al backend cuando esté disponible.
    // Por ahora retornamos false para indicar no implementado.
    return false;
  }
}
