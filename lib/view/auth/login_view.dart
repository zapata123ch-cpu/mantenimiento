import 'package:flutter/material.dart';
import '../../controller/auth_controller.dart';
import '../../rutas/app_routes.dart';
import '../../widgets/NotificationService.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late AuthController _controller;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _cargando = false;
  bool _recordarSesion = false;

  @override
  void initState() {
    super.initState();
    _controller = AuthController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      NotificationService.showError(
          context, 'Por favor completa todos los campos');
      return;
    }

    setState(() => _cargando = true);

    try {
      // Login con la opción de recordar sesión
      final usuario = await _controller.login(
        emailController.text,
        passwordController.text,
        recordarSesion: _recordarSesion, // ✅ PASAR RECORDAR SESIÓN
      );

      if (usuario == null) {
        if (mounted) {
          NotificationService.showError(
              context, 'Error al obtener datos del usuario');
        }
        return;
      }

      if (mounted) {
        // Estado pendiente
        if (usuario.estado == 'Pendiente') {
          NotificationService.showWarning(
            context,
            'Tu cuenta está pendiente de aprobación del administrador',
          );
          return;
        }

        // Sin rol asignado
        if (usuario.rol == null || usuario.rol!.isEmpty) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text('Cuenta en Espera'),
                ],
              ),
              content: const Text(
                'Tu cuenta ha sido aprobada, pero aún estamos asignando tu rol y vehículo. El administrador te notificará pronto.',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _controller.logout();
                    Navigator.pop(context);
                  },
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
          return;
        }

        // Acceso permitido
        NotificationService.showSuccess(
          context,
          '¡Bienvenido ${usuario.nombres}!',
        );

        // Navegar según rol
        if (usuario.rol == 'Admin') {
          Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        } else if (usuario.rol == 'Conductor') {
          Navigator.pushReplacementNamed(
              context, AppRoutes.conductorDashboard);
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // HERO SECTION - Ultra Minimalista
                Column(
                  children: [
                    // Logo con efecto de profundidad
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100.withOpacity(0.6),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.blue.shade50,
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Títulos con jerarquía clara
                    const Column(
                      children: [
                        Text(
                          'Bienvenido',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Accede a tu cuenta de gestión vehicular',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 44),

                // FORM CARD - Super Limpia
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFF3F4F6),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Campo Email
                      CustomTextField(
                        label: 'Correo electrónico',
                        hintText: 'usuario@gmail.com',
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                      ),
                      const SizedBox(height: 22),

                      // Campo Contraseña
                      CustomTextField(
                        label: 'Contraseña',
                        hintText: 'Ingresa tu contraseña',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        controller: passwordController,
                      ),

                      const SizedBox(height: 16),

                      // ✅ CHECKBOX RECORDAR SESIÓN (ACTUALIZADO)
                      Row(
                        children: [
                          Checkbox(
                            value: _recordarSesion,
                            onChanged: (value) {
                              setState(() => _recordarSesion = value ?? false);
                            },
                            activeColor: Colors.blue.shade600,
                          ),
                          Text(
                            'Recordar sesión',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Botón Principal
                      CustomButton(
                        text: _cargando
                            ? 'Iniciando sesión...'
                            : 'Iniciar Sesión',
                        onPressed: _cargando ? null : _iniciarSesion,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // DIVISOR
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade200,
                        thickness: 1,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '¿Nuevo en la plataforma?',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade200,
                        thickness: 1,
                        height: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // BOTÓN SOLICITUD CUENTA
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.blue.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.blue.shade700,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 20,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Solicitar Cuenta',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // FOOTER
                Text(
                  'Sistema de Gestión Vehicular • v2.4',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}