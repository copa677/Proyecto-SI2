import 'package:flutter/material.dart';
import 'package:textiltech/widgets/boton_principal.dart';
import 'package:textiltech/widgets/campo_texto.dart';

class OlvidoContrasena extends StatefulWidget {
  const OlvidoContrasena({Key? key}) : super(key: key);

  @override
  State<OlvidoContrasena> createState() => _OlvidoContrasenaState();
}

class _OlvidoContrasenaState extends State<OlvidoContrasena> {
  final TextEditingController _correoController = TextEditingController();
  final Color azulPrincipal = const Color(0xFF1862C2);
  final Color azulBoton = const Color(0xFF1862C2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Recuperar Contraseña',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingresa tu correo electrónico y te enviaremos instrucciones para restablecer tu contraseña.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  CampoTexto(
                    etiqueta: 'Correo Electrónico',
                    icono: Icons.email_outlined,
                    controlador: _correoController,
                    colorIcono: azulPrincipal,
                    colorBorde: azulPrincipal,
                  ),
                  const SizedBox(height: 32),
                  BotonPrincipal(
                    texto: 'Enviar instrucciones',
                    onPressed: () {
                      // Aquí iría la lógica para enviar el correo
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Si el correo existe, se enviarán instrucciones.')),
                      );
                    },
                    color: azulBoton,
                  ),
                  const SizedBox(height: 32),                 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
