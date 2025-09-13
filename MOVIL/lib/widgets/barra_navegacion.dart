import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BarraNavegacion extends StatelessWidget {
  final List<Widget> paginas;

  const BarraNavegacion({Key? key, required this.paginas}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: const Text(
            'Sistema de Manufactura',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.blanco,
          foregroundColor: AppColors.grisTextoSecundario,
          elevation: 1,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: TabBar(
              isScrollable: true,
              labelColor: AppColors.azulPrincipal,
              unselectedLabelColor: AppColors.grisTextoSecundario,
              indicatorColor: AppColors.azulPrincipal,
              tabs: [
                Tab(text: 'Dashboard'),
                Tab(text: 'Personal'),
                Tab(text: 'Asistencia y Turnos'),
                Tab(text: 'Usuarios'),
                Tab(text: 'Configuración'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: paginas.map((pagina) => SafeArea(child: pagina)).toList(),
        ),
      ),
    );
  }
}
