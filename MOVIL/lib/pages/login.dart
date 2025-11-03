import 'pagina_principal.dart';
import 'package:textiltech/pages/olvido_contrasena.dart';
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
