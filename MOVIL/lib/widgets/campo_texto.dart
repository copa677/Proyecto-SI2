import 'package:flutter/material.dart';

class CampoTexto extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final bool esContrasena;
  final TextEditingController? controlador;
  final Color colorIcono;
  final Color colorBorde;
  final ValueChanged<String>? onChanged;

  const CampoTexto({
    Key? key,
    required this.etiqueta,
    required this.icono,
    this.esContrasena = false,
    this.controlador,
    this.colorIcono = const Color(0xFF1862C2),
    this.colorBorde = const Color(0xFF1862C2),
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      obscureText: esContrasena,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icono, color: colorIcono),
        labelText: etiqueta,
        labelStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorBorde, width: 2),
        ),
      ),
    );
  }
}
