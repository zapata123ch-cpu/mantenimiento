import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../../../model/vehiculo_model.dart';
import '../../../controller/vehiculos_controller.dart';
import '../../../rutas/app_routes.dart';
import '../../../widgets/DocumentoViewer.dart';

class DetalleVehiculoView extends StatefulWidget {
  final Vehiculo vehiculo;

  const DetalleVehiculoView({
    super.key,
    required this.vehiculo,
  });

  @override
  State<DetalleVehiculoView> createState() => _DetalleVehiculoViewState();
}

class _DetalleVehiculoViewState extends State<DetalleVehiculoView> {
  final VehiculosController _controller = VehiculosController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  bool _isLoading = false;
  late Vehiculo _vehiculo;

  // Colores corporativos
  static const Color _primaryColor = Color(0xFF3B82F6);
  static const Color _primaryDark = Color(0xFF1E40AF);
  static const Color _accentBlue = Color(0xFF60A5FA);
  static const Color _backgroundColor = Color(0xFFFFFFFF);
  static const Color _surfaceLight = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  // Controllers
  late TextEditingController _placaController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _anoController;
  late TextEditingController _colorController;

  @override
  void initState() {
    super.initState();
    _vehiculo = widget.vehiculo;
    _initializeControllers();
  }

  void _initializeControllers() {
    _placaController = TextEditingController(text: _vehiculo.placa);
    _marcaController = TextEditingController(text: _vehiculo.marca);
    _modeloController = TextEditingController(text: _vehiculo.modelo);
    _anoController = TextEditingController(text: _vehiculo.ano.toString());
    _colorController = TextEditingController(text: _vehiculo.color);
  }

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anoController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Activo':
        return const Color(0xFF10B981);
      case 'En mantenimiento':
        return const Color(0xFFF59E0B);
      case 'Fuera de servicio':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'Activo':
        return Icons.check_circle_rounded;
      case 'En mantenimiento':
        return Icons.build_circle_rounded;
      case 'Fuera de servicio':
        return Icons.cancel_rounded;
      default:
        return Icons.help;
    }
  }

  Future<void> _refreshVehiculoData() async {
    setState(() => _isLoading = true);

    try {
      final vehiculoActualizado = await _controller.obtenerVehiculoPorId(_vehiculo.id!);
      if (vehiculoActualizado != null) {
        setState(() {
          _vehiculo = vehiculoActualizado;
          _initializeControllers();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Datos actualizados'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: _getEstadoColor(_vehiculo.estado),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al actualizar: $e')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_primaryColor, _accentBlue]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Editar Vehículo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildEditField('Placa', _placaController, Icons.directions_car_rounded, 'ABC-1234'),
              const SizedBox(height: 16),
              _buildEditField('Marca', _marcaController, Icons.business_center_rounded, 'Toyota'),
              const SizedBox(height: 16),
              _buildEditField('Modelo', _modeloController, Icons.model_training_rounded, 'Corolla'),
              const SizedBox(height: 16),
              _buildEditField('Año', _anoController, Icons.calendar_today_rounded, '2023', TextInputType.number),
              const SizedBox(height: 16),
              _buildEditField('Color', _colorController, Icons.palette_rounded, 'Rojo'),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: _borderColor),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildEditField(String label, TextEditingController controller, IconData icon, String hint, [TextInputType keyboardType = TextInputType.text]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: _primaryColor, size: 20),
            filled: true,
            fillColor: _surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final vehiculoActualizado = Vehiculo(
        id: _vehiculo.id,
        placa: _placaController.text.trim(),
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        ano: int.parse(_anoController.text),
        color: _colorController.text.trim(),

        // 🔄 CORRECCIÓN: Sustitución de 'conductor' por la lista 'conductores' y 'conductoresUIDs'
        conductores: _vehiculo.conductores,
        conductoresUIDs: _vehiculo.conductoresUIDs,

        estado: _vehiculo.estado,
        kilometrajeAcumulado: _vehiculo.kilometrajeAcumulado,
        documentosBase64: _vehiculo.documentosBase64,
        // 🆕 Nuevo campo de lista de documentos. Asumiendo que se mantiene el valor existente.
        documentos: _vehiculo.documentos,
        fechaRegistro: _vehiculo.fechaRegistro,
      );
// ... resto de la lógica de actualización

      final success = await _controller.actualizarVehiculo(_vehiculo.id!, vehiculoActualizado);

      if (success && mounted) {
        setState(() => _vehiculo = vehiculoActualizado);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Vehículo actualizado exitosamente'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    if (_placaController.text.isEmpty ||
        _marcaController.text.isEmpty ||
        _modeloController.text.isEmpty ||
        _anoController.text.isEmpty ||
        _colorController.text.isEmpty ) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos'), backgroundColor: Colors.orange),
      );
      return false;
    }

    try {
      int.parse(_anoController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Año debe ser número valido'), backgroundColor: Colors.orange),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _getEstadoColor(_vehiculo.estado);
    final estadoIcon = _getEstadoIcon(_vehiculo.estado);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: _backgroundColor,
            foregroundColor: _textPrimary,
            elevation: 0,
            actions: [
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_primaryColor)),
                )
                    : const Icon(Icons.refresh_rounded),
                onPressed: _isLoading ? null : _refreshVehiculoData,
                tooltip: 'Actualizar datos',
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [estadoColor.withOpacity(0.9), estadoColor.withOpacity(0.7)],
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_vehiculo.placa, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                              const SizedBox(height: 4),
                              Text('${_vehiculo.marca} ${_vehiculo.modelo}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _borderColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: estadoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(estadoIcon, color: estadoColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Estado del Vehículo', style: TextStyle(fontSize: 14, color: _textSecondary, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(_vehiculo.estado, style: TextStyle(fontSize: 18, color: _textPrimary, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: estadoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: estadoColor.withOpacity(0.3)),
                          ),
                          child: Text('${_vehiculo.kilometrajeAcumulado} km', style: TextStyle(fontSize: 14, color: estadoColor, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                  const SizedBox(height: 32),
                  // Documentos
                  if (_vehiculo.documentosBase64 != null && _vehiculo.documentosBase64!.isNotEmpty) ...[
                    _buildDocumentosSection(),
                    const SizedBox(height: 32),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: _borderColor),
                            foregroundColor: _textPrimary,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Volver', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _showEditDialog,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Editar', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () {
                        Navigator.pushNamed(context, AppRoutes.asignarConductor, arguments: _vehiculo);
                      },
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Asignar Conductor'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: _getEstadoColor(_vehiculo.estado), width: 2),
                        foregroundColor: _getEstadoColor(_vehiculo.estado),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentosSection() {    final tiposDocumentos = ['SOAT', 'TIV', 'CITV', 'TUC'];

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _surfaceLight,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _borderColor, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_primaryColor, _accentBlue]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Documentos del Vehículo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Mostrar todos los tipos de documentos, cargados o vacíos
        ...tiposDocumentos.map((tipo) {
          final url = _vehiculo.documentosBase64?[tipo];
          return url != null && url.isNotEmpty
              ? _buildDocumentoItem(tipo, url)
              : _buildEspacioSubirDocumento(tipo);
        }),
      ],
    ),
  );
  }



  Widget _buildDocumentoItem(String tipo, String url) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFDFEAF8), Color(0xFFE0E7FF)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: _primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tipo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
                const SizedBox(height: 2),
                Text('Documento cargado', style: TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Row(
            children: [
              // 👁️ VER DOCUMENTO
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentoViewer(
                        url: url,
                        titulo: tipo,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.visibility_rounded, color: _primaryColor, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              // ✏️ EDITAR DOCUMENTO
              GestureDetector(
                onTap: () => _showEditDocumentoDialog(tipo),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Color(0xFFF59E0B), size: 20),
                ),
              ),
              const SizedBox(width: 8),
              // 🗑️ ELIMINAR DOCUMENTO
              GestureDetector(
                onTap: () => _showEliminarDocumentoDialog(tipo),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget para mostrar espacio vacío para subir documento
  Widget _buildEspacioSubirDocumento(String tipo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 2, style: BorderStyle.solid),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor, width: 1),
            ),
            child: Icon(Icons.add_rounded, color: _textSecondary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tipo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
                const SizedBox(height: 2),
                Text('Toca para subir documento', style: TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          // ➕ SUBIR DOCUMENTO
          GestureDetector(
            onTap: () => _seleccionarYSubirDocumento(tipo),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.upload_rounded, color: _primaryColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// Diálogo para editar documento
  void _showEditDocumentoDialog(String tipoDocumento) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Color(0xFFF59E0B), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Editar $tipoDocumento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Selecciona un nuevo archivo para reemplazar este documento',
                style: TextStyle(fontSize: 14, color: _textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: _borderColor),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.pop(context);
                        _seleccionarYActualizarDocumento(tipoDocumento);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Seleccionar', style: TextStyle(fontWeight: FontWeight.w600)),
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

  /// Diálogo para eliminar documento
  void _showEliminarDocumentoDialog(String tipoDocumento) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Eliminar $tipoDocumento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '¿Estás seguro de que deseas eliminar este documento? Podrás subir uno nuevo después.',
                style: TextStyle(fontSize: 14, color: _textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: _borderColor),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.pop(context);
                        _eliminarDocumento(tipoDocumento);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Future<void> _seleccionarYActualizarDocumento(String tipoDocumento) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);

        setState(() => _isLoading = true);

        final success = await _controller.actualizarDocumento(
          _vehiculo.id!,
          _vehiculo.placa,
          tipoDocumento,
          file,
        );

        if (success && mounted) {
          await _refreshVehiculoData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Documento actualizado exitosamente'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al actualizar el documento'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Solo se permiten archivos PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Seleccionar y subir documento nuevo (SOLO PDF)
  Future<void> _seleccionarYSubirDocumento(String tipoDocumento) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);

        setState(() => _isLoading = true);

        final success = await _controller.actualizarDocumento(
          _vehiculo.id!,
          _vehiculo.placa,
          tipoDocumento,
          file,
        );

        if (success && mounted) {
          await _refreshVehiculoData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Documento subido exitosamente'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al subir el documento'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Solo se permiten archivos PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }




  /// Eliminar documento
  Future<void> _eliminarDocumento(String tipoDocumento) async {
    setState(() => _isLoading = true);

    try {
      final success = await _controller.eliminarDocumentoVehiculo(
        _vehiculo.id!,
        _vehiculo.placa,
        tipoDocumento,
      );

      if (success && mounted) {
        await _refreshVehiculoData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Documento eliminado exitosamente'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Widget _buildInfoSection() {
    // Función helper para construir el texto de los conductores (adaptado de la corrección anterior)
    String _getConductorText() {
      final List<String> conductores = _vehiculo.conductores;
      final int count = conductores.length;

      if (count == 0) {
        return 'Sin asignar';
      } else if (count == 1) {
        return conductores.first;
      } else {
        // Muestra el primero y la cuenta de los demás
        return '${conductores.first} (+${count - 1} más)';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Sección 1: Detalles del Vehículo ---
        _buildInfoCard(
            'Información General',
            Icons.info_rounded,
            [
              ('Marca', _vehiculo.marca),
              ('Modelo', _vehiculo.modelo),
              ('Año', _vehiculo.ano.toString()),
              ('Color', _vehiculo.color),
            ]
        ),
        const SizedBox(height: 20),

        // --- Sección 2: Operación y Mantenimiento ---
        _buildInfoCard(
            'Información Operativa',
            Icons.settings_rounded,
            [
              ('Conductor(es)', _getConductorText()),
              ('Kilometraje', '${_vehiculo.kilometrajeAcumulado} km'),
            ]
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<(String, String)> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: _primaryColor),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => _buildInfoItem(item.$1, item.$2)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, color: _textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, color: _textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
