import 'dart:async';
import '../constants.dart';

/// Modelo de Orden de Producción
class OrdenProduccion {
  final String id;
  final String lote;
  final String producto;
  final String etapaActual; // corte, costura, estampado, acabado, empaque
  final int progreso; // 0-100
  final Duration tiempoEstimado; // tiempo estimado restante o total
  final DateTime fechaInicio;

  OrdenProduccion({
    required this.id,
    required this.lote,
    required this.producto,
    required this.etapaActual,
    required this.progreso,
    required this.tiempoEstimado,
    required this.fechaInicio,
  });
}

/// Servicio para obtener órdenes de producción.
/// En modo mock (debugUseMockApi=true) devuelve datos de ejemplo.
class OrdenesService {
  Future<List<OrdenProduccion>> getOrdenes() async {
    if (debugUseMockApi) {
      await Future.delayed(const Duration(milliseconds: 250));
      return [
        OrdenProduccion(
          id: 'OP-001',
          lote: 'L-202510-A',
          producto: 'Polera básica algodón',
          etapaActual: 'corte',
          progreso: 25,
          tiempoEstimado: const Duration(hours: 5, minutes: 30),
          fechaInicio: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        OrdenProduccion(
          id: 'OP-002',
          lote: 'L-202510-B',
          producto: 'Pantalón jean clásico',
          etapaActual: 'costura',
          progreso: 60,
          tiempoEstimado: const Duration(hours: 3),
          fechaInicio: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        OrdenProduccion(
          id: 'OP-003',
          lote: 'L-202510-C',
          producto: 'Polera estampada edición',
          etapaActual: 'estampado',
          progreso: 40,
          tiempoEstimado: const Duration(hours: 4, minutes: 15),
          fechaInicio: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        OrdenProduccion(
          id: 'OP-004',
          lote: 'L-202510-D',
          producto: 'Camisa lino premium',
          etapaActual: 'acabado',
          progreso: 85,
          tiempoEstimado: const Duration(hours: 1, minutes: 10),
          fechaInicio: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        OrdenProduccion(
          id: 'OP-005',
          lote: 'L-202510-E',
          producto: 'Pack medias deportivas',
          etapaActual: 'empaque',
          progreso: 95,
          tiempoEstimado: const Duration(minutes: 30),
          fechaInicio: DateTime.now().subtract(const Duration(hours: 10)),
        ),
      ];
    }

    // TODO: Implementar llamada HTTP cuando el backend esté listo
    // final url = Uri.parse('$baseUrl/api/ordenes');
    // final resp = await http.get(url);
    // ...
    return [];
  }
}
