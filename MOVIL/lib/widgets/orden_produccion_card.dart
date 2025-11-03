import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OrdenProduccionCard extends StatelessWidget {
  final String codigo;
  final String producto;
  final String lote;
  final String estado; // Planificada / En Proceso / Completado / Cancelado
  final String etapa; // Para compatibilidad, usaremos estado
  final int? progreso; // 0..100 - opcional, si es null no se muestra
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
    this.progreso,
    this.fechaInicio,
    this.fechaEntregaEstimada,
    this.onVerDetalles,
  }) : super(key: key);

  Color _estadoColor(String e) {
    switch (e.toLowerCase()) {
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

  IconData _estadoIcon(String e) {
    switch (e.toLowerCase()) {
      case 'planificada':
        return Icons.schedule_rounded;
      case 'en proceso':
        return Icons.play_circle_filled_rounded;
      case 'completado':
        return Icons.check_circle_rounded;
      case 'cancelado':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  List<Color> _gradientColors(String e) {
    switch (e.toLowerCase()) {
      case 'planificada':
        return [const Color(0xFF1570EF), const Color(0xFF3B82F6)];
      case 'en proceso':
        return [const Color(0xFFF79009), const Color(0xFFFFB020)];
      case 'completado':
        return [const Color(0xFF12B76A), const Color(0xFF32D583)];
      case 'cancelado':
        return [const Color(0xFFF04438), const Color(0xFFFF6B6B)];
      default:
        return [AppColors.grisTextoSecundario, AppColors.grisTextoSecundario];
    }
  }

  String _fmtFecha(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _estadoColor(estado);
    final gradientColors = _gradientColors(estado);
    final estadoIcon = _estadoIcon(estado);
    final progresoDecimal = (progreso ?? 0) / 100.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withOpacity(0.05),
            gradientColors[1].withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: estadoColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: estadoColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con código y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                codigo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.negroTexto,
                                ),
                              ),
                              Text(
                                'Orden de Producción',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grisTextoSecundario,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: estadoColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(estadoIcon, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          estado,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Producto
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_outlined,
                      color: estadoColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Producto',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.grisTextoSecundario,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            producto,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.negroTexto,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Lote
              Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, color: estadoColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Lote: ',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grisTextoSecundario,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    lote,
                    style: TextStyle(
                      fontSize: 14,
                      color: estadoColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Solo mostrar progreso si se proporciona
              if (progreso != null) ...[
                const SizedBox(height: 16),
                // Progreso
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: estadoColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timeline_rounded,
                                color: estadoColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Progreso',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.negroTexto,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: estadoColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$progreso%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progresoDecimal,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Fechas
              if (fechaInicio != null || fechaEntregaEstimada != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (fechaInicio != null) ...[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 14,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _fmtFecha(fechaInicio!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (fechaInicio != null && fechaEntregaEstimada != null)
                      const SizedBox(width: 8),
                    if (fechaEntregaEstimada != null) ...[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.flag_rounded,
                                size: 14,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _fmtFecha(fechaEntregaEstimada!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Botón ver detalles
              if (onVerDetalles != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onVerDetalles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: estadoColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text(
                      'Ver detalles',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
