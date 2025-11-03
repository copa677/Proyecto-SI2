import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_texto.dart';
import '../widgets/campo_busqueda.dart';
import '../widgets/dropdown_personalizado.dart';
import '../widgets/etiqueta_estado.dart';
import '../widgets/turno_card.dart';
import '../widgets/registro_asistencia_item.dart';
import '../widgets/fila_tabla_usuario.dart';

class PruebasPage extends StatefulWidget {
  const PruebasPage({Key? key}) : super(key: key);

  @override
  State<PruebasPage> createState() => _PruebasPageState();
}

class _PruebasPageState extends State<PruebasPage> {
  final TextEditingController _textoCtrl = TextEditingController();
  final TextEditingController _busquedaCtrl = TextEditingController();
  String _dropdownValor = 'Opción A';
  String _estado = 'Activo';

  @override
  void dispose() {
    _textoCtrl.dispose();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Pruebas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.negroTexto,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Zona de pruebas para widgets y flujos de UI. Nada aquí afecta datos reales.',
                style: TextStyle(color: AppColors.grisTextoSecundario),
              ),
              const SizedBox(height: 16),

              // Botón principal
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Botón principal'),
                      const SizedBox(height: 8),
                      BotonPrincipal(
                        texto: 'Acción de prueba',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Botón presionado')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Campo de texto y búsqueda
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Campos de texto'),
                      const SizedBox(height: 8),
                      CampoTexto(
                        etiqueta: 'Nombre',
                        icono: Icons.person,
                        controlador: _textoCtrl,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      CampoTexto(
                        etiqueta: 'Contraseña',
                        icono: Icons.lock,
                        esContrasena: true,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 12),
                      CampoBusqueda(
                        controller: _busquedaCtrl,
                        hintText: 'Buscar algo...',
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Dropdown y etiqueta de estado
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dropdown y estado'),
                      const SizedBox(height: 8),
                      DropdownPersonalizado(
                        items: const ['Opción A', 'Opción B', 'Opción C'],
                        valorSeleccionado: _dropdownValor,
                        labelText: 'Opciones',
                        isExpanded: true,
                        clearable: true,
                        selectFirstWhenNull: false,
                        onChanged: (v) {
                          setState(() => _dropdownValor = v ?? '');
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Estado: '),
                          const SizedBox(width: 8),
                          EtiquetaEstado(estado: _estado),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _estado = _estado == 'Activo'
                                    ? 'Inactivo'
                                    : 'Activo';
                              });
                            },
                            child: const Text('Toggle estado'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tarjetas de turno
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Turnos'),
                      SizedBox(height: 8),
                      TurnoCard(
                        titulo: 'Turno Mañana',
                        horario: '08:00 - 16:00',
                        personas: 12,
                      ),
                      SizedBox(height: 8),
                      TurnoCard(
                        titulo: 'Turno Tarde',
                        horario: '16:00 - 00:00',
                        personas: 9,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Registro asistencia y Fila usuario
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Componentes de lista'),
                      SizedBox(height: 8),
                      RegistroAsistenciaItem(
                        nombre: 'Juan Pérez',
                        iniciales: 'JP',
                        fecha: '2025-10-12',
                        turno: 'Mañana',
                        estado: 'Presente',
                        estadoColor: Colors.green,
                      ),
                      SizedBox(height: 8),
                      FilaTablaUsuario(
                        nombre: 'María Gomez',
                        id: 'U-102',
                        email: 'maria@empresa.com',
                        estado: 'Activo',
                        tipo: 'Admin',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
