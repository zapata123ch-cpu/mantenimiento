import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controller/mantenimientos_controller.dart';
import '../../../controller/vehiculos_controller.dart';
import '../../../model/mantenimiento_model.dart';

class EjecutarMantenimientoView extends StatefulWidget {
  final Mantenimiento mantenimiento;

  const EjecutarMantenimientoView({super.key, required this.mantenimiento});

  @override
  State<EjecutarMantenimientoView> createState() =>
      _EjecutarMantenimientoViewState();
}

class _EjecutarMantenimientoViewState extends State<EjecutarMantenimientoView> {
  final _formKey = GlobalKey<FormState>();
  final _serviciosCtrl = TextEditingController();
  final _piezasCtrl = TextEditingController();
  final _comentariosCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();

  bool _cargando = false;
  final MantenimientosController _mantenimientosController = MantenimientosController();
  final VehiculosController _vehiculosController = VehiculosController();

  @override
  void initState() {
    super.initState();
    _comentariosCtrl.text = widget.mantenimiento.observaciones ?? '';
    _precioCtrl.text = widget.mantenimiento.precio > 0
        ? widget.mantenimiento.precio.toStringAsFixed(2)
        : '';
  }

  Future<void> _guardarEjecucion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      widget.mantenimiento.serviciosRealizados = _serviciosCtrl.text;
      widget.mantenimiento.piezasCambiadas = _piezasCtrl.text;
      widget.mantenimiento.comentarios =
      _comentariosCtrl.text.isEmpty ? null : _comentariosCtrl.text;
      widget.mantenimiento.precio = double.tryParse(_precioCtrl.text) ?? 0.0;

      // Ejecutar mantenimiento
      await _mantenimientosController.ejecutarMantenimiento(widget.mantenimiento);

      // Cambiar estado del vehículo a "Activo"
      await _vehiculosController.actualizarEstadoVehiculo(
        widget.mantenimiento.vehiculoId,
        'Activo',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Mantenimiento ejecutado correctamente'),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al ejecutar mantenimiento: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    try {
      _serviciosCtrl.dispose();
      _piezasCtrl.dispose();
      _comentariosCtrl.dispose();
      _precioCtrl.dispose();
    } catch (e) {
      print('Error disponiendo controladores: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1E88E5);
    const Color lightGrey = Color(0xFFF5F5F5);
    const Color textDark = Color(0xFF212121);
    const Color iconBlue = Color(0xFF1976D2);

    final fechaProgramada =
    DateFormat('dd/MM/yyyy').format(widget.mantenimiento.fechaProgramada);
    final esPreventivo = widget.mantenimiento.tipoServicio == 'Preventivo';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ejecutar Mantenimiento',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: textDark,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        iconTheme: const IconThemeData(color: textDark),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // HEADER INFORMATIVO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightGrey,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      esPreventivo
                          ? Icons.shield_outlined
                          : Icons.build_circle_outlined,
                      color: iconBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mantenimiento.tipoServicio,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Programado para $fechaProgramada',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryBlue.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            widget.mantenimiento.estado,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: iconBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // FORMULARIO
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // PRECIO EDITABLE
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: lightGrey,
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: _precioCtrl,
                      style: const TextStyle(fontSize: 16, color: textDark),
                      keyboardType:
                      TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Precio del servicio',
                        labelStyle: const TextStyle(
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: 'Ej: 150.00',
                        hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'S/',
                            style: TextStyle(
                              color: iconBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el precio del servicio';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Ingresa un precio válido';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SERVICIOS REALIZADOS
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: lightGrey,
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: _serviciosCtrl,
                      style: const TextStyle(fontSize: 16, color: textDark),
                      decoration: InputDecoration(
                        labelText: 'Servicios realizados',
                        labelStyle: const TextStyle(
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: 'Describe los servicios que se realizaron',
                        hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        prefixIcon: const Icon(
                          Icons.design_services_outlined,
                          color: iconBlue,
                        ),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Campo obligatorio'
                          : null,
                      maxLines: 3,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PIEZAS CAMBIADAS
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: lightGrey,
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: _piezasCtrl,
                      style: const TextStyle(fontSize: 16, color: textDark),
                      decoration: InputDecoration(
                        labelText: 'Piezas cambiadas',
                        labelStyle: const TextStyle(
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w500,
                        ),
                        hintText:
                        'Lista las piezas que fueron reemplazadas (opcional)',
                        hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        prefixIcon: const Icon(
                          Icons.settings_outlined,
                          color: iconBlue,
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // COMENTARIOS
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: lightGrey,
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: _comentariosCtrl,
                      style: const TextStyle(fontSize: 16, color: textDark),
                      decoration: InputDecoration(
                        labelText: 'Comentarios',
                        labelStyle: const TextStyle(
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w500,
                        ),
                        hintText:
                        'Notas adicionales sobre el mantenimiento (opcional)',
                        hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        prefixIcon: const Icon(
                          Icons.note_outlined,
                          color: iconBlue,
                        ),
                      ),
                      maxLines: 4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // BOTÓN EJECUTAR
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: primaryBlue,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _cargando ? null : _guardarEjecucion,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedOpacity(
                              opacity: _cargando ? 0 : 1,
                              duration: const Duration(milliseconds: 200),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ejecutar Mantenimiento',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_cargando)
                              const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BOTÓN CANCELAR
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.3),
                        width: 2,
                      ),
                      color: Colors.white,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _cargando ? null : () => Navigator.pop(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.arrow_back_outlined,
                              color: Color(0xFF1976D2),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // INFORMACIÓN ADICIONAL
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: lightGrey,
                border: Border.all(
                  color: primaryBlue.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Al ejecutar el mantenimiento, el vehículo volverá a estado Activo.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}