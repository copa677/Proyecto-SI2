import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/campo_busqueda.dart';
import '../widgets/dropdown_personalizado.dart';
import '../widgets/cabecera_tabla.dart';
import '../widgets/fila_tabla_usuario.dart';

class UsuariosPage extends StatelessWidget {
  const UsuariosPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usuarios = [
      {
        'nombre': 'Admin Usuario',
        'id': '001',
        'email': 'admin@ejemplo.com',
        'estado': 'Activo',
        'tipo': 'Administrador',
      },
      {
        'nombre': 'Juan Pérez',
        'id': '002',
        'email': 'juan@ejemplo.com',
        'estado': 'Activo',
        'tipo': 'Supervisor',
      },
      {
        'nombre': 'María González',
        'id': '003',
        'email': 'maria@ejemplo.com',
        'estado': 'Inactivo',
        'tipo': 'Operario',
      },
    ];

    String estadoSeleccionado = 'Todos los estados';
    String tipoSeleccionado = 'Todos los tipos';

    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y botón
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Gestión de Usuarios',
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulPrincipal,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Filtros y búsqueda
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 600;
                  if (isSmall) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: CampoBusqueda(hintText: 'Buscar usuario...'),
                            ),
                            DropdownPersonalizado(
                              items: const ['Todos los estados', 'Activo', 'Inactivo'],
                              valorSeleccionado: estadoSeleccionado,
                              hint: 'Estado',
                            ),
                            DropdownPersonalizado(
                              items: const ['Todos los tipos', 'Administrador', 'Supervisor', 'Operario'],
                              valorSeleccionado: tipoSeleccionado,
                              hint: 'Tipo',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.azulPrincipal,
                                side: const BorderSide(color: AppColors.azulPrincipal),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {},
                              child: const Text('Limpiar'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.azulPrincipal,
                                foregroundColor: AppColors.blanco,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {},
                              child: const Text('Registrar Usuario'),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: CampoBusqueda(hintText: 'Buscar usuario...'),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: DropdownPersonalizado(
                            items: const ['Todos los estados', 'Activo', 'Inactivo'],
                            valorSeleccionado: estadoSeleccionado,
                            hint: 'Estado',
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: DropdownPersonalizado(
                            items: const ['Todos los tipos', 'Administrador', 'Supervisor', 'Operario'],
                            valorSeleccionado: tipoSeleccionado,
                            hint: 'Tipo',
                          ),
                        ),
                        const SizedBox(width: 20),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.azulPrincipal,
                            side: const BorderSide(color: AppColors.azulPrincipal),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {},
                          child: const Text('Limpiar'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulPrincipal,
                            foregroundColor: AppColors.blanco,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {},
                          child: const Text('Registrar Usuario'),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              // Aquí aseguramos el tamaño finito
              Expanded(
                child: Card(
                  color: AppColors.grisMuyClaro,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 700,
                        child: Column(
                          children: [
                            CabeceraTabla(
                              columnas: const ['USUARIO', 'EMAIL', 'ESTADO', 'TIPO'],
                            ),
                            Divider(height: 1, color: AppColors.grisLineas),
                            Expanded(
                              child: ListView.separated(
                                itemCount: usuarios.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.grisLineas),
                                itemBuilder: (context, i) {
                                  final u = usuarios[i];
                                  return FilaTablaUsuario(
                                    nombre: u['nombre']!,
                                    id: u['id']!,
                                    email: u['email']!,
                                    estado: u['estado']!,
                                    tipo: u['tipo']!,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mostrando ${usuarios.length} de ${usuarios.length} resultados',
                style: const TextStyle(color: AppColors.grisTextoSecundario, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}