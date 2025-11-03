import 'package:flutter/material.dart';
import '../services/perfil_service.dart';
import '../theme/app_colors.dart';
import 'login.dart';
import '../services/auth_service.dart';

class PerfilUsuarioPage extends StatefulWidget {
  const PerfilUsuarioPage({Key? key}) : super(key: key);

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  final PerfilService _service = PerfilService();
  final AuthService _authService = AuthService();
  late Future<PerfilUsuario> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getPerfil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Perfil de usuario',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.negroTexto,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<PerfilUsuario>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final perfil = snapshot.data;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Tarjeta principal con info básica
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              // Header con avatar y nombre
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: AppColors.azulPrincipal
                                        .withOpacity(0.1),
                                    child: Text(
                                      _getInitials(perfil?.nombre ?? ''),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.azulPrincipal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          perfil?.nombre ?? '-',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.negroTexto,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.azulPrincipal
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            perfil?.estado ?? 'Estado',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.azulPrincipal,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 16),

                              // Información de rol y tipo
                              _buildInfoRow(
                                Icons.work_outline,
                                'Rol',
                                perfil?.area ?? '-',
                              ),
                              _buildInfoRow(
                                Icons.person_outline,
                                'Tipo de usuario',
                                perfil?.rol ?? '-',
                              ),

                              if (perfil != null &&
                                  perfil.email.isNotEmpty) ...[
                                _buildInfoRow(
                                  Icons.email_outlined,
                                  'Email',
                                  perfil.email,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tarjeta de información personal
                      if (_hasPersonalInfo(perfil))
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: AppColors.azulPrincipal,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Información Personal',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.negroTexto,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                if (perfil != null &&
                                    perfil.telefono.isNotEmpty)
                                  _buildInfoRow(
                                    Icons.phone_outlined,
                                    'Teléfono',
                                    perfil.telefono,
                                  ),

                                if (perfil != null &&
                                    perfil.direccion.isNotEmpty)
                                  _buildInfoRow(
                                    Icons.location_on_outlined,
                                    'Dirección',
                                    perfil.direccion,
                                  ),

                                if (perfil != null &&
                                    perfil.fechaNacimiento.isNotEmpty)
                                  _buildInfoRow(
                                    Icons.cake_outlined,
                                    'Fecha de nacimiento',
                                    _formatDate(perfil.fechaNacimiento),
                                  ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Botón de cerrar sesión
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Cerrar sesión'),
                                content: const Text('¿Deseas cerrar sesión?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Cerrar sesión'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await _authService.logout();
                              if (!mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const Login(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.azulPrincipal.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.negroTexto.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.negroTexto,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasPersonalInfo(PerfilUsuario? perfil) {
    if (perfil == null) return false;
    return (perfil.telefono.isNotEmpty ||
        perfil.direccion.isNotEmpty ||
        perfil.fechaNacimiento.isNotEmpty);
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }
}
