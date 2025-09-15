import 'pagina_principal.dart';
import 'package:textiltech/pages/olvido_contrasena.dart';
import 'package:textiltech/pages/formulario_personal.dart';
import 'package:flutter/material.dart';
import 'package:textiltech/widgets/boton_principal.dart';
import 'package:textiltech/widgets/campo_texto.dart';
import 'package:textiltech/services/auth_service.dart';

final AuthService _authService = AuthService();

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... resto del código igual
    final Color azulPrincipal = const Color(0xFF1862C2);
    final Color azulBoton = const Color(0xFF1862C2);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
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
                children: [
                  Image.asset('assets/login.png', height: 100),
                  SizedBox(height: 8),
                  Text(
                    'Sistema de Manufactura de Textiles',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 32),
                  CampoTexto(
                    etiqueta: 'Usuario',
                    icono: Icons.person_outline,
                    colorIcono: azulPrincipal,
                    colorBorde: azulPrincipal,
                    controlador: usernameController, // manu
                  ),
                  SizedBox(height: 16),
                  CampoTexto(
                    etiqueta: 'Contraseña',
                    icono: Icons.lock_outline,
                    esContrasena: true,
                    colorIcono: azulPrincipal,
                    colorBorde: azulPrincipal,
                    controlador: passwordController, // manu
                  ),
                  SizedBox(height: 16),
                  Theme(
                    data: Theme.of(context).copyWith(canvasColor: Colors.white),
                    child: DropdownButtonFormField<String>(
                      value: 'Administrador',
                      items: [
                        DropdownMenuItem(
                          value: 'Administrador',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, color: azulPrincipal),
                              SizedBox(width: 8),
                              Text('Administrador'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Supervisor',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, color: azulPrincipal),
                              SizedBox(width: 8),
                              Text('Supervisor'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Personal',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, color: azulPrincipal),
                              SizedBox(width: 8),
                              Text('Personal'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {},
                      decoration: InputDecoration(
                        labelText: 'Rol',
                        labelStyle: TextStyle(color: azulPrincipal),
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
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // manu
                  BotonPrincipal(
                    texto: 'Iniciar sesión',
                    onPressed: () async {
                      String username = usernameController.text;
                      String password = passwordController.text;

                      bool success = await _authService.login(
                        username,
                        password,
                      );
                      if (success) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const PaginaPrincipal(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Credenciales incorrectas'),
                          ),
                        );
                      }
                    },
                    color: azulBoton,
                  ),
                  // manu
                  SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const OlvidoContrasena(),
                            ),
                          );
                        },
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: Color(0xFF1862C2),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Abriendo registro...'),
                            ),
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const FormularioPersonal(),
                            ),
                          );
                        },
                        child: Text(
                          'Crear nueva cuenta',
                          style: TextStyle(
                            color: azulPrincipal,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
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
