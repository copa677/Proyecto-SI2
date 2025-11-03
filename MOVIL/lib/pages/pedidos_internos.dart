import 'package:flutter/material.dart';
import '../services/pedidos_service.dart';
import '../theme/app_colors.dart';

class PedidosInternosPage extends StatefulWidget {
  const PedidosInternosPage({Key? key}) : super(key: key);

  @override
  State<PedidosInternosPage> createState() => _PedidosInternosPageState();
}

class _PedidosInternosPageState extends State<PedidosInternosPage> {
  final PedidosService _service = PedidosService();
  late Future<List<PedidoInterno>> _future;
  String _filtroEstado = 'Todos';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _service.getPedidos();
  }

  void _recargarPedidos() {
    setState(() {
      _future = _service.getPedidos();
    });
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange.shade600;
      case 'en proceso':
        return Colors.blue.shade600;
      case 'entregado':
        return Colors.green.shade600;
      default:
        return AppColors.grisTextoSecundario;
    }
  }

  IconData _estadoIcon(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.schedule;
      case 'en proceso':
        return Icons.autorenew;
      case 'entregado':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _mostrarDetallePedido(PedidoInterno pedido) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pedido ${pedido.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Solicitante: ${pedido.solicitante}'),
              Text('Área: ${pedido.area}'),
              Text('Estado: ${pedido.estado}'),
              const SizedBox(height: 16),
              const Text(
                'Productos solicitados:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...pedido.productos.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• ${p.nombre}: ${p.cantidad} ${p.unidad}'),
                ),
              ),
              const SizedBox(height: 16),
              if (pedido.estado != 'entregado') ...[
                const Text(
                  'Actualizar estado:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (pedido.estado == 'pendiente') ...[
                      ElevatedButton(
                        onPressed: () =>
                            _actualizarEstado(pedido.id, 'en proceso'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Procesar'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (pedido.estado == 'en proceso') ...[
                      ElevatedButton(
                        onPressed: () =>
                            _actualizarEstado(pedido.id, 'entregado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Entregar'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton(
                      onPressed: () =>
                          _actualizarEstado(pedido.id, 'pendiente'),
                      child: const Text('Revertir a Pendiente'),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'Entregado el: ${pedido.fechaEntrega?.hour.toString().padLeft(2, '0')}:${pedido.fechaEntrega?.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: AppColors.grisTextoSecundario),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _actualizarEstado(String pedidoId, String nuevoEstado) async {
    try {
      final exito = await _service.actualizarEstado(pedidoId, nuevoEstado);
      if (!mounted) return;

      Navigator.pop(context); // Cerrar el diálogo

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado actualizado a: $nuevoEstado')),
        );
        _recargarPedidos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar estado')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pedidos Internos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.negroTexto,
                ),
              ),
            ),
          ),
          // Filtros y búsqueda
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _filtroEstado,
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(
                      value: 'pendiente',
                      child: Text('Pendientes'),
                    ),
                    DropdownMenuItem(
                      value: 'en proceso',
                      child: Text('En Proceso'),
                    ),
                    DropdownMenuItem(
                      value: 'entregado',
                      child: Text('Entregados'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _filtroEstado = v ?? 'Todos'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por solicitante o área...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PedidoInterno>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final data = snap.data ?? [];

                // Filtrado
                final filtered = data.where((pedido) {
                  final matchEstado =
                      _filtroEstado == 'Todos' ||
                      pedido.estado == _filtroEstado;
                  final matchQuery =
                      _query.isEmpty ||
                      pedido.solicitante.toLowerCase().contains(_query) ||
                      pedido.area.toLowerCase().contains(_query) ||
                      pedido.id.toLowerCase().contains(_query);
                  return matchEstado && matchQuery;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Sin resultados'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final pedido = filtered[index];
                    final color = _estadoColor(pedido.estado);
                    final icon = _estadoIcon(pedido.estado);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: InkWell(
                        onTap: () => _mostrarDetallePedido(pedido),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Pedido ${pedido.id}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon, size: 16, color: color),
                                        const SizedBox(width: 6),
                                        Text(
                                          pedido.estado.toUpperCase(),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Solicitante: ${pedido.solicitante}'),
                              Text('Área: ${pedido.area}'),
                              const SizedBox(height: 8),
                              Text(
                                'Productos: ${pedido.productos.length} items',
                                style: const TextStyle(
                                  color: AppColors.grisTextoSecundario,
                                ),
                              ),
                              Text(
                                'Solicitud: ${pedido.fechaSolicitud.hour.toString().padLeft(2, '0')}:${pedido.fechaSolicitud.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: AppColors.grisTextoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}
