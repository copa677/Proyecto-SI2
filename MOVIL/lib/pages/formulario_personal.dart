import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:textiltech/widgets/boton_principal.dart';
import 'package:textiltech/widgets/campo_texto.dart';
// manu
import 'package:textiltech/services/auth_service.dart';
// manu

class FormularioPersonal extends StatefulWidget {
  const FormularioPersonal({Key? key}) : super(key: key);

  @override
  State<FormularioPersonal> createState() => _FormularioPersonalState();
}

class _FormularioPersonalState extends State<FormularioPersonal> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  // manu
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  // manu
  String _rol = 'Operario';
  final Map<String, bool> _permisos = {
    'Asistencia': false,
    'Reportes': false,
    'Admin': false,
    'Básico': false,
  };

  final Color azulPrincipal = const Color(0xFF1862C2);
  final Color azulBoton = const Color(0xFF1862C2);

  // manu
  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Añadir Personal',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nombre y Correo
                  CampoTexto(
                    etiqueta: 'Nombre Completo',
                    icono: Icons.person_outline,
                    controlador: _nombreController,
                    colorIcono: azulPrincipal,
                    colorBorde: azulPrincipal,
                  ),
                  const SizedBox(height: 20),
                  CampoTexto(
                    etiqueta: 'Correo Electrónico',
                    icono: Icons.email_outlined,
                    controlador: _correoController,
                    colorIcono: azulPrincipal,
                    colorBorde: azulPrincipal,
                  ),

                  // manu
                  CampoTexto(
                    etiqueta: 'Usuario',
                    icono: Icons.person_outline,
                    controlador: _usuarioController,
                    colorIcono: azulPrincipal,
                    colorBorde: azulPrincipal,
                  ),
                  CampoTexto(
                    etiqueta: 'Contraseña',
                    icono: Icons.lock_outline,
                    esContrasena: true,
                    controlador: _passwordController,
                    colorIcono: azulPrincipal,
                    colorBorde: azulPrincipal,
                  ),
                  // manu
                  const SizedBox(height: 28),
                  // Rol
                  const Text(
                    'Rol',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context).copyWith(canvasColor: Colors.white),
                    child: DropdownButtonFormField<String>(
                      value: _rol,
                      items: const [
                        DropdownMenuItem(
                          value: 'Operario',
                          child: Text('Operario'),
                        ),
                        DropdownMenuItem(
                          value: 'Supervisor',
                          child: Text('Supervisor'),
                        ),
                        DropdownMenuItem(
                          value: 'Administrador',
                          child: Text('Administrador'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _rol = value);
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: azulPrincipal,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Permisos
                  const Text(
                    'Permisos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.8,
                    children: _permisos.keys.map((permiso) {
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(permiso),
                        value: _permisos[permiso],
                        activeColor: azulPrincipal,
                        onChanged: (value) {
                          setState(() => _permisos[permiso] = value ?? false);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 36),
                  // Acciones
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black54,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BotonPrincipal(
                          texto: 'Guardar',
                          onPressed: () async {
                            // manu
                            String username = _usuarioController.text;
                            String password = _passwordController.text;
                            String email = _correoController.text;
                            String rol = _rol;

                            if (username.isEmpty ||
                                password.isEmpty ||
                                email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Por favor completa todos los campos',
                                  ),
                                ),
                              );
                              return;
                            }

                            bool success = await _authService.register(
                              username,
                              password,
                              email,
                              rol,
                            );

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Usuario registrado exitosamente',
                                  ),
                                ),
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error al registrar usuario'),
                                ),
                              );
                            }
                            // manu
                          },
                          color: azulBoton,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
