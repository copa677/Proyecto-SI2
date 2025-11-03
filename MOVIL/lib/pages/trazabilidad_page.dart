import 'package:flutter/material.dart';
import '../services/trazabilidad_service.dart';
import '../services/ordenes_service.dart';
import '../theme/app_colors.dart';

class TrazabilidadPage extends StatefulWidget {
  final OrdenProduccion orden;

  const TrazabilidadPage({Key? key, required this.orden}) : super(key: key);

  @override
  State<TrazabilidadPage> createState() => _TrazabilidadPageState();
}

class _TrazabilidadPageState extends State<TrazabilidadPage> {
  final TrazabilidadService _trazabilidadService = TrazabilidadService();
  late Future<List<Trazabilidad>> _trazabilidadesFuture;
  List<EtapaProduccion> _etapas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarTrazabilidades();
  }

  void _cargarTrazabilidades() {
    setState(() {
      _trazabilidadesFuture = _trazabilidadService.getTrazabilidades(
        idOrden: widget.orden.idOrden,
      );
    });
  }

  void _refrescar() {
    _cargarTrazabilidades();
  }

  Color _getEtapaColor(String estado) {
    switch (estado) {
      case 'completado':
        return const Color(0xFF12B76A); // Verde
      case 'en_proceso':
        return const Color(0xFFF79009); // Naranja
      case 'pendiente':
      default:
        return AppColors.grisTextoSecundario; // Gris
    }
  }

  IconData _getEtapaIcon(String estado) {
    switch (estado) {
      case 'completado':
        return Icons.check_circle_rounded;
      case 'en_proceso':
        return Icons.play_circle_filled_rounded;
      case 'pendiente':
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  IconData _getEtapaProcesosIcon(String proceso) {
    switch (proceso.toLowerCase()) {
      case 'corte':
        return Icons.content_cut_rounded;
      case 'costura':
        return Icons.web_asset_rounded;
      case 'estampado':
        return Icons.brush_rounded;
      case 'acabado':
        return Icons.build_rounded;
      case 'empaque':
        return Icons.inventory_2_rounded;
      default:
        return Icons.settings_rounded;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String _formatearFechaHora(DateTime fecha) {
    return '${_formatearFecha(fecha)} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  void _mostrarFormularioEtapa(EtapaProduccion etapa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FormularioEtapa(
        etapa: etapa,
        orden: widget.orden,
        onEtapaRegistrada: () {
          Navigator.pop(context);
          _refrescar();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      appBar: AppBar(
        backgroundColor: AppColors.azulPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Trazabilidad',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _refrescar,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: FutureBuilder<List<Trazabilidad>>(
        future: _trazabilidadesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: AppColors.grisTextoSecundario,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar trazabilidad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.negroTexto,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grisTextoSecundario,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refrescar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulPrincipal,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final trazabilidades = snapshot.data ?? [];
          _etapas = _trazabilidadService.generarEtapasProduccion(
            trazabilidades,
          );
          final progresoReal = _trazabilidadService.calcularProgresoReal(
            _etapas,
            widget.orden.cantidadTotal,
          );
          final etapaActual = _trazabilidadService.getEtapaActual(_etapas);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información general del lote/orden
                _buildInfoGeneral(progresoReal, etapaActual),
                const SizedBox(height: 24),

                // Timeline de etapas
                _buildTimelineEtapas(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoGeneral(int progresoReal, String? etapaActual) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.azulPrincipal.withOpacity(0.1),
            AppColors.azulClaro.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.azulPrincipal.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.azulPrincipal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orden: ${widget.orden.codOrden}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.negroTexto,
                      ),
                    ),
                    Text(
                      widget.orden.productoCompleto,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grisTextoSecundario,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Cantidad',
                  '${widget.orden.cantidadTotal} unidades',
                  Icons.production_quantity_limits_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  'Estado actual',
                  etapaActual ?? 'Sin iniciar',
                  Icons.timeline_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progreso total
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progreso total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.negroTexto,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.verdePrincipal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$progresoReal%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.grisMuyClaro,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progresoReal / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.verdePrincipal,
                          AppColors.verdePrincipal.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grisLineas, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.azulPrincipal),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grisTextoSecundario,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.negroTexto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEtapas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Etapas de Producción',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.negroTexto,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _etapas.length,
          separatorBuilder: (context, index) => _buildTimelineConnector(),
          itemBuilder: (context, index) {
            final etapa = _etapas[index];
            return _buildEtapaCard(etapa, index == _etapas.length - 1);
          },
        ),
      ],
    );
  }

  Widget _buildTimelineConnector() {
    return Container(
      margin: const EdgeInsets.only(left: 28),
      width: 2,
      height: 20,
      color: AppColors.grisLineas,
    );
  }

  Widget _buildEtapaCard(EtapaProduccion etapa, bool isLast) {
    final color = _getEtapaColor(etapa.estado);
    final icon = _getEtapaIcon(etapa.estado);
    final procesoIcon = _getEtapaProcesosIcon(etapa.nombre);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono de timeline y estado
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3), width: 2),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(procesoIcon, size: 20, color: color),
                          const SizedBox(width: 8),
                          Text(
                            etapa.nombre,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.negroTexto,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        etapa.descripcion,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grisTextoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getEstadoTexto(etapa.estado),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            // Información de fechas y operario
            if (etapa.fechaInicio != null || etapa.operario != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grisMuyClaro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (etapa.fechaInicio != null) ...[
                      _buildDetalleInfo(
                        'Inicio',
                        _formatearFechaHora(etapa.fechaInicio!),
                        Icons.play_arrow_rounded,
                      ),
                    ],
                    if (etapa.fechaFin != null) ...[
                      const SizedBox(height: 8),
                      _buildDetalleInfo(
                        'Finalización',
                        _formatearFechaHora(etapa.fechaFin!),
                        Icons.stop_rounded,
                      ),
                    ],
                    if (etapa.operario != null) ...[
                      const SizedBox(height: 8),
                      _buildDetalleInfo(
                        'Operario',
                        etapa.operario!,
                        Icons.person_rounded,
                      ),
                    ],
                    if (etapa.cantidad != null) ...[
                      const SizedBox(height: 8),
                      _buildDetalleInfo(
                        'Cantidad procesada',
                        '${etapa.cantidad} unidades',
                        Icons.inventory_rounded,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Botón de acción
            if (!etapa.estaCompletada) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _mostrarFormularioEtapa(etapa),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: Icon(
                    etapa.estaEnProceso
                        ? Icons.flag_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(
                    etapa.estaEnProceso ? 'Finalizar etapa' : 'Iniciar etapa',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grisTextoSecundario),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.grisTextoSecundario,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.negroTexto,
            ),
          ),
        ),
      ],
    );
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'completado':
        return 'Completada';
      case 'en_proceso':
        return 'En proceso';
      case 'pendiente':
      default:
        return 'Pendiente';
    }
  }
}

// Formulario para registrar avance de etapa
class _FormularioEtapa extends StatefulWidget {
  final EtapaProduccion etapa;
  final OrdenProduccion orden;
  final VoidCallback onEtapaRegistrada;

  const _FormularioEtapa({
    required this.etapa,
    required this.orden,
    required this.onEtapaRegistrada,
  });

  @override
  State<_FormularioEtapa> createState() => _FormularioEtapaState();
}

class _FormularioEtapaState extends State<_FormularioEtapa> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _nombreOperarioController = TextEditingController();
  final _trazabilidadService = TrazabilidadService();
  bool _isLoading = false;
  String? _nombreUsuario;

  @override
  void initState() {
    super.initState();
    _cantidadController.text = widget.orden.cantidadTotal.toString();
    // El campo del operario inicia vacío para que el usuario ingrese su nombre
    _obtenerNombreUsuario();
  }

  void _obtenerNombreUsuario() {
    // Usar el valor del campo de texto que el usuario ingrese
    _nombreUsuario = _nombreOperarioController.text.isNotEmpty
        ? _nombreOperarioController.text
        : null; // El campo inicia vacío
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _cantidadController.dispose();
    _nombreOperarioController.dispose();
    super.dispose();
  }

  Future<void> _registrarEtapa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Actualizar el nombre del usuario con el valor actual del campo
    _nombreUsuario = _nombreOperarioController.text.trim();

    if (_nombreUsuario == null || _nombreUsuario!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese el nombre del operario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ahora = DateTime.now();
      final esIniciar = !widget.etapa.estaEnProceso;

      String descripcion;
      String estado;
      String horaInicio;
      String horaFin;

      if (esIniciar) {
        descripcion =
            'Inicio de ${widget.etapa.nombre.toLowerCase()}: ${_comentarioController.text.isNotEmpty ? _comentarioController.text : 'Sin observaciones'}';
        estado = 'En Proceso';
        horaInicio = _trazabilidadService.formatearHora(ahora);
        horaFin = '00:00:00';
      } else {
        descripcion =
            'Finalización de ${widget.etapa.nombre.toLowerCase()}: ${_comentarioController.text.isNotEmpty ? _comentarioController.text : 'Sin observaciones'}';
        estado = 'Completado';
        horaInicio = widget.etapa.fechaInicio != null
            ? _trazabilidadService.formatearHora(widget.etapa.fechaInicio!)
            : _trazabilidadService.formatearHora(ahora);
        horaFin = _trazabilidadService.formatearHora(ahora);
      }

      await _trazabilidadService.registrarTrazabilidad(
        proceso: widget.etapa.nombre,
        descripcionProceso: descripcion,
        fechaRegistro: ahora,
        horaInicio: horaInicio,
        horaFin: horaFin,
        cantidad:
            int.tryParse(_cantidadController.text) ??
            widget.orden.cantidadTotal,
        estado: estado,
        nombrePersonal: _nombreUsuario!,
        idOrden: widget.orden.idOrden,
      );

      widget.onEtapaRegistrada();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              esIniciar
                  ? 'Etapa ${widget.etapa.nombre} iniciada exitosamente'
                  : 'Etapa ${widget.etapa.nombre} finalizada exitosamente',
            ),
            backgroundColor: AppColors.verdePrincipal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al registrar etapa: $e';

        // Personalizar mensaje si es error de personal no encontrado
        if (e.toString().contains('No existe un personal con el nombre')) {
          errorMessage =
              'El operario "${_nombreUsuario}" no está registrado en el sistema.\n\n'
              'Por favor:\n'
              '1. Verifique que escribió el nombre correctamente\n'
              '2. Use uno de los nombres registrados\n'
              '3. Contacte al administrador para registrar nuevos operarios';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.rojo,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esIniciar = !widget.etapa.estaEnProceso;
    final color = esIniciar
        ? AppColors.verdePrincipal
        : AppColors.azulPrincipal;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    esIniciar ? Icons.play_arrow_rounded : Icons.flag_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${esIniciar ? 'Iniciar' : 'Finalizar'} ${widget.etapa.nombre}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.negroTexto,
                        ),
                      ),
                      Text(
                        widget.etapa.descripcion,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grisTextoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Campo de cantidad
            TextFormField(
              controller: _cantidadController,
              decoration: InputDecoration(
                labelText: 'Cantidad procesada',
                hintText: 'Ingrese la cantidad de unidades',
                prefixIcon: const Icon(Icons.inventory_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese la cantidad';
                }
                final cantidad = int.tryParse(value);
                if (cantidad == null || cantidad <= 0) {
                  return 'Ingrese una cantidad válida';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Campo de nombre del operario
            TextFormField(
              controller: _nombreOperarioController,
              decoration: InputDecoration(
                labelText: 'Nombre del operario *',
                hintText: 'Ej: Juan Pérez, María García',
                helperText:
                    'Debe coincidir exactamente con el nombre registrado en el sistema',
                prefixIcon: const Icon(Icons.person_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingrese el nombre del operario';
                }
                if (value.trim().length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Campo de comentario
            TextFormField(
              controller: _comentarioController,
              decoration: InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Observaciones, problemas o notas adicionales',
                prefixIcon: const Icon(Icons.comment_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
              maxLines: 3,
              maxLength: 200,
            ),

            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.grisTextoSecundario),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.negroTexto,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registrarEtapa,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            esIniciar ? 'Iniciar' : 'Finalizar',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
