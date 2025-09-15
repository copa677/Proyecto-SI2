import 'package:flutter/material.dart';
import '../services/personal_service.dart';
import '../theme/app_colors.dart';

/// Modelo local para representar a un empleado.
/// Usa los campos enviados por el backend.
class PersonalData {
  final int idUsuario;
  final String nombre;
  final String direccion;
  final String telefono;
  final String rol;
  final String fechaNacimiento;
  final String estado;

  PersonalData({
    required this.idUsuario,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.rol,
    required this.fechaNacimiento,
    required this.estado,
  });

  /// Construye desde el JSON retornado por obtener_empleados.
  factory PersonalData.fromJson(Map<String, dynamic> json) {
    return PersonalData(
      idUsuario: json['id_usuario'] ?? 0,
      nombre: json['nombre_completo'] ?? '',
      direccion: json['direccion'] ?? '',
      telefono: json['telefono'] ?? '',
      rol: json['rol'] ?? '',
      fechaNacimiento: json['fecha_nacimiento'] ?? '',
      estado: json['estado'] ?? '',
    );
  }

  /// Iniciales para el avatar.
  String get iniciales {
    if (nombre.trim().isEmpty) return '';
    final partes = nombre.split(' ');
    if (partes.length == 1) return partes.first.substring(0, 2).toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }
}

class PersonalGestion extends StatefulWidget {
  const PersonalGestion({Key? key}) : super(key: key);

  @override
  State<PersonalGestion> createState() => _PersonalGestionState();
}

class _PersonalGestionState extends State<PersonalGestion> {
  final PersonalService _personalService = PersonalService();

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalController = ScrollController();

  String _selectedRole = 'Todos los roles';
  final List<String> _roles = const [
    'Todos los roles',
    'Supervisor',
    'Administrador',
    'Operario',
  ];

  List<PersonalData> _personalList = [];

  @override
  void initState() {
    super.initState();
    _loadPersonal();
  }

  Future<void> _loadPersonal() async {
    try {
      final data = await _personalService.getEmpleados();
      setState(() {
        _personalList = data
            .map<PersonalData>((e) => PersonalData.fromJson(e))
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener personal: $e')));
    }
  }

  /// Devuelve la lista filtrada según el rol y el texto de búsqueda.
  List<PersonalData> get filteredPersonal {
    List<PersonalData> filtered = _personalList;

    if (_selectedRole != 'Todos los roles') {
      filtered = filtered
          .where((person) => person.rol == _selectedRole)
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (person) =>
                person.nombre.toLowerCase().contains(query) ||
                person.telefono.toLowerCase().contains(query),
          )
          .toList();
    }

    return filtered;
  }

  /// Abre un diálogo para registrar un nuevo empleado y llama al servicio.
  Future<void> _registrarPersonalDialog() async {
    final formKey = GlobalKey<FormState>();
    String nombre = '';
    String direccion = '';
    String telefono = '';
    String rol = _roles[1]; // por defecto Supervisor
    String fechaNac = '';
    String estado = 'Activo';
    String username = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar empleado'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese nombre' : null,
                    onChanged: (v) => nombre = v,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese dirección' : null,
                    onChanged: (v) => direccion = v,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese teléfono' : null,
                    onChanged: (v) => telefono = v,
                  ),
                  DropdownButtonFormField<String>(
                    value: rol,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: _roles
                        .where((r) => r != 'Todos los roles')
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => rol = v ?? rol,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de nacimiento (aaaa-mm-dd)',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese fecha' : null,
                    onChanged: (v) => fechaNac = v,
                  ),
                  DropdownButtonFormField<String>(
                    value: estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                      DropdownMenuItem(
                        value: 'Inactivo',
                        child: Text('Inactivo'),
                      ),
                    ],
                    onChanged: (v) => estado = v ?? estado,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Usuario (username)',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese usuario' : null,
                    onChanged: (v) => username = v,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final datos = {
                    'nombre_completo': nombre,
                    'direccion': direccion,
                    'telefono': telefono,
                    'rol': rol,
                    'fecha_nacimiento': fechaNac,
                    'estado': estado,
                    'username': username,
                  };
                  final ok = await _personalService.registrarEmpleado(datos);
                  Navigator.of(context).pop();
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Empleado registrado correctamente'),
                      ),
                    );
                    await _loadPersonal();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error al registrar empleado'),
                      ),
                    );
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

  /// Abre un diálogo para editar los datos de un empleado.
  Future<void> _editarPersonalDialog(PersonalData persona) async {
    final formKey = GlobalKey<FormState>();
    String nombre = persona.nombre;
    String direccion = persona.direccion;
    String telefono = persona.telefono;
    String rol = persona.rol;
    String fechaNac = persona.fechaNacimiento;
    String estado = persona.estado;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar empleado'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: nombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese nombre' : null,
                    onChanged: (v) => nombre = v,
                  ),
                  TextFormField(
                    initialValue: direccion,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese dirección' : null,
                    onChanged: (v) => direccion = v,
                  ),
                  TextFormField(
                    initialValue: telefono,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese teléfono' : null,
                    onChanged: (v) => telefono = v,
                  ),
                  DropdownButtonFormField<String>(
                    value: rol,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: _roles
                        .where((r) => r != 'Todos los roles')
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => rol = v ?? rol,
                  ),
                  TextFormField(
                    initialValue: fechaNac,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de nacimiento (aaaa-mm-dd)',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese fecha' : null,
                    onChanged: (v) => fechaNac = v,
                  ),
                  DropdownButtonFormField<String>(
                    value: estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                      DropdownMenuItem(
                        value: 'Inactivo',
                        child: Text('Inactivo'),
                      ),
                    ],
                    onChanged: (v) => estado = v ?? estado,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final datos = {
                    'nombre_completo': nombre,
                    'direccion': direccion,
                    'telefono': telefono,
                    'rol': rol,
                    'fecha_nacimiento': fechaNac,
                    'estado': estado,
                    'id_usuario': persona.idUsuario,
                  };
                  final ok = await _personalService.actualizarEmpleado(datos);
                  Navigator.of(context).pop();
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Empleado actualizado correctamente'),
                      ),
                    );
                    await _loadPersonal();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error al actualizar empleado'),
                      ),
                    );
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

  /// Elimina un empleado después de confirmar.
  Future<void> _eliminarPersonal(PersonalData persona) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Eliminar a ${persona.nombre}? Esta acción borrará su usuario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      final ok = await _personalService.eliminarEmpleado(persona.idUsuario);
      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Empleado eliminado')));
        await _loadPersonal();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar empleado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisMuyClaro,
      appBar: AppBar(
        title: const Text(
          'Gestión de Personal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.negroTexto,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con descripción y botón de añadir
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administre los datos del personal de la empresa',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grisTextoSecundario,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _registrarPersonalDialog,
                    //onPressed: null,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Añadir personal',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulPrincipal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Búsqueda y filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar personal...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.grisTextoSecundario,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.grisLineas),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.grisLineas),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Filtro por rol
                Row(
                  children: [
                    const Text(
                      'Filtrar por:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.negroTexto,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grisLineas),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          underline: Container(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value ?? 'Todos los roles';
                            });
                          },
                          items: _roles.map((role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(role),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabla de resultados
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Iniciales')),
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Teléfono')),
                  DataColumn(label: Text('Rol')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: filteredPersonal.map((persona) {
                  return DataRow(
                    cells: [
                      DataCell(
                        CircleAvatar(
                          backgroundColor: AppColors.azulClaro.withOpacity(0.2),
                          child: Text(
                            persona.iniciales,
                            style: const TextStyle(
                              color: AppColors.azulPrincipal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(persona.nombre)),
                      DataCell(Text(persona.telefono)),
                      DataCell(Text(persona.rol)),
                      DataCell(Text(persona.estado)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.azulPrincipal,
                              ),
                              onPressed: () => _editarPersonalDialog(persona),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _eliminarPersonal(persona),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }
}
