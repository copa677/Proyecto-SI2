import 'package:flutter/material.dart';

class DropdownPersonalizado extends StatelessWidget {
  final List<String> items;
  final String? valorSeleccionado;
  final ValueChanged<String?>? onChanged;
  final String? hint;

  // Mejoras de UX (opcionales para mantener compatibilidad)
  final bool dense;
  final bool isExpanded;
  final bool enabled;
  final bool clearable; // muestra un botón para limpiar selección
  final bool
  selectFirstWhenNull; // si true y valorSeleccionado es null, selecciona items.first
  final String? labelText; // etiqueta superior
  final IconData? prefixIcon;

  const DropdownPersonalizado({
    Key? key,
    required this.items,
    this.valorSeleccionado,
    this.onChanged,
    this.hint,
    this.dense = true,
    this.isExpanded = false,
    this.enabled = true,
    this.clearable = false,
    this.selectFirstWhenNull = true,
    this.labelText,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveValue =
        valorSeleccionado ??
        (selectFirstWhenNull && items.isNotEmpty ? items.first : null);

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white, // Color del popup del dropdown
      ),
      child: DropdownButtonFormField<String>(
        isExpanded: isExpanded,
        value: effectiveValue,
        hint: hint != null ? Text(hint!) : null,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: enabled ? onChanged : null,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: clearable && effectiveValue != null
              ? IconButton(
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.clear),
                  onPressed: onChanged == null ? null : () => onChanged!(null),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: dense ? 6 : 10,
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: dense,
          enabled: enabled,
        ),
      ),
    );
  }
}
