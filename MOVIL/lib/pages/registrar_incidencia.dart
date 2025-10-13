import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/incidencias_service.dart';

class RegistrarIncidenciaPage extends StatefulWidget {
  final String ordenId;
  final String lote;
  final String producto;
  final String etapaActual;
  final String responsableActual; // se podría obtener del usuario autenticado

  const RegistrarIncidenciaPage({
    super.key,
    required this.ordenId,
    required this.lote,
    required this.producto,
    required this.etapaActual,
    required this.responsableActual,
  });

  @override
  State<RegistrarIncidenciaPage> createState() =>
      _RegistrarIncidenciaPageState();
}

class _RegistrarIncidenciaPageState extends State<RegistrarIncidenciaPage> {
  final _formKey = GlobalKey<FormState>();
  final IncidenciasService _service = IncidenciasService();

  // Campos del formulario
  String? _tipoDefecto;
  final TextEditingController _descripcionCtrl = TextEditingController();
  String? _etapaOcurrencia;
  String? _severidad; // Baja/Media/Alta
  String? _imagenPath;

  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _etapaOcurrencia = widget.etapaActual; // por defecto, la etapa actual
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    final inc = Incidencia(
      ordenId: widget.ordenId,
      lote: widget.lote,
      producto: widget.producto,
      etapa: _etapaOcurrencia ?? widget.etapaActual,
      tipoDefecto: _tipoDefecto!,
      descripcion: _descripcionCtrl.text.trim(),
      severidad: _severidad!,
      responsable: widget.responsableActual,
      fechaHora: DateTime.now(),
      imagenPath: _imagenPath,
    );

    final ok = await _service.registrarIncidencia(inc);
    setState(() => _enviando = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incidencia registrada')));
      Navigator.of(context).pop(); // cerrar panel
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar la incidencia')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blanco,
        foregroundColor: AppColors.negroTexto,
        elevation: 0.5,
        title: const Text('Registrar Incidencia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Row(
        children: [
          // Espaciador flexible para empujar la hoja a la derecha en pantallas anchas
          if (MediaQuery.of(context).size.width > 800)
            const Expanded(child: SizedBox()),
          SizedBox(
            width: MediaQuery.of(context).size.width > 800
                ? 480
                : MediaQuery.of(context).size.width,
            child: _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // B. Información contextual
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grisMuyClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orden: ${widget.ordenId}  |  Lote: ${widget.lote}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('Etapa actual: ${_capitalizar(widget.etapaActual)}'),
                  Text('Producto: ${widget.producto}'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // C. Formulario
            DropdownButtonFormField<String>(
              value: _tipoDefecto,
              isExpanded: true,
              items: const [
                'Costura',
                'Mancha',
                'Error de talla',
                'Tela dañada',
                'Error de estampado',
                'Otro',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              decoration: _decor('Tipo de defecto'),
              onChanged: (v) => setState(() => _tipoDefecto = v),
              validator: (v) =>
                  v == null ? 'Seleccione un tipo de defecto' : null,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 4,
              decoration: _decor('Descripción'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingrese una descripción'
                  : null,
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _etapaOcurrencia,
              isExpanded: true,
              items:
                  const ['corte', 'costura', 'estampado', 'acabado', 'empaque']
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(_capitalizar(e)),
                        ),
                      )
                      .toList(),
              decoration: _decor('Etapa donde ocurrió'),
              onChanged: (v) => setState(() => _etapaOcurrencia = v),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _severidad,
              isExpanded: true,
              items: const [
                'Baja',
                'Media',
                'Alta',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              decoration: _decor('Severidad'),
              onChanged: (v) => setState(() => _severidad = v),
              validator: (v) => v == null ? 'Seleccione severidad' : null,
            ),

            const SizedBox(height: 12),

            // Imagen: mock - elegimos ruta local (pendiente integrar picker/cámara)
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    // TODO: Integrar image_picker / camera
                    setState(() => _imagenPath = 'mock://imagen.jpg');
                  },
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Tomar foto / Elegir imagen'),
                ),
                const SizedBox(width: 12),
                if (_imagenPath != null)
                  Expanded(
                    child: Text(
                      _imagenPath!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grisTextoSecundario,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Responsable y Fecha/Hora automáticos (solo lectura)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: widget.responsableActual,
                    readOnly: true,
                    decoration: _decor('Responsable'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _fmtFechaHora(DateTime.now()),
                    readOnly: true,
                    decoration: _decor('Fecha y hora'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                child: _enviando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Registrar incidencia'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  InputDecoration _decor(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  String _fmtFechaHora(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}
