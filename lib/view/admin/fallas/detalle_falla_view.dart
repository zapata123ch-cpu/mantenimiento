import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controller/fallas_controller.dart';
import '../../../model/falla_model.dart';

class DetalleFallaView extends StatefulWidget {
  final Falla falla;

  const DetalleFallaView({
    super.key,
    required this.falla,
  });

  @override
  State<DetalleFallaView> createState() => _DetalleFallaViewState();
}

class _DetalleFallaViewState extends State<DetalleFallaView> {
  final FallasController _controller = FallasController();
  final _comentariosCtrl = TextEditingController();
  late String _estadoSeleccionado;
  late String _nombreConductor = 'Cargando...';
  late String _placaVehiculo = 'Cargando...';
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.falla.estado;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final nombre = await _controller.obtenerNombreConductor(widget.falla.conductorId);
      final placa = await _controller.obtenerPlacaVehiculo(widget.falla.vehiculoId);

      if (mounted) {
        setState(() {
          _nombreConductor = nombre;
          _placaVehiculo = placa;
        });
      }
    } catch (e) {
      print('Error cargando datos: $e');
    }
  }

  @override
  void dispose() {
    _comentariosCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (_estadoSeleccionado == widget.falla.estado &&
        _comentariosCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hay cambios para guardar'),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await _controller.actualizarEstado(
        widget.falla.id,
        _estadoSeleccionado,
        comentarios: _comentariosCtrl.text.isNotEmpty
            ? _comentariosCtrl.text
            : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Falla actualizada correctamente'),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Detalle de Falla',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFORMACIÓN DEL REPORTE
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.blue[800],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Información del Reporte',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow('Tipo de Falla:', widget.falla.tipoFalla),
                    _buildDetailRow('Vehículo (Placa):', _placaVehiculo),
                    _buildDetailRow('Conductor:', _nombreConductor),
                    _buildDetailRow(
                      'Fecha Reportada:',
                      DateFormat('dd/MM/yyyy – HH:mm')
                          .format(widget.falla.createdAtDate),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FOTO DE LA FALLA
            if (widget.falla.fotoUrl != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.photo_camera_outlined,
                              color: Colors.blue[800],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Foto de la Falla',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.falla.fotoUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.blue[50],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                    color: Colors.blue[300],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Error al cargar imagen',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontSize: 12,
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
                ),
              ),

            const SizedBox(height: 16),

            // DESCRIPCIÓN
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: Colors.blue[800],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Descripción de la Falla',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50]?.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.falla.descripcion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ESTADO ACTUAL
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.flag_outlined,
                            color: Colors.blue[800],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Estado Actual',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _getColorPorEstado(widget.falla.estado).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getColorPorEstado(widget.falla.estado).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconPorEstado(widget.falla.estado),
                            color: _getColorPorEstado(widget.falla.estado),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.falla.estado,
                            style: TextStyle(
                              color: _getColorPorEstado(widget.falla.estado),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CAMBIAR ESTADO
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: Colors.blue[800],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Actualizar Estado',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50]?.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _estadoSeleccionado,
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.blue[800]),
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Reportada',
                            child: Text('Reportada'),
                          ),
                          DropdownMenuItem(
                            value: 'En reparación',
                            child: Text('En reparación'),
                          ),
                          DropdownMenuItem(
                            value: 'Resuelto',
                            child: Text('Resuelto'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _estadoSeleccionado = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // COMENTARIOS
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.comment_outlined,
                            color: Colors.blue[800],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Comentarios Admin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _comentariosCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe las acciones tomadas, piezas cambiadas, etc.',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.blue[50]?.withOpacity(0.3),
                      ),
                    ),
                    if (widget.falla.comentariosAdmin != null &&
                        widget.falla.comentariosAdmin!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Comentarios Anteriores:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[100]?.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.falla.comentariosAdmin!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
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
            ),

            const SizedBox(height: 24),

            // BOTÓN GUARDAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _cargando ? null : _guardarCambios,
                child: _cargando
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Guardar Cambios',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconPorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'reportada':
        return Icons.warning_amber_rounded;
      case 'en reparación':
        return Icons.build_circle_outlined;
      case 'resuelto':
        return Icons.check_circle_outlined;
      default:
        return Icons.info_outlined;
    }
  }

  Color _getColorPorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'reportada':
        return Colors.orange;
      case 'en reparación':
        return Colors.blue[800]!;
      case 'resuelto':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}