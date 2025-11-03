import 'dart:async';
import '../constants.dart';

class ProductoPedido {
  final String nombre;
  final int cantidad;
  final String unidad; // kg, metros, unidades, etc.

  ProductoPedido({
    required this.nombre,
    required this.cantidad,
    required this.unidad,
  });
}

class PedidoInterno {
  final String id;
  final String solicitante;
  final String area;
  final List<ProductoPedido> productos;
  final String estado; // pendiente, en proceso, entregado
  final DateTime fechaSolicitud;
  final DateTime? fechaEntrega;

  PedidoInterno({
    required this.id,
    required this.solicitante,
    required this.area,
    required this.productos,
    required this.estado,
    required this.fechaSolicitud,
    this.fechaEntrega,
  });
}

/// Servicio para gestionar pedidos internos de materiales o productos.
/// En modo mock (debugUseMockApi=true) devuelve datos de ejemplo.
class PedidosService {
  Future<List<PedidoInterno>> getPedidos() async {
    if (debugUseMockApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        PedidoInterno(
          id: 'PI-001',
          solicitante: 'Carlos Mendoza',
          area: 'Corte',
          productos: [
            ProductoPedido(
              nombre: 'Tela algodón azul',
              cantidad: 50,
              unidad: 'metros',
            ),
            ProductoPedido(
              nombre: 'Hilo blanco',
              cantidad: 10,
              unidad: 'rollos',
            ),
          ],
          estado: 'pendiente',
          fechaSolicitud: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        PedidoInterno(
          id: 'PI-002',
          solicitante: 'María Sánchez',
          area: 'Costura',
          productos: [
            ProductoPedido(
              nombre: 'Botones plásticos',
              cantidad: 200,
              unidad: 'unidades',
            ),
            ProductoPedido(
              nombre: 'Cremalleras 20cm',
              cantidad: 30,
              unidad: 'unidades',
            ),
          ],
          estado: 'en proceso',
          fechaSolicitud: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        PedidoInterno(
          id: 'PI-003',
          solicitante: 'Luis Torres',
          area: 'Empaque',
          productos: [
            ProductoPedido(
              nombre: 'Cajas de cartón medianas',
              cantidad: 100,
              unidad: 'unidades',
            ),
            ProductoPedido(
              nombre: 'Etiquetas adhesivas',
              cantidad: 500,
              unidad: 'unidades',
            ),
          ],
          estado: 'entregado',
          fechaSolicitud: DateTime.now().subtract(const Duration(days: 1)),
          fechaEntrega: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        PedidoInterno(
          id: 'PI-004',
          solicitante: 'Ana García',
          area: 'Estampado',
          productos: [
            ProductoPedido(
              nombre: 'Tinta textil negra',
              cantidad: 5,
              unidad: 'litros',
            ),
            ProductoPedido(
              nombre: 'Plantillas vinilo',
              cantidad: 15,
              unidad: 'unidades',
            ),
          ],
          estado: 'pendiente',
          fechaSolicitud: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        PedidoInterno(
          id: 'PI-005',
          solicitante: 'Roberto Silva',
          area: 'Acabado',
          productos: [
            ProductoPedido(
              nombre: 'Planchas de vapor',
              cantidad: 2,
              unidad: 'unidades',
            ),
            ProductoPedido(
              nombre: 'Spray antiestático',
              cantidad: 8,
              unidad: 'frascos',
            ),
          ],
          estado: 'en proceso',
          fechaSolicitud: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ];
    }

    // TODO: Implementar llamada HTTP cuando el backend esté listo
    // final url = Uri.parse('$baseUrl/api/pedidos-internos');
    // final resp = await http.get(url);
    // ...
    return [];
  }

  Future<bool> actualizarEstado(String pedidoId, String nuevoEstado) async {
    if (debugUseMockApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      return true; // Simula actualización exitosa
    }

    // TODO: Implementar llamada HTTP para actualizar estado
    // final url = Uri.parse('$baseUrl/api/pedidos-internos/$pedidoId/estado');
    // final resp = await http.put(url, body: {'estado': nuevoEstado});
    // return resp.statusCode == 200;
    return false;
  }
}
