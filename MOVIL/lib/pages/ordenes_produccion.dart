import 'package:flutter/material.dart';
import '../services/ordenes_service.dart';
import '../theme/app_colors.dart';
import '../widgets/filtros_ordenes.dart';
import '../widgets/orden_produccion_card.dart';
import 'registrar_incidencia.dart';

class OrdenesProduccionPage extends StatefulWidget {
  const OrdenesProduccionPage({Key? key}) : super(key: key);

  @override
  State<OrdenesProduccionPage> createState() => _OrdenesProduccionPageState();
}

class _OrdenesProduccionPageState extends State<OrdenesProduccionPage> {
  final OrdenesService _service = OrdenesService();
  late Future<List<OrdenProduccion>> _future;
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
    // Solo fecha (sin horas) -> yyyy-mm-dd
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Color _stageColor(String etapa) {
    switch (etapa) {
      case 'corte':
        return Colors.blue.shade400;
      case 'costura':
        return Colors.indigo.shade400;
      case 'estampado':
        return Colors.orange.shade600;
      case 'acabado':
        return Colors.teal.shade500;
      case 'empaque':
        return Colors.green.shade600;
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
                  // Etapa
                  if (_etapa != null && op.etapaActual != _etapa) return false;

                  // Texto
                  if (_query.isEmpty) return true;
                  switch (_campo) {
                    case OrdenFiltroCampo.lote:
                      return op.lote.toLowerCase().contains(_query);
                    case OrdenFiltroCampo.producto:
                      return op.producto.toLowerCase().contains(_query);
                    case OrdenFiltroCampo.todos:
                      return op.lote.toLowerCase().contains(_query) ||
                          op.producto.toLowerCase().contains(_query);
                  }
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Sin resultados'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final op = filtered[index];
                    // Derivar estado y fecha estimada de entrega
                    final estFin = op.fechaInicio.add(op.tiempoEstimado);
                    final estado = op.progreso >= 100
                        ? 'Completada'
                        : (DateTime.now().isAfter(estFin)
                              ? 'Retrasada'
                              : 'En proceso');

                    return OrdenProduccionCard(
                      codigo: op.id,
                      producto: op.producto,
                      lote: op.lote,
                      estado: estado,
                      etapa:
                          op.etapaActual[0].toUpperCase() +
                          op.etapaActual.substring(1),
                      progreso: op.progreso,
                      fechaInicio: op.fechaInicio,
                      fechaEntregaEstimada: estFin,
                      onVerDetalles: () {
                        _mostrarDetallesOrden(context, op, estado, estFin);
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

  void _mostrarDetallesOrden(
    BuildContext context,
    OrdenProduccion op,
    String estado,
    DateTime fechaEstimadaFin,
  ) {
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
                  _rowDetalle('Código de Orden', op.id),
                  _rowDetalle('Lote', op.lote),
                  _rowDetalle('Producto', op.producto),
                  _rowDetalle('Cantidad total', '—'),
                  const SizedBox(height: 8),
                  const Text('Progreso general'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: op.progreso / 100.0,
                            minHeight: 8,
                            backgroundColor: AppColors.grisMuyClaro,
                            color: _stageColor(op.etapaActual),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${op.progreso}%'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _rowDetalle('Estado actual', estado),
                  _rowDetalle(
                    'Etapa actual',
                    op.etapaActual[0].toUpperCase() +
                        op.etapaActual.substring(1),
                  ),
                  _rowDetalle('Responsable actual', 'Operario #4'),
                  const SizedBox(height: 8),
                  const Text('Tiempos'),
                  const SizedBox(height: 6),
                  _rowDetalle('Inicio', _fmtFecha(op.fechaInicio)),
                  _rowDetalle('Entrega estimada', _fmtFecha(fechaEstimadaFin)),
                  _rowDetalle('Duración por etapa', '—'),
                  const SizedBox(height: 8),
                  _rowDetalle('Defectos registrados', '0 (ver detalle)'),
                  const SizedBox(height: 16),
                  // Botones de acciones (estilo unificado)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      // Definir un estilo común para todos los botones
                      Builder(
                        builder: (context) {
                          final ButtonStyle actionBtnStyle =
                              ElevatedButton.styleFrom(
                                backgroundColor: AppColors.azulPrincipal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );

                          return Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(
                                style: actionBtnStyle,
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  // TODO: Navegar a flujo "Actualizar etapa"
                                },
                                child: const Text('Actualizar etapa'),
                              ),
                              ElevatedButton(
                                style: actionBtnStyle,
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  // Abre la vista de registro de incidencias a la derecha
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) =>
                                          RegistrarIncidenciaPage(
                                            ordenId: op.id,
                                            lote: op.lote,
                                            producto: op.producto,
                                            etapaActual: op.etapaActual,
                                            responsableActual:
                                                'Operario #4', // TODO: usar usuario autenticado
                                          ),
                                      transitionsBuilder:
                                          (_, animation, __, child) {
                                            // Animación deslizante desde la derecha
                                            const begin = Offset(1.0, 0.0);
                                            const end = Offset.zero;
                                            final tween =
                                                Tween(
                                                  begin: begin,
                                                  end: end,
                                                ).chain(
                                                  CurveTween(
                                                    curve: Curves.easeOutCubic,
                                                  ),
                                                );
                                            return SlideTransition(
                                              position: animation.drive(tween),
                                              child: child,
                                            );
                                          },
                                    ),
                                  );
                                },
                                child: const Text('Registrar incidencia'),
                              ),
                              ElevatedButton(
                                style: actionBtnStyle,
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  // TODO: Ver trazabilidad
                                },
                                child: const Text('Ver trazabilidad'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
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
