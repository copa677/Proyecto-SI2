import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.negroTexto,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gestione la configuración del sistema',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.grisTextoSecundario,
              ),
            ),
            const SizedBox(height: 32),
            _ImportExportCard(),
            const SizedBox(height: 32),
            _PreferenciasSistemaCard(),
            const SizedBox(height: 32),
            _CerrarSesionButton(),
          ],
        ),
      ),
    );
  }
}

class _CerrarSesionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          // Aquí puedes agregar la lógica real de logout
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
      ),
    );
  }
}

class _ImportExportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.blanco,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Importación/Exportación de Datos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.negroTexto),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Apilar verticalmente en móvil
                  return Column(
                    children: [
                      _ExportarDatosCard(),
                      const SizedBox(height: 18),
                      _ImportarDatosCard(),
                    ],
                  );
                } else {
                  // Mostrar en fila en pantallas grandes
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _ExportarDatosCard()),
                      const SizedBox(width: 24),
                      Expanded(child: _ImportarDatosCard()),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportarDatosCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grisMuyClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exportar Datos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.negroTexto)),
          const SizedBox(height: 4),
          const Text('Descargue los datos del sistema en formato CSV', style: TextStyle(color: AppColors.grisTextoSecundario)),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                // En móvil, apilar botones
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ConfigButton(text: 'Exportar Personal'),
                    const SizedBox(height: 8),
                    _ConfigButton(text: 'Exportar Asistencia'),
                    const SizedBox(height: 8),
                    _ConfigButton(text: 'Exportar Usuarios'),
                  ],
                );
              } else {
                // En escritorio, mantener fila
                return Row(
                  children: [
                    Expanded(child: _ConfigButton(text: 'Exportar Personal')),
                    const SizedBox(width: 8),
                    Expanded(child: _ConfigButton(text: 'Exportar Asistencia')),
                    const SizedBox(width: 8),
                    Expanded(child: _ConfigButton(text: 'Exportar Usuarios')),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ImportarDatosCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grisMuyClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Importar Datos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.negroTexto)),
          const SizedBox(height: 4),
          const Text('Suba archivos CSV para importar datos al sistema', style: TextStyle(color: AppColors.grisTextoSecundario)),
          const SizedBox(height: 18),
          _ConfigFileInput(label: 'Personal'),
          const SizedBox(height: 10),
          _ConfigFileInput(label: 'Asistencia'),
          const SizedBox(height: 10),
          _ConfigFileInput(label: 'Usuarios'),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: _ConfigButton(text: 'Importar Seleccionados', isPrimary: true),
          ),
        ],
      ),
    );
  }
}

class _ConfigButton extends StatelessWidget {
  final String text;
  final bool isPrimary;
  const _ConfigButton({required this.text, this.isPrimary = false});

  Future<void> _exportar(BuildContext context) async {
    if (text.startsWith('Exportar')) {
      try {
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Selecciona la carpeta de destino');
        if (selectedDirectory == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exportación cancelada.')),
          );
          return;
        }
        final filePath = '$selectedDirectory/${text.replaceAll(' ', '_').toLowerCase()}.csv';
        final file = File(filePath);
        await file.writeAsString('id,nombre,valor\n1,Ejemplo,123');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo exportado en: $filePath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.azulPrincipal : AppColors.blanco,
        foregroundColor: isPrimary ? AppColors.blanco : AppColors.azulPrincipal,
        elevation: isPrimary ? 2 : 0,
        side: isPrimary ? null : const BorderSide(color: AppColors.azulPrincipal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        _exportar(context);
      },
      child: Text(text),
    );
  }
}

class _ConfigFileInput extends StatefulWidget {
  final String label;
  const _ConfigFileInput({required this.label});

  @override
  State<_ConfigFileInput> createState() => _ConfigFileInputState();
}

class _ConfigFileInputState extends State<_ConfigFileInput> {
  String? _fileName;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (!mounted) return;
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _fileName = result.files.single.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo seleccionado: ${result.files.single.name}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ningún archivo.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.negroTexto)),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.blanco,
                border: Border.all(color: AppColors.grisLineas),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: AppColors.grisTextoSecundario, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fileName ?? 'Seleccionar archivo',
                      style: TextStyle(
                        color: _fileName == null ? AppColors.grisTextoSecundario : AppColors.negroTexto,
                        fontWeight: _fileName == null ? FontWeight.normal : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreferenciasSistemaCard extends StatefulWidget {
  @override
  State<_PreferenciasSistemaCard> createState() => _PreferenciasSistemaCardState();
}

class _PreferenciasSistemaCardState extends State<_PreferenciasSistemaCard> {
  bool notificacionesEmail = true;
  bool modoOscuro = false;
  String idioma = 'Español';

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.blanco,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preferencias del Sistema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.negroTexto)),
            const SizedBox(height: 24),
            _PreferenciaSwitch(
              title: 'Notificaciones por Email',
              subtitle: 'Recibir notificaciones sobre asistencia y turnos',
              value: notificacionesEmail,
              onChanged: (v) => setState(() => notificacionesEmail = v),
            ),
            const SizedBox(height: 16),
            _PreferenciaSwitch(
              title: 'Modo Oscuro',
              subtitle: 'Cambiar la apariencia del sistema',
              value: modoOscuro,
              onChanged: (v) => setState(() => modoOscuro = v),
            ),
            const SizedBox(height: 24),
            const Text('Idioma del Sistema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.negroTexto)),
            const SizedBox(height: 4),
            const Text('Seleccione el idioma preferido', style: TextStyle(color: AppColors.grisTextoSecundario)),
            const SizedBox(height: 12),
            _ConfigDropdown(
              value: idioma,
              onChanged: (v) => setState(() => idioma = v ?? idioma),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _ConfigButton(text: 'Guardar Cambios', isPrimary: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenciaSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PreferenciaSwitch({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          // En móvil, apilar
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.negroTexto)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.grisTextoSecundario)),
              Align(
                alignment: Alignment.centerLeft,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.azulPrincipal,
                  inactiveTrackColor: AppColors.grisLineas,
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        } else {
          // En escritorio, mantener fila
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.negroTexto)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.grisTextoSecundario)),
                ],
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.azulPrincipal,
                inactiveTrackColor: AppColors.grisLineas,
              ),
            ],
          );
        }
      },
    );
  }
}

class _ConfigDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _ConfigDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanco,
        border: Border.all(color: AppColors.grisLineas),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: const [
            DropdownMenuItem(value: 'Español', child: Text('Español')),
            DropdownMenuItem(value: 'Inglés', child: Text('Inglés')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
