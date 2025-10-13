import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OrdenProduccionCard extends StatelessWidget {
  final String codigo;
  final String producto;
  final String lote;
  final String estado; // En proceso / Retrasada / Completada
  final String etapa; // Corte / Costura / Estampado / Acabado / Empaque
  final int progreso; // 0..100
  final DateTime? fechaInicio;
  final DateTime? fechaEntregaEstimada;
  final VoidCallback? onVerDetalles;

  const OrdenProduccionCard({
    Key? key,
    required this.codigo,
    required this.producto,
    required this.lote,
    required this.estado,
    required this.etapa,
    required this.progreso,
    this.fechaInicio,
    this.fechaEntregaEstimada,
    this.onVerDetalles,
  }) : super(key: key);

  Color _estadoColor(String e) {
    switch (e.toLowerCase()) {
      case 'completada':
        return const Color(0xFF12B76A); // verde
      case 'retrasada':
        return const Color(0xFFF79009); // naranja
      case 'en proceso':
      default:
        return const Color(0xFF175CD3); // azul
    }
  }

  Color _etapaColor(String e) {
    switch (e.toLowerCase()) {
      case 'corte':
        return Colors.blue.shade500;
      case 'costura':
        return Colors.indigo.shade500;
      case 'estampado':
        return Colors.orange.shade600;
      case 'acabado':
        return Colors.teal.shade600;
      case 'empaque':
        return Colors.green.shade600;
      default:
        return AppColors.grisTextoSecundario;
    }
  }

  String _fmtFecha(DateTime d) {
    // Solo fecha (sin horas) -> yyyy-mm-dd
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _estadoColor(estado);
    final etapaColor = _etapaColor(etapa);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Orden: $codigo',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.negroTexto,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Ver detalles',
                  onPressed: onVerDetalles,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Producto y Lote
            Text('Producto: $producto', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('Lote: $lote', style: const TextStyle(fontSize: 14)),

            const SizedBox(height: 10),

            // Estado y Etapa chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estado,
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: etapaColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    etapa,
                    style: TextStyle(
                      color: etapaColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progreso
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (progreso.clamp(0, 100)) / 100.0,
                      minHeight: 8,
                      backgroundColor: AppColors.grisMuyClaro,
                      color: etapaColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${progreso.clamp(0, 100)}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Fechas (una debajo de la otra para evitar overflow)
            if (fechaInicio != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.grisTextoSecundario,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Inicio: ${_fmtFecha(fechaInicio!)}',
                    style: const TextStyle(
                      color: AppColors.grisTextoSecundario,
                    ),
                  ),
                ],
              ),
            ],
            if (fechaEntregaEstimada != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.outbound_rounded,
                    size: 16,
                    color: AppColors.grisTextoSecundario,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Entrega est.: ${_fmtFecha(fechaEntregaEstimada!)}',
                    style: const TextStyle(
                      color: AppColors.grisTextoSecundario,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
