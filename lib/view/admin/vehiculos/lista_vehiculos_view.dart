import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../controller/vehiculos_controller.dart';
import '../../../model/vehiculo_model.dart';
import '../../../rutas/app_routes.dart';

class ListaVehiculosView extends StatefulWidget {
  const ListaVehiculosView({super.key});

  @override
  State<ListaVehiculosView> createState() => _ListaVehiculosViewState();
}

class _ListaVehiculosViewState extends State<ListaVehiculosView> {
  final VehiculosController _controller = VehiculosController();
  String _filtroEstado = 'Todos';
  String? _vehiculoEliminandoId;
  bool _eliminandoGlobal = false;

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
        return Icons.add_alert_sharp;
    }
  }

  void _mostrarDialogoEliminacion(BuildContext context, Vehiculo vehiculo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Eliminar Vehículo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de eliminar el vehículo?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car,
                          size: 16,
                          color: Color(0xFF2563EB)
                      ),
                      const SizedBox(width: 8),
                      Text(
                        vehiculo.placa,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vehiculo.marca} ${vehiculo.modelo} - ${vehiculo.ano}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta acción no se puede deshacer y eliminará también todos los documentos asociados.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _vehiculoEliminandoId == vehiculo.id || _eliminandoGlobal
                ? null
                : () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: (_vehiculoEliminandoId == vehiculo.id || _eliminandoGlobal)
                    ? Colors.grey
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _vehiculoEliminandoId == vehiculo.id || _eliminandoGlobal
                ? null
                : () async {
              if (mounted) {
                setState(() {
                  _vehiculoEliminandoId = vehiculo.id;
                  _eliminandoGlobal = true;
                });
              }

              try {
                final success = await _controller.eliminarVehiculo(vehiculo.id!);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (mounted) {
                  _mostrarMensajeElimacion(
                    success: success,
                    placa: vehiculo.placa,
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (mounted) {
                  _mostrarMensajeError('Error inesperado');
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _vehiculoEliminandoId = null;
                    _eliminandoGlobal = false;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.red.shade200,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _vehiculoEliminandoId == vehiculo.id
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarMensajeElimacion({required bool success, required String placa}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success
                    ? 'Vehículo $placa eliminado exitosamente'
                    : 'Error al eliminar el vehículo',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarMensajeError(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error inesperado',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Vehículos',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.adminRegistrarVehiculo);
              },
              icon: const Icon(Icons.add, size: 18),
              label: isMobile ? const SizedBox() : const Text('Nuevo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Todos', 'Activo', 'En mantenimiento', 'Fuera de servicio']
                    .map((estado) {
                  final isSelected = _filtroEstado == estado;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: FilterChip(
                      label: Text(
                        estado,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filtroEstado = estado),
                      backgroundColor: Colors.white,
                      selectedColor: estado == 'Todos'
                          ? const Color(0xFF2563EB)
                          : _getEstadoColor(estado),
                      side: BorderSide(
                        color: isSelected
                            ? _getEstadoColor(estado)
                            : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Lista
          Expanded(
            child: StreamBuilder<List<Vehiculo>>(
              stream: _controller.obtenerVehiculosStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Sin vehículos',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }

                final vehiculos = _filtroEstado == 'Todos'
                    ? snapshot.data!
                    : snapshot.data!
                    .where((v) => v.estado == _filtroEstado)
                    .toList();

                if (vehiculos.isEmpty) {
                  return Center(
                    child: Text('Sin vehículos con estado "$_filtroEstado"',
                        style: TextStyle(color: Colors.grey.shade600)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: vehiculos.length,
                  itemBuilder: (context, i) => _buildVehicleCard(
                    context,
                    vehiculos[i],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Vehiculo v) {
    final estadoColor = _getEstadoColor(v.estado);
    final estadoIcon = _getEstadoIcon(v.estado);

    // 🔄 CORRECCIÓN CLAVE: Obtener la lista de conductores y mostrar el texto adecuado
    final String conductorText;
    if (v.conductores.isEmpty) {
      conductorText = 'Sin asignar';
    } else if (v.conductores.length == 1) {
      conductorText = v.conductores.first;
    } else {
      // Mostrar el primer conductor y la cuenta de +1, o ambos si caben
      conductorText = '${v.conductores.first} (+${v.conductores.length - 1} más)';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.detalleVehiculo,
            arguments: v,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.placa,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${v.marca} ${v.modelo}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'editar') {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.detalleVehiculo,
                            arguments: v,
                          );
                        } else if (value == 'eliminar') {
                          _mostrarDialogoEliminacion(context, v);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Color(0xFF2563EB)),
                              SizedBox(width: 12),
                              Text(
                                'Editar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 12),
                              Text(
                                'Eliminar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      icon: Icon(Icons.more_vert,
                          size: 20, color: Colors.grey.shade600),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBadge(
                        Icons.calendar_today_rounded,
                        'Año',
                        v.ano.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoBadge(
                        Icons.speed_rounded,
                        'Km',
                        '${v.kilometrajeAcumulado} km',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      // 🔄 CORREGIDO: Uso de la variable conductorText
                      child: _buildInfoBadge(
                        v.conductores.length > 1
                            ? Icons.group_rounded
                            : Icons.person_rounded,
                        'Conductor(es)',
                        conductorText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Estado - CLICKEABLE PARA CAMBIAR
                GestureDetector(
                  onTap: () => _mostrarMenuCambioEstado(context, v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: estadoColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(estadoIcon, size: 14, color: estadoColor),
                        const SizedBox(width: 6),
                        Text(
                          v.estado,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: estadoColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, size: 16, color: estadoColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarMenuCambioEstado(BuildContext context, Vehiculo vehiculo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cambiar Estado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _buildOpcionEstado(
              context,
              'Activo',
              Icons.check_circle_rounded,
              const Color(0xFF10B981),
              vehiculo,
            ),
            const SizedBox(height: 12),
            _buildOpcionEstado(
              context,
              'En mantenimiento',
              Icons.build_circle_rounded,
              const Color(0xFFF59E0B),
              vehiculo,
            ),
            const SizedBox(height: 12),
            _buildOpcionEstado(
              context,
              'Fuera de servicio',
              Icons.cancel_rounded,
              const Color(0xFFEF4444),
              vehiculo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionEstado(
      BuildContext context,
      String estado,
      IconData icon,
      Color color,
      Vehiculo vehiculo,
      ) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);

        try {
          // Usamos la función del controlador para mantener la lógica centralizada
          await _controller.actualizarEstadoVehiculo(vehiculo.id!, estado);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Estado actualizado a: $estado'),
                backgroundColor: color,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('❌ Error al actualizar estado'),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              estado,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: const Color(0xFF2563EB)),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}