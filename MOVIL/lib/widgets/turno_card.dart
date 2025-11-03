import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TurnoCard extends StatelessWidget {
  final String titulo;
  final String horario;
  final int personas;
  const TurnoCard({required this.titulo, required this.horario, required this.personas, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grisLineas),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 2),
              Text(horario, style: const TextStyle(fontSize: 13, color: AppColors.grisTextoSecundario)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.verdeClaro,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${personas} personas',
              style: const TextStyle(fontSize: 13, color: AppColors.verdePrincipal, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
