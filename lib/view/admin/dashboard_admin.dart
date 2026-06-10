import 'package:flutter/material.dart';
import '../../controller/auth_controller.dart';
import '../../rutas/app_routes.dart';

class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFE),
      body: CustomScrollView(
        slivers: [
          // AppBar moderno
          SliverAppBar(
            automaticallyImplyLeading: false,

            expandedHeight: 180,
            collapsedHeight: 80,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: const Color(0xFF111827),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Panel Administrativo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFFFAFBFE),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                    ),
                    child: const Icon(Icons.logout_rounded, size: 20),
                  ),
                  onPressed: () => _mostrarDialogoLogout(context),
                ),
              ),
            ],
          ),

          // Contenido principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con bienvenida
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Bienvenido Admin!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gestiona usuarios, vehículos y mantenimientos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Grid de opciones
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
                    children: [
                      _MenuCard(
                        icon: Icons.people_alt_rounded,
                        title: 'Usuarios',
                        subtitle: 'Aprobar y Gestionar',
                        color: const Color(0xFF6366F1),
                        gradient: const [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.adminUsuarios,
                        ),
                      ),
                      _MenuCard(
                        icon: Icons.electric_car_rounded,
                        title: 'Vehículos',
                        subtitle: 'CRUD Vehículos',
                        color: const Color(0xFF10B981),
                        gradient: const [
                          Color(0xFF10B981),
                          Color(0xFF34D399),
                        ],
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.adminVehiculos,
                        ),
                      ),
                      _MenuCard(
                        icon: Icons.build_circle_rounded,
                        title: 'Mantenimientos',
                        subtitle: 'Supervisar',
                        color: const Color(0xFFF59E0B),
                        gradient: const [
                          Color(0xFFF59E0B),
                          Color(0xFFFBBF24),
                        ],
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.adminMantenimientos,
                        ),
                      ),
                      _MenuCard(
                        icon: Icons.warning_amber_rounded,
                        title: 'Fallas',
                        subtitle: 'Gestionar Reportes',
                        color: const Color(0xFFEF4444),
                        gradient: const [
                          Color(0xFFEF4444),
                          Color(0xFFF87171),
                        ],
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.adminFallas,
                        ),
                      ),
                      _MenuCard(
                        icon: Icons.notifications_active_rounded,
                        title: 'Alertas',
                        subtitle: 'Notificaciones',
                        color: const Color(0xFF8B5CF6),
                        gradient: const [
                          Color(0xFF8B5CF6),
                          Color(0xFFA78BFA),
                        ],
                        onTap: () {
                          print("🛎 Se pulsó Notificaciones");
                          Navigator.pushNamed(
                            context,
                            AppRoutes.adminNotificaciones,
                          );
                        },
                      ),
                      _MenuCard(
                        icon: Icons.bar_chart_rounded,
                        title: 'Reportes',
                        subtitle: 'Gráficos y PDF',
                        color: const Color(0xFF0EA5E9),
                        gradient: const [
                          Color(0xFF0EA5E9),
                          Color(0xFF38BDF8),
                        ],
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.adminReportes, // esta ruta la crearemos
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade50,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade400,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '¿Estás seguro de que deseas cerrar sesión?',
                textAlign: TextAlign.center, // ✅ Aquí va
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final authController = AuthController();
                        await authController.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.login,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.red.shade500,
                        elevation: 0,
                      ),
                      child: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarSnackbarElegante(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Efectos de fondo decorativos
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}