import 'package:flutter/material.dart';
import '../../controller/auth_controller.dart';
import '../../rutas/app_routes.dart';

class DashboardConductor extends StatelessWidget {
  const DashboardConductor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      appBar: AppBar(
        automaticallyImplyLeading: false,

        title: const Text('Dashboard Conductor'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _mostrarDialogoLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¡Bienvenido!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestiona tus recorridos y vehículo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                // Mi Perfil (Mis Datos + Documentos)
                _MenuCard(
                  icon: Icons.person_rounded,
                  title: 'Mi Perfil',
                  subtitle: 'Datos y Documentos',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.conductorPerfil,
                  ),
                ),
                // Mi Vehículo (Info + Documentos)
                _MenuCard(
                  icon: Icons.directions_car_rounded,
                  title: 'Mi Vehículo',
                  subtitle: 'Info y Documentos',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.conductorVehiculo,
                  ),
                ),
                // Recorridos (Registro + Historial)
                _MenuCard(
                  icon: Icons.route_rounded,
                  title: 'Recorridos',
                  subtitle: 'Registrar y Historial',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.conductorRecorridos,
                  ),
                ),
                // Checklist Previo
                _MenuCard(
                  icon: Icons.checklist_rounded,
                  title: 'Checklist',
                  subtitle: 'Verificación Previa',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.conductorChecklist,
                  ),
                ),
                // Mantenimiento (Programar + Ejecutar + Historial)
                _MenuCard(
                  icon: Icons.build_circle_rounded,
                  title: 'Mantenimiento',
                  subtitle: 'Gestión Completa',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.conductorMantenimientos,
                  ),
                ),
                // Fallas (Reportar + Ver Estado)
                _MenuCard(
                  icon: Icons.warning_rounded,
                  title: 'Fallas',
                  subtitle: 'Reportar y Seguimiento',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.conductorFallas,
                  ),
                ),
                // Notificaciones
                _MenuCard(
                  icon: Icons.notifications_rounded,
                  title: 'Notificaciones',
                  subtitle: 'Alertas y Avisos',
                  onTap: () {
                    print("🛎 Se pulsó Notificaciones");
                    Navigator.pushNamed(
                      context,
                      AppRoutes.conductorNotificaciones,
                    );
                  },
                ),


              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final authController = AuthController();
              await authController.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF3F4F6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue.shade600),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}