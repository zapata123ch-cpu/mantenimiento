import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controller/mantenimientos_controller.dart';
import '../../../controller/vehiculos_controller.dart';
import '../../../model/mantenimiento_model.dart';

class SupervisarMantenimientosView extends StatefulWidget {
  const SupervisarMantenimientosView({super.key});

  @override
  State<SupervisarMantenimientosView> createState() =>
      _SupervisarMantenimientosViewState();
}

class _SupervisarMantenimientosViewState
    extends State<SupervisarMantenimientosView> {
  final MantenimientosController _mantenimientosCtrl = MantenimientosController();
  final VehiculosController _vehiculosCtrl = VehiculosController();

  String _filtroSeleccionado = 'Todos';
  final List<String> _filtros = [
    'Todos',
    'Pendiente',
    'Aceptado',
    'Urgente',
    'Completado'
  ];

  // Altura fija para el widget de estado y para el botón eliminar (para que coincidan)
  final double _estadoWidgetHeight = 36;

  // CACHÉ - Se carga una sola vez
  final Map<String, String> _nombresConductores = {};
  final Map<String, String> _placasVehiculos = {};
  bool _datosYaCargados = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Supervisión de Mantenimientos',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onBackground,
      ),
      body: Column(
        children: [
          // SECCIÓN DE FILTROS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.grey[50],
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrar por estado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filtros.map((filtro) {
                      final isSelected = _filtroSeleccionado == filtro;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            filtro,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _filtroSeleccionado = filtro;
                            });
                          },
                          backgroundColor: isSelected ? null : colorScheme.surface,
                          selectedColor: _getColorPorEstado(filtro),
                          side: BorderSide(
                            color: isSelected
                                ? _getColorPorEstado(filtro)
                                : colorScheme.outline.withOpacity(0.3),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // LISTA DE MANTENIMIENTOS
          Expanded(
            child: StreamBuilder<List<Mantenimiento>>(
              stream: _mantenimientosCtrl.obtenerTodosMantenimientos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando mantenimientos...',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.build_circle_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay mantenimientos',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allMantenimientos = snapshot.data!;

                // ✅ CARGAR DATOS SOLO UNA VEZ
                if (!_datosYaCargados) {
                  _cargarNombresConductoresYPlacas(allMantenimientos);
                  _datosYaCargados = true;
                }

                final mantenimientos = _filtroSeleccionado == 'Todos'
                    ? allMantenimientos
                    : allMantenimientos
                    .where((m) => m.estado == _filtroSeleccionado)
                    .toList();

                if (mantenimientos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_alt_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay mantenimientos en estado $_filtroSeleccionado',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: mantenimientos.length,
                  itemBuilder: (context, index) {
                    final mant = mantenimientos[index];
                    final urgente = mant.estado == 'Urgente';
                    final nombreConductor = _nombresConductores[mant.conductorId] ?? 'Cargando...';
                    final placaVehiculo = _placasVehiculos[mant.vehiculoId] ?? 'Cargando...';

                    // Nota: el botón eliminar NO se deshabilita en ninguna condición
                    final bool eliminarDeshabilitado = false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: urgente
                            ? Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        )
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _verDetalles(mant, nombreConductor, placaVehiculo),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ENCABEZADO
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mant.tipoServicio,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          _buildInfoRow(
                                            Icons.directions_car_outlined,
                                            'Vehículo: $placaVehiculo',
                                          ),
                                          const SizedBox(height: 4),
                                          _buildInfoRow(
                                            Icons.person_outline,
                                            'Conductor: $nombreConductor',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Aquí mostramos el contenedor de estado y al lado el icono de eliminar,
                                    // ambos con la misma altura (_estadoWidgetHeight)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            // Contenedor de estado con altura fija
                                            Container(
                                              height: _estadoWidgetHeight,
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: _getColorPorEstado(mant.estado).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _getColorPorEstado(mant.estado).withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: ConstrainedBox(
                                                constraints: const BoxConstraints(minWidth: 60),
                                                child: Text(
                                                  mant.estado,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getColorPorEstado(mant.estado),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 8),

                                            // Botón eliminar con misma altura visual que el estado
                                            SizedBox(
                                              height: _estadoWidgetHeight,
                                              width: 44,
                                              child: ElevatedButton(
                                                // Siempre habilitado
                                                onPressed: () => _confirmarYEliminarMantenimiento(mant.id),
                                                style: ButtonStyle(
                                                  minimumSize: MaterialStateProperty.all(Size(44, _estadoWidgetHeight)),
                                                  padding: MaterialStateProperty.all(EdgeInsets.zero),
                                                  backgroundColor:
                                                  MaterialStateProperty.resolveWith<Color?>((states) {
                                                    // mantener el aspecto habitual; si quieres cambiar colores según estado puedes hacerlo aquí
                                                    return Colors.red.shade50;
                                                  }),
                                                  foregroundColor:
                                                  MaterialStateProperty.resolveWith<Color?>((states) {
                                                    return Colors.red.shade600;
                                                  }),
                                                  shape: MaterialStateProperty.all(
                                                    RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                  ),
                                                  elevation: MaterialStateProperty.all(0),
                                                ),
                                                child: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // si quieres mostrar algún texto o tooltip debajo, puedes añadirlo aquí
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // INFORMACIÓN DETALLADA
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildInfoCard(
                                        Icons.calendar_today_outlined,
                                        'Fecha Prog.',
                                        DateFormat('dd/MM/yyyy').format(mant.fechaProgramada),
                                      ),
                                      _buildInfoCard(
                                        Icons.attach_money_outlined,
                                        'Precio',
                                        '\$${mant.precio.toStringAsFixed(0)}'.replaceAll('.0', '.00'),
                                      ),
                                    ],
                                  ),
                                ),

                                // OBSERVACIONES
                                if (mant.observaciones != null && mant.observaciones!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.primary.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.note_outlined,
                                              size: 16,
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Observaciones',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          mant.observaciones!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: colorScheme.onSurface.withOpacity(0.8),
                                            height: 1.4,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // BOTONES DE ACCIÓN
                                if (mant.estado == 'Pendiente') ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text(
                                            'Aceptar',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.green,
                                            side: BorderSide(color: Colors.green.withOpacity(0.3)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () => _actualizarEstado(mant.id, 'Aceptado', mant.vehiculoId),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.warning_amber_outlined, size: 16),
                                          label: const Text(
                                            'Urgente',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.orange,
                                            side: BorderSide(color: Colors.orange.withOpacity(0.3)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () => _actualizarEstado(mant.id, 'Urgente', mant.vehiculoId, esUrgente: true),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (mant.estado == 'Aceptado' || mant.estado == 'Urgente') ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.edit_outlined, size: 16),
                                          label: const Text(
                                            'Cambiar a Aceptado',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                            side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: mant.estado == 'Aceptado'
                                              ? null
                                              : () => _actualizarEstado(mant.id, 'Aceptado', mant.vehiculoId),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.edit_outlined, size: 16),
                                          label: const Text(
                                            'Cambiar a Urgente',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.orange,
                                            side: BorderSide(color: Colors.orange.withOpacity(0.3)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: mant.estado == 'Urgente'
                                              ? null
                                              : () => _actualizarEstado(mant.id, 'Urgente', mant.vehiculoId, esUrgente: true),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (mant.estado == 'Completado') ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Completado',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (mant.fechaEjecucion != null)
                                                Text(
                                                  'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(mant.fechaEjecucion!)}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.green.withOpacity(0.8),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Confirmar y eliminar mantenimiento llamando al controlador
  Future<void> _confirmarYEliminarMantenimiento(String mantenimientoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mantenimiento'),
        content: const Text('¿Estás seguro de eliminar este mantenimiento? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmar ?? false) {
      try {
        await _mantenimientosCtrl.eliminarMantenimientoPorId(mantenimientoId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Mantenimiento eliminado'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
        // El stream debe reflejar la eliminación automáticamente; no hace falta forzar reload.
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al eliminar: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  // ✅ CARGAR DATOS UNA SOLA VEZ
  void _cargarNombresConductoresYPlacas(List<Mantenimiento> mantenimientos) async {
    for (final mant in mantenimientos) {
      // Cargar nombre conductor
      if (!_nombresConductores.containsKey(mant.conductorId)) {
        final nombre = await _mantenimientosCtrl.obtenerNombreConductor(mant.conductorId);
        if (nombre != null && mounted) {
          setState(() {
            _nombresConductores[mant.conductorId] = nombre;
          });
        }
      }

      // Cargar placa vehículo
      if (!_placasVehiculos.containsKey(mant.vehiculoId)) {
        final placa = await _mantenimientosCtrl.obtenerPlacaVehiculo(mant.vehiculoId);
        if (placa != null && mounted) {
          setState(() {
            _placasVehiculos[mant.vehiculoId] = placa;
          });
        }
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getColorPorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange;
      case 'Aceptado':
        return Colors.blue;
      case 'Urgente':
        return Colors.red;
      case 'Completado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ✅ ACTUALIZAR ESTADO + CAMBIAR VEHÍCULO A "En mantenimiento" SI ES URGENTE
  Future<void> _actualizarEstado(
      String mantId,
      String nuevoEstado,
      String vehiculoId, {
        bool esUrgente = false,
      }) async {
    try {
      // 1️⃣ Actualizar mantenimiento
      await _mantenimientosCtrl.actualizarEstado(mantId, nuevoEstado);

      // 2️⃣ Si es urgente, cambiar vehículo a "En mantenimiento"
      if (esUrgente) {
        await _vehiculosCtrl.actualizarEstadoVehiculo(vehiculoId, 'En mantenimiento');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Estado actualizado a $nuevoEstado${esUrgente ? ' - Vehículo en mantenimiento' : ''}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _verDetalles(Mantenimiento mant, String nombreConductor, String placaVehiculo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        mant.tipoServicio,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getColorPorEstado(mant.estado).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getColorPorEstado(mant.estado).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        mant.estado,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getColorPorEstado(mant.estado),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailItem(Icons.directions_car_outlined, 'Vehículo', placaVehiculo),
                _buildDetailItem(Icons.person_outline, 'Conductor', nombreConductor),
                _buildDetailItem(
                  Icons.calendar_today_outlined,
                  'Fecha Programada',
                  DateFormat('dd/MM/yyyy').format(mant.fechaProgramada),
                ),
                _buildDetailItem(
                  Icons.attach_money_outlined,
                  'Precio del Servicio',
                  '\$${mant.precio.toStringAsFixed(2)}',
                ),
                if (mant.observaciones != null && mant.observaciones!.isNotEmpty)
                  _buildDetailItem(Icons.note_outlined, 'Observaciones', mant.observaciones!),
                if (mant.fechaEjecucion != null)
                  _buildDetailItem(
                    Icons.check_circle_outlined,
                    'Fecha Ejecución',
                    DateFormat('dd/MM/yyyy HH:mm').format(mant.fechaEjecucion!),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}