import 'package:flutter/material.dart';

class PersonalGestion extends StatefulWidget {
  const PersonalGestion({Key? key}) : super(key: key);

  @override
  State<PersonalGestion> createState() => _PersonalGestionState();
}

class _PersonalGestionState extends State<PersonalGestion> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  String _selectedRole = 'Todos los roles';

  final List<String> _roles = [
    'Todos los roles',
    'Supervisor',
    'Administrador',
    'Operario',
  ];

  final List<PersonalData> _personalList = [
    PersonalData(
      id: '001',
      nombre: 'Juan Perez',
      email: 'juan.perez@ejemplo.com',
      rol: 'Supervisor',
      permisos: ['Asistencia', 'Reportes'],
      iniciales: 'JP',
      color: Colors.blue,
    ),
    PersonalData(
      id: '002',
      nombre: 'Maria Gonzalez',
      email: 'maria.gonzalez@ejemplo.com',
      rol: 'Administrador',
      permisos: ['Asistencia', 'Reportes', 'Admin'],
      iniciales: 'MG',
      color: Colors.purple,
    ),
    PersonalData(
      id: '003',
      nombre: 'Carlos Rodriguez',
      email: 'carlos.rodriguez@ejemplo.com',
      rol: 'Operario',
      permisos: ['Básico'],
      iniciales: 'CR',
      color: Colors.orange,
    ),
  ];

  List<PersonalData> get filteredPersonal {
    List<PersonalData> filtered = _personalList;

    if (_selectedRole != 'Todos los roles') {
      filtered = filtered
          .where((person) => person.rol == _selectedRole)
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where(
            (person) =>
                person.nombre.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                person.email.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Gestión de Personal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,

        // botones de perfil eliminado
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.person, color: Color(0xFF2C3E50)),
        //     onPressed: () {},
        //   ),
        // ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con descripción y botón
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administre los datos del personal de la empresa',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navegación a añadir personal
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Función añadir personal'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Añadir Personal',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
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

          // Barra de búsqueda y filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar personal...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF6C757D),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
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
                        color: Color(0xFF495057),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFDEE2E6)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          underline: Container(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedRole = newValue!;
                            });
                          },
                          items: _roles.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(value),
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

          // Lista de personal
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Tabla completa con scroll sincronizado
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _horizontalScrollController,
                      child: SizedBox(
                        width: 720,
                        child: Column(
                          children: [
                            // Header de la tabla
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFE9ECEF)),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  SizedBox(
                                    width: 170,
                                    child: Text('NOMBRE', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF495057))),
                                  ),
                                  SizedBox(
                                    width: 180,
                                    child: Text('EMAIL', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF495057))),
                                  ),
                                  SizedBox(
                                    width: 110,
                                    child: Text('ROL', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF495057))),
                                  ),
                                  SizedBox(
                                    width: 140,
                                    child: Text('PERMISOS', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF495057))),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF495057))),
                                  ),
                                ],
                              ),
                            ),

                            // Lista de empleados
                            Expanded(
                              child: ListView.builder(
                                itemCount: filteredPersonal.length,
                                itemBuilder: (context, index) {
                                  final person = filteredPersonal[index];
                                  return PersonalCard(person: person);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer con paginación
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mostrando ${filteredPersonal.length} de ${_personalList.length} resultados',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: null,
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Color(0xFFADB5BD),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007BFF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              onPressed: null,
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFFADB5BD),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
    _horizontalScrollController.dispose();
    super.dispose();
  }
}

class PersonalCard extends StatelessWidget {
  final PersonalData person;

  const PersonalCard({Key? key, required this.person}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 720,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        children: [
          // Avatar e información personal
          SizedBox(
            width: 170,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: person.color,
                  radius: 16,
                  child: Text(
                    person.iniciales,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.nombre,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF495057),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ${person.id}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Email
          SizedBox(
            width: 180,
            child: Text(
              person.email,
              style: const TextStyle(fontSize: 12, color: Color(0xFF495057)),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Rol
          SizedBox(
            width: 110,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(person.rol),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                person.rol,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Permisos
          SizedBox(
            width: 140,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: person.permisos.take(2).map((permiso) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F3FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF007BFF),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    permiso,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF007BFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Acciones
          SizedBox(
            width: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Editar ${person.nombre}')),
                    );
                  },
                  child: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Color(0xFF007BFF),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _showDeleteDialog(context, person);
                  },
                  child: const Icon(
                    Icons.delete,
                    size: 18,
                    color: Color(0xFFDC3545),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Supervisor':
        return const Color(0xFF28A745);
      case 'Administrador':
        return const Color(0xFF007BFF);
      case 'Operario':
        return const Color(0xFF6C757D);
      default:
        return const Color(0xFF6C757D);
    }
  }

  void _showDeleteDialog(BuildContext context, PersonalData person) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Está seguro de que desea eliminar a ${person.nombre}?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Color(0xFFDC3545)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${person.nombre} eliminado')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class PersonalData {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final List<String> permisos;
  final String iniciales;
  final Color color;

  PersonalData({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.permisos,
    required this.iniciales,
    required this.color,
  });
}
