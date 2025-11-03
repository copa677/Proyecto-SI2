import 'package:flutter/material.dart';
import '../services/ordenes_service.dart';
import '../services/trazabilidad_service.dart';
import '../theme/app_colors.dart';
import '../widgets/filtros_ordenes.dart';
import '../widgets/orden_produccion_card.dart';
import 'trazabilidad_page.dart';

class OrdenesProduccionPage extends StatefulWidget {
  const OrdenesProduccionPage({Key? key}) : super(key: key);

  @override
  State<OrdenesProduccionPage> createState() => _OrdenesProduccionPageState();
}

class _OrdenesProduccionPageState extends State<OrdenesProduccionPage> {
  final OrdenesService _service = OrdenesService();
  final TrazabilidadService _trazabilidadService = TrazabilidadService();
  late Future<List<OrdenProduccion>> _future;
  final Map<int, int> _progresosReales = {};
  OrdenFiltroCampo _campo =
      OrdenFiltroCampo.todos; // campo: todos/lote/producto
  String _query = '';
  String? _etapa; // null=todas

  @override
  void initState() {
    super.initState();
    _future = _service.getOrdenes();
  }

  String _fmtFecha(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Future<int> _calcularProgresoReal(OrdenProduccion orden) async {
    try {
      // Obtener trazabilidades de esta orden
      final trazabilidades = await _trazabilidadService.getTrazabilidades(
        idOrden: orden.idOrden,
      );

      // Generar etapas de producción basadas en las trazabilidades
      final etapas = _trazabilidadService.generarEtapasProduccion(
        trazabilidades,
      );

      // Calcular progreso real
      final progresoReal = _trazabilidadService.calcularProgresoReal(
        etapas,
        orden.cantidadTotal,
      );

      return progresoReal;
    } catch (e) {
      // En caso de error, devolver el progreso estimado como fallback
      print('Error al calcular progreso real: $e');
      return orden.progresoEstimado;
    }
  }

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'planificada':
        return const Color(0xFF1570EF); // Azul
      case 'en proceso':
        return const Color(0xFFF79009); // Naranja
      case 'completado':
        return const Color(0xFF12B76A); // Verde
      case 'cancelado':
        return const Color(0xFFF04438); // Rojo
      default:
        return AppColors.grisTextoSecundario;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: Column(
        children: [
          // Título estilo Configuración
          const Padding(
            padding: EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Órdenes de Producción',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.negroTexto,
                ),
              ),
            ),
          ),
          // Filtros avanzados
          FiltroOrdenesBar(
            campo: _campo,
            onCampoChange: (c) => setState(() => _campo = c),
            query: _query,
            onQueryChange: (v) =>
                setState(() => _query = v.trim().toLowerCase()),
            etapa: _etapa,
            onEtapaChange: (e) => setState(() => _etapa = e),
          ),
          Expanded(
            child: FutureBuilder<List<OrdenProduccion>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final data = snap.data ?? [];

                // Filtrado compuesto (sin rango de fechas por ahora)
                final filtered = data.where((op) {
                  // Estado (usando _etapa como filtro de estado por ahora)
                  if (_etapa != null &&
                      op.estado.toLowerCase() != _etapa!.toLowerCase())
                    return false;

                  // Texto
                  if (_query.isEmpty) return true;
                  switch (_campo) {
                    case OrdenFiltroCampo.lote:
                      return op.codOrden.toLowerCase().contains(_query);
                    case OrdenFiltroCampo.producto:
                      return op.productoCompleto.toLowerCase().contains(_query);
                    case OrdenFiltroCampo.todos:
                      return op.codOrden.toLowerCase().contains(_query) ||
                          op.productoCompleto.toLowerCase().contains(_query);
                  }
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Sin resultados'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final op = filtered[index];

                    return OrdenProduccionCard(
                      codigo: op.codOrden,
                      producto: op.productoCompleto,
                      lote: 'Cantidad: ${op.cantidadTotal}',
                      estado: op.estado,
                      etapa: op.estado, // Usamos estado como etapa por ahora
                      // progreso: op.progresoEstimado, // Removido - solo se mostrará en detalles
                      fechaInicio: op.fechaInicio,
                      fechaEntregaEstimada: op.fechaEntrega,
                      onVerDetalles: () {
                        _mostrarDetallesOrden(context, op);
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: filtered.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesOrden(BuildContext context, OrdenProduccion op) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalle de Orden',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _rowDetalle('Código de Orden', op.codOrden),
                  _rowDetalle('Producto', op.productoModelo),
                  _rowDetalle('Color', op.color),
                  _rowDetalle('Talla', op.talla),
                  _rowDetalle('Cantidad total', '${op.cantidadTotal}'),
                  const SizedBox(height: 16),

                  // Estado con color
                  Row(
                    children: [
                      const Text(
                        'Estado: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _estadoColor(op.estado).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _estadoColor(op.estado).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          op.estado,
                          style: TextStyle(
                            color: _estadoColor(op.estado),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Progreso real',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<int>(
                    future: _calcularProgresoReal(op),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: op.progresoEstimado / 100.0,
                                  minHeight: 10,
                                  backgroundColor: AppColors.grisMuyClaro,
                                  color: _estadoColor(
                                    op.estado,
                                  ).withOpacity(0.5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _estadoColor(op.estado),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Calculando...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _estadoColor(op.estado),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      final progresoReal = snapshot.data ?? op.progresoEstimado;
                      final esProgresoReal = snapshot.hasData;

                      return Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progresoReal / 100.0,
                                minHeight: 10,
                                backgroundColor: AppColors.grisMuyClaro,
                                color: _estadoColor(op.estado),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              Text(
                                '${progresoReal}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (esProgresoReal) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: AppColors.verdePrincipal,
                                ),
                              ],
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Fechas',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _rowDetalle('Inicio', _fmtFecha(op.fechaInicio)),
                  _rowDetalle('Fin planificado', _fmtFecha(op.fechaFin)),
                  _rowDetalle(
                    'Entrega planificada',
                    _fmtFecha(op.fechaEntrega),
                  ),
                  const SizedBox(height: 16),
                  // Botón Ver trazabilidad
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azulPrincipal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrazabilidadPage(orden: op),
                          ),
                        );
                      },
                      icon: const Icon(Icons.timeline_rounded, size: 18),
                      label: const Text(
                        'Ver trazabilidad',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _rowDetalle(String campo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              campo,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}
