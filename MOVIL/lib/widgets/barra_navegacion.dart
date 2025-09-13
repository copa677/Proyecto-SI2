import 'package:flutter/material.dart';

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
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: TabBar(
              isScrollable: true,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.blue,
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
          children: paginas.map((pagina) => SafeArea(child: SingleChildScrollView(child: pagina))).toList(),
        ),
      ),
    );
  }
}
