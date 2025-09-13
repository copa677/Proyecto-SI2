import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/campo_busqueda.dart';
import '../widgets/dropdown_personalizado.dart';
import '../widgets/cabecera_tabla.dart';
import '../widgets/fila_tabla_usuario.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({Key? key}) : super(key: key);

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  void _abrirDialogoEditarUsuario(Map<String, String> usuario, int index) {
    final _formKey = GlobalKey<FormState>();
    String nombre = usuario['nombre']!;
    String email = usuario['email']!;
    String tipo = usuario['tipo']!;
    String estado = usuario['estado']!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 400,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nombre', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: nombre,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Ingrese un nombre' : null,
                        onChanged: (v) => nombre = v,
                      ),
                      const SizedBox(height: 18),
                      const Text('Email', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: email,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Ingrese un email' : null,
                        onChanged: (v) => email = v,
                      ),
                      const SizedBox(height: 18),
                      const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      DropdownPersonalizado(
                        items: const ['Operario', 'Supervisor', 'Administrador'],
                        valorSeleccionado: tipo,
                        onChanged: (v) => setStateDialog(() => tipo = v ?? tipo),
                      ),
                      const SizedBox(height: 18),
                      const Text('Estado', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      DropdownPersonalizado(
                        items: const ['Activo', 'Inactivo'],
                        valorSeleccionado: estado,
                        onChanged: (v) => setStateDialog(() => estado = v ?? estado),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.azulPrincipal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                setState(() {
                                  usuarios[index]['nombre'] = nombre;
                                  usuarios[index]['email'] = email;
                                  usuarios[index]['tipo'] = tipo;
                                  usuarios[index]['estado'] = estado;
                                });
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Usuario actualizado')),
                                );
                              }
                            },
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _eliminarUsuario(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: const Text('¿Está seguro de eliminar este usuario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                usuarios.removeAt(index);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuario eliminado')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  void _abrirDialogoRegistrarUsuario() {
    final _formKey = GlobalKey<FormState>();
    String nombre = '';
    String email = '';
    String tipo = 'Operario';
    String estado = 'Activo';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Registrar Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 400,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nombre', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: '',
                        decoration: InputDecoration(
                          hintText: 'Admin Usuario',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Ingrese un nombre' : null,
                        onChanged: (v) => nombre = v,
                      ),
                      const SizedBox(height: 18),
                      const Text('Email', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: '',
                        decoration: InputDecoration(
                          hintText: 'admin@ejemplo.com',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Ingrese un email' : null,
                        onChanged: (v) => email = v,
                      ),
                      const SizedBox(height: 18),
                      const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      DropdownPersonalizado(
                        items: const ['Operario', 'Supervisor', 'Administrador'],
                        valorSeleccionado: tipo,
                        onChanged: (v) => setStateDialog(() => tipo = v ?? tipo),
                      ),
                      const SizedBox(height: 18),
                      const Text('Estado', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      DropdownPersonalizado(
                        items: const ['Activo', 'Inactivo'],
                        valorSeleccionado: estado,
                        onChanged: (v) => setStateDialog(() => estado = v ?? estado),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.azulPrincipal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                // Aquí puedes guardar el usuario
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
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

  @override
  Widget build(BuildContext context) {
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
                              items: const ['Todos los estados', 'Activos', 'Inactivos'],
                              valorSeleccionado: estadoSeleccionado,
                              hint: 'Estado',
                              onChanged: (v) {
                                if (v != null) setState(() => estadoSeleccionado = v);
                              },
                            ),
                            DropdownPersonalizado(
                              items: const ['Todos los tipos', 'Administrador', 'Supervisor', 'Operario'],
                              valorSeleccionado: tipoSeleccionado,
                              hint: 'Tipo',
                              onChanged: (v) {
                                if (v != null) setState(() => tipoSeleccionado = v);
                              },
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
                              onPressed: _abrirDialogoRegistrarUsuario,
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
                            items: const ['Todos los estados', 'Activos', 'Inactivos'],
                            valorSeleccionado: estadoSeleccionado,
                            hint: 'Estado',
                            onChanged: (v) {
                              if (v != null) setState(() => estadoSeleccionado = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: DropdownPersonalizado(
                            items: const ['Todos los tipos', 'Administrador', 'Supervisor', 'Operario'],
                            valorSeleccionado: tipoSeleccionado,
                            hint: 'Tipo',
                            onChanged: (v) {
                              if (v != null) setState(() => tipoSeleccionado = v);
                            },
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
                            SizedBox(
                              height: 320,
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
                                    acciones: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Color(0xFF2563EB)),
                                          tooltip: 'Editar',
                                          onPressed: () => _abrirDialogoEditarUsuario(u, i),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Eliminar',
                                          onPressed: () => _eliminarUsuario(i),
                                        ),
                                      ],
                                    ),
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