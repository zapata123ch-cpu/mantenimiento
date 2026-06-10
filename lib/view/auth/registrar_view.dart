import 'package:flutter/material.dart';
import '../../controller/auth_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegistrarView extends StatefulWidget {
  const RegistrarView({super.key});

  @override
  State<RegistrarView> createState() => _RegistrarViewState();
}

class _RegistrarViewState extends State<RegistrarView> {
  late AuthController _controller;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _controller = AuthController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    await _controller.seleccionarFecha(context);
    setState(() {});
  }

  Future<void> _registrar() async {
    setState(() => _cargando = true);

    try {
      await _controller.registrar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cuenta creada exitosamente. Espera aprobación del administrador.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _controller.limpiar();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
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
      body: Container(
        color: const Color(0xFFFEFEFE),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 60,
            bottom: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón de retroceso personalizado
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF3F4F6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crear Nueva Cuenta',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Completa tus datos para solicitar acceso al sistema',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Formulario
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF3F4F6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF111827),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Información Personal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Nombres y Apellidos
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Nombres',
                            hintText: 'Juan Carlos',
                            prefixIcon: Icons.person_rounded,
                            controller: _controller.nombresController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Apellidos',
                            hintText: 'Pérez García',
                            prefixIcon: Icons.person_rounded,
                            controller: _controller.apellidosController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'DNI',
                      hintText: '12345678',
                      prefixIcon: Icons.badge_rounded,
                      keyboardType: TextInputType.number,
                      controller: _controller.dniController,
                    ),
                    const SizedBox(height: 16),

                    // Fecha de Nacimiento
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fecha de Nacimiento',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _seleccionarFecha(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 16),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 20,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    child: Text(
                                      _controller.fechaNacimientoController.text.isEmpty
                                          ? 'DD/MM/AAAA'
                                          : _controller.fechaNacimientoController.text,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _controller.fechaNacimientoController.text.isEmpty
                                            ? const Color(0xFF9CA3AF)
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Correo Electrónico',
                      hintText: 'usuario@gmail.com',
                      prefixIcon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      controller: _controller.emailController,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Teléfono',
                      hintText: '+51 999 999 999',
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      controller: _controller.telefonoController,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Contraseña',
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_rounded,
                      isPassword: true,
                      controller: _controller.passwordController,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Confirmar Contraseña',
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_rounded,
                      isPassword: true,
                      controller: _controller.confirmPasswordController,
                    ),
                    const SizedBox(height: 32),

                    CustomButton(
                      text: _cargando
                          ? 'Registrando...'
                          : 'Enviar Solicitud de Cuenta',
                      onPressed: !_cargando
                          ? () {
                        _registrar(); // aquí llamamos a tu función async
                      }
                          : null,
                    ),


                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _cargando ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Información importante
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFBAE6FD),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.verified_user_rounded,
                            color: Colors.blue.shade700,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Proceso de Verificación',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoItem(text: 'Tu cuenta será verificada por un administrador'),
                        _InfoItem(text: 'No podrás iniciar sesión hasta ser aprobado'),
                        _InfoItem(text: 'El administrador asignará tu rol y vehículo'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String text;

  const _InfoItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}