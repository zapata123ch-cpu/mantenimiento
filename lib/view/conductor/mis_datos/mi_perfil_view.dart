import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controller/usuarios_controller.dart';
import '../../../widgets/NotificationService.dart';

class MiPerfilView extends StatefulWidget {
  const MiPerfilView({super.key});

  @override
  State<MiPerfilView> createState() => _MiPerfilViewState();
}

class _MiPerfilViewState extends State<MiPerfilView> {
  late Future<Map<String, dynamic>?> _userDataFuture;
  final UsuariosController _usuariosController = UsuariosController();

  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _dniController;
  late TextEditingController _fechaNacimientoController;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _usuariosController.obtenerDatosUsuarioActual();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nombresController = TextEditingController();
    _apellidosController = TextEditingController();
    _emailController = TextEditingController();
    _telefonoController = TextEditingController();
    _dniController = TextEditingController();
    _fechaNacimientoController = TextEditingController();
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _dniController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }

  void _cargarDatosEnControllers(Map<String, dynamic> userData) {
    _nombresController.text = userData['nombres'] ?? '';
    _apellidosController.text = userData['apellidos'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _telefonoController.text = userData['telefono'] ?? '';
    _dniController.text = userData['dni'] ?? '';
    _fechaNacimientoController.text = userData['fechaNacimiento'] ?? '';
  }

  String? _validarCamposAntesDeGuardar() {
    // Trim todos los valores para validar
    final nombres = _nombresController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final email = _emailController.text.trim();
    final telefono = _telefonoController.text.trim();
    final dni = _dniController.text.trim();
    final fechaNacimiento = _fechaNacimientoController.text.trim();

    // Validar campos vacíos
    if (nombres.isEmpty ||
        apellidos.isEmpty ||
        email.isEmpty ||
        telefono.isEmpty ||
        dni.isEmpty ||
        fechaNacimiento.isEmpty) {
      return 'Por favor completa todos los campos';
    }

    // Nombres y apellidos solo letras y espacios (incluye acentos y ñ)
    final nombreRegex = RegExp(r'^[a-zA-ZÁÉÍÓÚáéíóúñÑ ]+$');
    if (!nombreRegex.hasMatch(nombres) || !nombreRegex.hasMatch(apellidos)) {
      return 'Los nombres y apellidos solo deben contener letras y espacios';
    }

    // DNI: 8 dígitos numéricos
    final dniRegex = RegExp(r'^[0-9]{8}$');
    if (!dniRegex.hasMatch(dni)) {
      return 'El DNI debe tener 8 dígitos numéricos';
    }

    // Teléfono: iniciar con 9 y tener 9 dígitos
    final telefonoRegex = RegExp(r'^9[0-9]{8}$');
    if (!telefonoRegex.hasMatch(telefono)) {
      return 'El teléfono debe iniciar con 9 y tener 9 dígitos';
    }

    // Email básico
    final emailRegex = RegExp(r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'El email ingresado no tiene un formato válido';
    }

    // Fecha: formato dd/MM/yyyy y fecha válida (no acepta 31/02 por ejemplo)
    try {
      final formatter = DateFormat('dd/MM/yyyy');
      // parseStrict lanza excepción si no es válida
      final parsed = formatter.parseStrict(fechaNacimiento);
      // opcional: podrías chequear rango (ej. no mayor a hoy)
      // if (parsed.isAfter(DateTime.now())) return 'La fecha de nacimiento no puede ser en el futuro';
    } catch (e) {
      return 'La fecha de nacimiento debe tener formato dd/MM/yyyy y ser válida';
    }

    return null; // todo ok
  }

  Future<void> _guardarCambios() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    // Validación previa
    final error = _validarCamposAntesDeGuardar();
    if (error != null) {
      NotificationService.showError(context, error);
      setState(() => _isSaving = false);
      return;
    }

    try {
      // Enviar valores "limpios" (trim)
      await _usuariosController.actualizarPerfilActual({
        'nombres': _nombresController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'dni': _dniController.text.trim(),
        'fechaNacimiento': _fechaNacimientoController.text.trim(),
      });

      setState(() {
        _isEditing = false;
        _userDataFuture = _usuariosController.obtenerDatosUsuarioActual();
      });

      NotificationService.showSuccess(context, 'Perfil actualizado exitosamente');
    } catch (e) {
      NotificationService.showError(context, 'Error al guardar: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1D21),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF1A1D21),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Color(0xFF475569),
                ),
              ),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF3B82F6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando perfil...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error al cargar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1D21),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            );
          }

          final userData = snapshot.data ?? {};

          if (_isEditing && _nombresController.text.isEmpty) {
            _cargarDatosEnControllers(userData);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta de perfil
                _buildProfileCard(userData),
                const SizedBox(height: 20),

                // Botón de subir documentos integrado
                _buildSubirDocumentosCard(),
                const SizedBox(height: 24),

                if (_isEditing) ...[
                  _buildEditSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ] else ...[
                  _buildInfoSections(userData),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> userData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar con diseño más limpio
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF1F5F9),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),

          // Nombre
          Text(
            '${userData['nombres'] ?? 'Usuario'} ${userData['apellidos'] ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D21),
            ),
          ),
          const SizedBox(height: 8),

          // Email
          Text(
            userData['email'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusBadge(userData['rol'] ?? 'Usuario', _getRolColor(userData['rol'])),
              const SizedBox(width: 8),
              _buildStatusBadge(userData['estado'] ?? 'Desconocido', _getEstadoColor(userData['estado'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubirDocumentosCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/perfil/subirDocumentos');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono con fondo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subir Documentos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DNI, Licencia, Certificados',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Flecha
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEditSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editar Información',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D21),
            ),
          ),
          const SizedBox(height: 20),
          _buildEditField('Nombres', _nombresController),
          _buildEditField('Apellidos', _apellidosController),
          _buildEditField('Email', _emailController, TextInputType.emailAddress),
          _buildEditField('Teléfono', _telefonoController, TextInputType.phone),
          _buildEditField('DNI', _dniController),
          _buildEditField('Fecha de Nacimiento', _fechaNacimientoController),
        ],
      ),
    );
  }

  Widget _buildInfoSections(Map<String, dynamic> userData) {
    return Column(
      children: [
        // Información Personal
        _buildInfoSection(
          'Información Personal',
          Icons.person_outline,
          [
            _buildInfoItem('Nombres', userData['nombres'] ?? 'No registrado', Icons.person),
            _buildInfoItem('Apellidos', userData['apellidos'] ?? 'No registrado', Icons.person),
            _buildInfoItem('Email', userData['email'] ?? 'No registrado', Icons.email_outlined),
            _buildInfoItem('Teléfono', userData['telefono'] ?? 'No registrado', Icons.phone_outlined),
            _buildInfoItem('DNI', userData['dni'] ?? 'No registrado', Icons.badge_outlined),
            _buildInfoItem('Fecha de Nacimiento', userData['fechaNacimiento'] ?? 'No registrado', Icons.calendar_today_outlined),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF475569)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1D21),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, [TextInputType? type]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: type ?? TextInputType.text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1D21),
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
                : const Text(
              'Guardar Cambios',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getEstadoColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'aprobado':
        return const Color(0xFF10B981);
      case 'pendiente':
        return const Color(0xFFF59E0B);
      case 'rechazado':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getRolColor(String? rol) {
    switch (rol?.toLowerCase()) {
      case 'admin':
        return const Color(0xFF8B5CF6);
      case 'usuario':
        return const Color(0xFF3B82F6);
      case 'conductor':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }
}