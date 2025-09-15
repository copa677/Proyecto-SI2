import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/campo_busqueda.dart';
import '../widgets/dropdown_personalizado.dart';
import '../widgets/cabecera_tabla.dart';
import '../widgets/fila_tabla_usuario.dart';
import '../services/user_service.dart';
import '../services/personal_service.dart';

/// Página para gestionar los usuarios del sistema.
///
/// Esta versión reemplaza la lista estática por una lista obtenida del
/// backend mediante [UserService]. Permite filtrar por estado y tipo de
/// usuario, buscar por nombre de usuario o email y registrar un nuevo
/// usuario desde un diálogo. Los botones de edición y eliminación
/// actualizan sólo el listado local; para eliminar realmente un
/// usuario en la base de datos deberías usar [PersonalService.eliminarEmpleado],
/// ya que el backend no expone un endpoint específico para borrar
/// usuarios.
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({Key? key}) : super(key: key);

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final UserService _userService = UserService();
  final PersonalService _personalService = PersonalService();
  final TextEditingController _busquedaController = TextEditingController();

  String _estadoSeleccionado = 'Todos los estados';
  String _tipoSeleccionado = 'Todos los tipos';

  List<dynamic> _usuarios = [];

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    try {
      final data = await _userService.getUsuarios();
      setState(() {
        _usuarios = data;
      });
    } catch (e) {
      // Muestra un snack bar en caso de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener usuarios: $e')),
        );
      }
    }

    // prueba para ver si se obtiene bien los usuarios
    /*try {
      final data = await _userService.getUsuarios();
      print('Usuarios obtenidos: $data'); // añade este print
      setState(() {
        _usuarios = data;
      });
    } catch (e) {
      print('Error al obtener usuarios: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener usuarios: $e')));
    }*/
  }

  /// Aplica los filtros y la búsqueda sobre la lista de usuarios.
  List<dynamic> get _filteredUsuarios {
    List<dynamic> filtered = List<dynamic>.from(_usuarios);

    // Filtrar por estado
    if (_estadoSeleccionado != 'Todos los estados') {
      final filtroEstado = _estadoSeleccionado == 'Activos'
          ? 'activo'
          : 'inactivo';
      filtered = filtered
          .where(
            (u) => (u['estado'] ?? '').toString().toLowerCase() == filtroEstado,
          )
          .toList();
    }

    // Filtrar por tipo de usuario
    if (_tipoSeleccionado != 'Todos los tipos') {
      final filtroTipo = _tipoSeleccionado.toLowerCase();
      filtered = filtered
          .where(
            (u) =>
                (u['tipo_usuario'] ?? '').toString().toLowerCase() ==
                filtroTipo,
          )
          .toList();
    }

    // Búsqueda por name_user o email
    final query = _busquedaController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (u) =>
                (u['name_user'] ?? '').toString().toLowerCase().contains(
                  query,
                ) ||
                (u['email'] ?? '').toString().toLowerCase().contains(query),
          )
          .toList();
    }

    return filtered;
  }

  /// Abre un diálogo para registrar un nuevo usuario.
  Future<void> _abrirDialogoRegistrarUsuario() async {
    final formKey = GlobalKey<FormState>();
    String nombreUsuario = '';
    String email = '';
    String password = '';
    String tipo = 'Operario';
    String estado = 'Activo';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Registrar Usuario',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nombre de usuario',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Usuario',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Ingrese nombre' : null,
                        onChanged: (v) => nombreUsuario = v,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'correo@ejemplo.com',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Ingrese email' : null,
                        onChanged: (v) => email = v,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Contraseña',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '********',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Ingrese contraseña'
                            : null,
                        onChanged: (v) => password = v,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Tipo',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      DropdownPersonalizado(
                        items: const [
                          'Operario',
                          'Supervisor',
                          'Administrador',
                        ],
                        valorSeleccionado: tipo,
                        onChanged: (v) =>
                            setStateDialog(() => tipo = v ?? tipo),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Estado',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      DropdownPersonalizado(
                        items: const ['Activo', 'Inactivo'],
                        valorSeleccionado: estado,
                        onChanged: (v) =>
                            setStateDialog(() => estado = v ?? estado),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrincipal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final nuevo = {
                    'name_user': nombreUsuario,
                    'password': password,
                    'email': email,
                    'tipo_usuario': tipo,
                    'estado': estado,
                  };
                  final ok = await _userService.registerUsuario(nuevo);
                  Navigator.of(context).pop();
                  if (ok) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Usuario registrado correctamente'),
                        ),
                      );
                    }
                    await _loadUsuarios();
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al registrar usuario'),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// Abre el diálogo de edición y actualiza el listado local.
  void _abrirDialogoEditarUsuario(Map<String, dynamic> usuario, int index) {
    final formKey = GlobalKey<FormState>();
    String nombre = usuario['name_user'];
    String email = usuario['email'];
    String tipo = usuario['tipo_usuario'];
    String estado = usuario['estado'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Editar Usuario',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nombre de usuario',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: nombre,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Ingrese nombre' : null,
                        onChanged: (v) => nombre = v,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: email,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Ingrese email' : null,
                        onChanged: (v) => email = v,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Tipo',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      DropdownPersonalizado(
                        items: const [
                          'Operario',
                          'Supervisor',
                          'Administrador',
                        ],
                        valorSeleccionado: tipo,
                        onChanged: (v) =>
                            setStateDialog(() => tipo = v ?? tipo),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Estado',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      DropdownPersonalizado(
                        items: const ['Activo', 'Inactivo'],
                        valorSeleccionado: estado,
                        onChanged: (v) =>
                            setStateDialog(() => estado = v ?? estado),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrincipal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  setState(() {
                    _usuarios[index]['name_user'] = nombre;
                    _usuarios[index]['email'] = email;
                    _usuarios[index]['tipo_usuario'] = tipo;
                    _usuarios[index]['estado'] = estado;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usuario actualizado (solo local)'),
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// Confirma y elimina el usuario localmente. Para borrar en la base de datos
  /// llama a PersonalService.eliminarEmpleado(idUsuario) si lo deseas.
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
                _usuarios.removeAt(index);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuario eliminado (solo local)')),
              );
              // Para eliminar en la base de datos, descomenta el siguiente
              // código y reemplaza idUsuario por el id real:
              // final id = _usuarios[index]['id'];
              // await _personalService.eliminarEmpleado(id);
              // await _loadUsuarios();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
              // Título
              const Text(
                'Gestión de Usuarios',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulPrincipal,
                ),
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
                              child: CampoBusqueda(
                                controller: _busquedaController,
                                hintText: 'Buscar usuario...',
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                            DropdownPersonalizado(
                              items: const [
                                'Todos los estados',
                                'Activos',
                                'Inactivos',
                              ],
                              valorSeleccionado: _estadoSeleccionado,
                              hint: 'Estado',
                              onChanged: (v) {
                                if (v != null)
                                  setState(() => _estadoSeleccionado = v);
                              },
                            ),
                            DropdownPersonalizado(
                              items: const [
                                'Todos los tipos',
                                'Administrador',
                                'Supervisor',
                                'Operario',
                              ],
                              valorSeleccionado: _tipoSeleccionado,
                              hint: 'Tipo',
                              onChanged: (v) {
                                if (v != null)
                                  setState(() => _tipoSeleccionado = v);
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
                                side: const BorderSide(
                                  color: AppColors.azulPrincipal,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _busquedaController.clear();
                                  _estadoSeleccionado = 'Todos los estados';
                                  _tipoSeleccionado = 'Todos los tipos';
                                });
                              },
                              child: const Text('Limpiar'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.azulPrincipal,
                                foregroundColor: AppColors.blanco,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
                          child: CampoBusqueda(
                            controller: _busquedaController,
                            hintText: 'Buscar usuario...',
                            onChanged: (v) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: DropdownPersonalizado(
                            items: const [
                              'Todos los estados',
                              'Activos',
                              'Inactivos',
                            ],
                            valorSeleccionado: _estadoSeleccionado,
                            hint: 'Estado',
                            onChanged: (v) {
                              if (v != null)
                                setState(() => _estadoSeleccionado = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: DropdownPersonalizado(
                            items: const [
                              'Todos los tipos',
                              'Administrador',
                              'Supervisor',
                              'Operario',
                            ],
                            valorSeleccionado: _tipoSeleccionado,
                            hint: 'Tipo',
                            onChanged: (v) {
                              if (v != null)
                                setState(() => _tipoSeleccionado = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.azulPrincipal,
                            side: const BorderSide(
                              color: AppColors.azulPrincipal,
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _busquedaController.clear();
                              _estadoSeleccionado = 'Todos los estados';
                              _tipoSeleccionado = 'Todos los tipos';
                            });
                          },
                          child: const Text('Limpiar'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulPrincipal,
                            foregroundColor: AppColors.blanco,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _abrirDialogoRegistrarUsuario,
                          child: const Text('Registrar Usuario'),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
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
                            const CabeceraTabla(
                              columnas: ['USUARIO', 'EMAIL', 'ESTADO', 'TIPO'],
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.grisLineas,
                            ),
                            SizedBox(
                              height: 320,
                              child: ListView.separated(
                                itemCount: _filteredUsuarios.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  color: AppColors.grisLineas,
                                ),
                                itemBuilder: (context, i) {
                                  final u = _filteredUsuarios[i];
                                  return FilaTablaUsuario(
                                    nombre: u['name_user'] ?? '',
                                    id: (u['id'] ?? '').toString(),
                                    email: u['email'] ?? '',
                                    estado: u['estado'] ?? '',
                                    tipo: u['tipo_usuario'] ?? '',
                                    acciones: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Color(0xFF2563EB),
                                          ),
                                          tooltip: 'Editar',
                                          onPressed: () =>
                                              _abrirDialogoEditarUsuario(
                                                u as Map<String, dynamic>,
                                                i,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
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
                'Mostrando ${_filteredUsuarios.length} de ${_usuarios.length} resultados',
                style: const TextStyle(
                  color: AppColors.grisTextoSecundario,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }
}
