import 'package:flutter/material.dart';

class BotonPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;
  final Color color;
  final double radioBorde;
  final EdgeInsetsGeometry padding;

  const BotonPrincipal({
    Key? key,
    required this.texto,
    required this.onPressed,
    this.color = const Color(0xFF1862C2),
    this.radioBorde = 32,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radioBorde),
          ),
          padding: padding,
        ),
        onPressed: onPressed,
        child: Text(
          texto,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
