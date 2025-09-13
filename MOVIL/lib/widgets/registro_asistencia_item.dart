import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RegistroAsistenciaItem extends StatelessWidget {
  final String nombre;
  final String iniciales;
  final String fecha;
  final String turno;
  final String estado;
  final Color estadoColor;

  const RegistroAsistenciaItem({
    Key? key,
    required this.nombre,
    required this.iniciales,
    required this.fecha,
    required this.turno,
    required this.estado,
    required this.estadoColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.azulPrincipal.withOpacity(0.12),
            child: Text(
              iniciales,
              style: const TextStyle(
                color: AppColors.azulPrincipal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: Text(fecha, style: const TextStyle(color: AppColors.grisTextoSecundario)),
          ),
          Expanded(
            flex: 2,
            child: Text(turno, style: const TextStyle(color: AppColors.grisTextoSecundario)),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 80),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: estado.toLowerCase() == 'presente'
                  ? const Color(0xFFD1FADF)
                  : const Color(0xFFFEE4E2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              estado,
              style: TextStyle(
                color: estado.toLowerCase() == 'presente'
                    ? const Color(0xFF039855)
                    : const Color(0xFFB42318),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
