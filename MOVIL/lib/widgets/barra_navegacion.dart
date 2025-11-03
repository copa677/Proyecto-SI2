import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BarraNavegacion extends StatelessWidget {
  final List<Widget> paginas;

  const BarraNavegacion({Key? key, required this.paginas}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: paginas.length,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          backgroundColor: AppColors.blanco,
          foregroundColor: AppColors.grisTextoSecundario,
          elevation: 1,
          // Usamos todo el contenido dentro del bottom para compartir el mismo padding izquierdo
          toolbarHeight: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56 + 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bloque de título con padding uniforme
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sistema de Manufactura',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                // Bloque de tabs con el mismo padding horizontal
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: TabBar(
                    isScrollable: true,
                    // Alinear los tabs al inicio y eliminar el margen extra en extremos
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.azulPrincipal,
                    unselectedLabelColor: AppColors.grisTextoSecundario,
                    indicatorColor: AppColors.azulPrincipal,
                    // Evitar el sobre-deslizamiento (bounce) y limitar el rango
                    physics: const ClampingScrollPhysics(),
                    labelPadding: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                    tabs: const [
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.only(right: 24),
                          child: Text('Dashboard'),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.only(right: 24),
                          child: Text('Órdenes'),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.only(right: 24),
                          child: Text('Asistencia y Turnos'),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.only(right: 24),
                          child: Text('Configuración'),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.only(right: 24),
                          child: Text('Perfil'),
                        ),
                      ),
                    ],
                  ),
                ),
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
