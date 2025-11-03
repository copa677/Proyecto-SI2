import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/registro_asistencia_item.dart';
import '../widgets/campo_busqueda.dart';
import '../widgets/dropdown_personalizado.dart';
import '../widgets/turno_card.dart';

class AsistenciasTurnosPage extends StatefulWidget {
  const AsistenciasTurnosPage({Key? key}) : super(key: key);

  @override
  State<AsistenciasTurnosPage> createState() => _AsistenciasTurnosPageState();
}

class _AsistenciasTurnosPageState extends State<AsistenciasTurnosPage> {
  DateTime? _fechaSeleccionada;

  // Filtros de Turno y Estado
  String _turnoSeleccionado = 'Todos los turnos';
  String _estadoSeleccionado = 'Todos los estados';

  String get _fechaTexto {
    if (_fechaSeleccionada == null) return '';
    final d = _fechaSeleccionada!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // --- Formulario de registro de asistencia ---
  void _abrirDialogoRegistrarAsistencia() {
    final _formKey = GlobalKey<FormState>();
    String nombre = '';
    DateTime? fecha = DateTime.now();
    String turno = 'Mañana (8:00–14:00)';
    String estado = 'Presente';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Registrar Asistencia', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          hintText: 'Juan Pérez',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Ingrese un nombre' : null,
                        onChanged: (v) => nombre = v,
                      ),
                      const SizedBox(height: 18),
                      const Text('Fecha', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: fecha ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setStateDialog(() => fecha = picked);
                        },
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: TextEditingController(
                              text: fecha == null ? '' : '${fecha!.day.toString().padLeft(2, '0')}/${fecha!.month.toString().padLeft(2, '0')}/${fecha!.year}',
                            ),
                            decoration: InputDecoration(
                              hintText: 'dd/mm/aaaa',
                              suffixIcon: Icon(Icons.calendar_today, size: 20, color: AppColors.grisTextoSecundario),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            readOnly: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('Turno', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: turno,
                        items: const [
                          DropdownMenuItem(value: 'Mañana (8:00–14:00)', child: Text('Mañana (8:00–14:00)')),
                          DropdownMenuItem(value: 'Tarde (14:00–20:00)', child: Text('Tarde (14:00–20:00)')),
                          DropdownMenuItem(value: 'Noche (20:00–02:00)', child: Text('Noche (20:00–02:00)')),
                        ],
                        onChanged: (v) => setStateDialog(() => turno = v ?? turno),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('Estado', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: estado,
                        items: const [
                          DropdownMenuItem(value: 'Presente', child: Text('Presente')),
                          DropdownMenuItem(value: 'Ausente', child: Text('Ausente')),
                        ],
                        onChanged: (v) => setStateDialog(() => estado = v ?? estado),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: Colors.white,
                        ),
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
                                // Aquí puedes guardar la asistencia
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'Asistencia y Turnos',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.negroTexto),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    backgroundColor: AppColors.azulPrincipal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _abrirDialogoRegistrarAsistencia,
                  child: const Text('Registrar Asistencia'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Gestione la asistencia y los turnos del personal',
              style: TextStyle(fontSize: 16, color: AppColors.grisTextoSecundario),
            ),
            const SizedBox(height: 32),
            // Filtros arriba
            Card(
              color: AppColors.grisMuyClaro,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Calendario de Asistencias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.negroTexto)),
                    const SizedBox(height: 18),
                    // Fecha
                    const Text('Fecha', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: TextEditingController(text: _fechaTexto),
                      decoration: InputDecoration(
                        hintText: 'dd/mm/aaaa',
                        suffixIcon: Icon(Icons.calendar_today, size: 20, color: AppColors.grisTextoSecundario),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final hoy = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fechaSeleccionada ?? hoy,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _fechaSeleccionada = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    // Turno
                    const Text('Turno', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    DropdownPersonalizado(
                      items: const [
                        'Todos los turnos',
                        'Mañana (8:00–14:00)',
                        'Tarde (14:00–20:00)',
                        'Noche (20:00–02:00)'
                      ],
                      valorSeleccionado: _turnoSeleccionado,
                      onChanged: (v) {
                        setState(() {
                          _turnoSeleccionado = v ?? _turnoSeleccionado;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    // Estado
                    const Text('Estado', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    DropdownPersonalizado(
                      items: const [
                        'Todos los estados',
                        'Presente',
                        'Ausente',
                        'Tarde',
                        'Licencia'
                      ],
                      valorSeleccionado: _estadoSeleccionado,
                      onChanged: (v) {
                        setState(() {
                          _estadoSeleccionado = v ?? _estadoSeleccionado;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    // Buscar por nombre
                    const Text('Buscar por nombre', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    CampoBusqueda(
                      hintText: 'Escribe un nombre...',
                      onChanged: (v) {},
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Limpiar filtros'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Resumen de Asistencia y Turnos Activos
            Card(
              color: AppColors.blanco,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumen de Asistencia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 18),
                    const Text('Hoy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Total Personal:', style: TextStyle(fontSize: 15)),
                        Text('3', style: TextStyle(fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Asistencia:', style: TextStyle(fontSize: 15)),
                        Text('2 (67%)', style: TextStyle(fontSize: 15, color: AppColors.verdePrincipal, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Ausencias:', style: TextStyle(fontSize: 15)),
                        Text('1 (33%)', style: TextStyle(fontSize: 15, color: AppColors.grisTextoSecundario, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0.67,
                        minHeight: 8,
                        backgroundColor: AppColors.grisLineas,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.verdePrincipal),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Turnos Activos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Column(
                      children: const [
                        TurnoCard(
                          titulo: 'Mañana (8:00–14:00)',
                          horario: '8:00 AM - 2:00 PM',
                          personas: 2,
                        ),
                        SizedBox(height: 10),
                        TurnoCard(
                          titulo: 'Tarde (14:00–20:00)',
                          horario: '2:00 PM - 8:00 PM',
                          personas: 1,
                        ),
                        SizedBox(height: 10),
                        TurnoCard(
                          titulo: 'Noche (20:00–02:00)',
                          horario: '8:00 PM - 2:00 AM',
                          personas: 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Registros de asistencia abajo
            Card(
              color: AppColors.blanco,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 700,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 0),
                          child: Text('Registro de Asistencias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.negroTexto)),
                        ),
                        const SizedBox(height: 16),
                        // Encabezados alineados con los datos
                        Row(
                          children: const [
                            SizedBox(width: 40), // Avatar
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.only(left: 0),
                                child: Text('NOMBRE', style: TextStyle(color: AppColors.grisTextoSecundario, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('FECHA', style: TextStyle(color: AppColors.grisTextoSecundario, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('TURNO', style: TextStyle(color: AppColors.grisTextoSecundario, fontWeight: FontWeight.bold)),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text('ESTADO', style: TextStyle(color: AppColors.grisTextoSecundario, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Divider(),
                        // Lista scrollable de registros
                        SizedBox(
                          height: 320,
                          child: ListView(
                            physics: ClampingScrollPhysics(),
                            shrinkWrap: true,
                            children: const [
                              RegistroAsistenciaItem(
                                nombre: 'Juan Pérez',
                                iniciales: 'JP',
                                fecha: '13/09/2025',
                                turno: 'Mañana (8:00–14:00)',
                                estado: 'Presente',
                                estadoColor: AppColors.verdePrincipal,
                              ),
                              RegistroAsistenciaItem(
                                nombre: 'Ana López',
                                iniciales: 'AL',
                                fecha: '13/09/2025',
                                turno: 'Tarde (14:00–20:00)',
                                estado: 'Presente',
                                estadoColor: AppColors.verdePrincipal,
                              ),
                              RegistroAsistenciaItem(
                                nombre: 'Carlos Ruiz',
                                iniciales: 'CR',
                                fecha: '13/09/2025',
                                turno: 'Noche (20:00–02:00)',
                                estado: 'Ausente',
                                estadoColor: AppColors.rojo,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}