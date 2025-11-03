import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'campo_busqueda.dart';
import 'dropdown_personalizado.dart';

enum OrdenFiltroCampo { todos, lote, producto }

String _campoToLabel(OrdenFiltroCampo c) {
  switch (c) {
    case OrdenFiltroCampo.lote:
      return 'Lote';
    case OrdenFiltroCampo.producto:
      return 'Producto';
    case OrdenFiltroCampo.todos:
      return 'Todos';
  }
}

OrdenFiltroCampo _labelToCampo(String label) {
  switch (label) {
    case 'Lote':
      return OrdenFiltroCampo.lote;
    case 'Producto':
      return OrdenFiltroCampo.producto;
    case 'Todos':
    default:
      return OrdenFiltroCampo.todos;
  }
}

class EtapaChipSelector extends StatelessWidget {
  final String? etapaSeleccionada; // null = todas
  final ValueChanged<String?> onChanged;
  final List<String> etapas;

  const EtapaChipSelector({
    Key? key,
    required this.etapaSeleccionada,
    required this.onChanged,
    this.etapas = const ['corte', 'costura', 'estampado', 'acabado', 'empaque'],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        FilterChip(
          selected: etapaSeleccionada == null,
          label: const Text('Todas'),
          onSelected: (_) => onChanged(null),
        ),
        ...etapas.map(
          (e) => FilterChip(
            selected: etapaSeleccionada == e,
            label: Text(e[0].toUpperCase() + e.substring(1)),
            onSelected: (sel) => onChanged(sel ? e : null),
          ),
        ),
      ],
    );
  }
}

class DateRangeSelector extends StatelessWidget {
  final DateTimeRange? range;
  final ValueChanged<DateTimeRange?> onChanged;
  final String label;

  const DateRangeSelector({
    Key? key,
    required this.range,
    required this.onChanged,
    this.label = 'Rango de fechas',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final text = range == null
        ? label
        : '${_fmt(range!.start)} - ${_fmt(range!.end)}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(now.year - 5),
              lastDate: DateTime(now.year + 5),
              initialDateRange: range,
              helpText: 'Selecciona el rango',
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(
                    context,
                  ).colorScheme.copyWith(primary: AppColors.azulPrincipal),
                ),
                child: child!,
              ),
            );
            onChanged(picked);
          },
          icon: const Icon(Icons.date_range),
          label: Text(text),
        ),
        if (range != null)
          IconButton(
            tooltip: 'Limpiar rango',
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.clear),
          ),
      ],
    );
  }

  String _fmt(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}

class FiltroOrdenesBar extends StatelessWidget {
  final OrdenFiltroCampo campo;
  final ValueChanged<OrdenFiltroCampo> onCampoChange;
  final String query;
  final ValueChanged<String> onQueryChange;
  final String? etapa;
  final ValueChanged<String?> onEtapaChange;
  final VoidCallback? onRefresh;
  // Nota: el rango de fechas y el botón de reinicio se han ocultado temporalmente.

  const FiltroOrdenesBar({
    Key? key,
    required this.campo,
    required this.onCampoChange,
    required this.query,
    required this.onQueryChange,
    required this.etapa,
    required this.onEtapaChange,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Campo | Etapa | Refrescar (ajustable sin overflow)
          Row(
            children: [
              Expanded(
                child: DropdownPersonalizado(
                  items: const ['Todos', 'Lote', 'Producto'],
                  // No mostrar valor por defecto cuando el campo es 'Todos'. Mostrar placeholder 'Campo'.
                  valorSeleccionado: campo == OrdenFiltroCampo.todos
                      ? null
                      : _campoToLabel(campo),
                  hint: 'Campo',
                  dense: true,
                  isExpanded: true,
                  // Remueve icono para ahorrar espacio
                  prefixIcon: null,
                  clearable: false,
                  selectFirstWhenNull: false,
                  onChanged: (v) {
                    if (v == null) return;
                    onCampoChange(_labelToCampo(v));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownPersonalizado(
                  items: const [
                    'Todos',
                    'Corte',
                    'Costura',
                    'Estampado',
                    'Acabado',
                    'Empaque',
                  ],
                  // Si etapa es null, mostramos placeholder 'Etapa'
                  valorSeleccionado: etapa == null
                      ? null
                      : (etapa!.isEmpty
                            ? null
                            : etapa![0].toUpperCase() + etapa!.substring(1)),
                  hint: 'Etapa',
                  dense: true,
                  isExpanded: true,
                  // Remueve icono para ahorrar espacio
                  prefixIcon: null,
                  clearable: false,
                  selectFirstWhenNull: false,
                  onChanged: (v) {
                    if (v == null || v == 'Todos') {
                      onEtapaChange(null);
                    } else {
                      onEtapaChange(v.toLowerCase());
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              if (onRefresh != null)
                IconButton(
                  tooltip: 'Refrescar',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Limpiar filtros',
                onPressed: () {
                  // Restablece: Campo -> Todos (placeholder), Etapa -> null (placeholder), Buscar -> ''
                  onCampoChange(OrdenFiltroCampo.todos);
                  onEtapaChange(null);
                  onQueryChange('');
                },
                icon: const Icon(Icons.clear_all),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fila 2: Búsqueda
          Row(
            children: [
              Expanded(
                child: CampoBusqueda(
                  controller: TextEditingController(text: query),
                  hintText: 'Buscar...',
                  onChanged: onQueryChange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
