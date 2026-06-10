import 'package:flutter/material.dart';
import '../../../model/vehiculo_model.dart';
import '../../../controller/vehiculos_controller.dart';

class AsignarConductorView extends StatefulWidget {
  final Vehiculo vehiculo;

  const AsignarConductorView({
    super.key,
    required this.vehiculo,
  });

  @override
  State<AsignarConductorView> createState() => _AsignarConductorViewState();
}

class _AsignarConductorViewState extends State<AsignarConductorView> {
  // 🔄 Cambiado a obtener CONDUCTORES CON STATUS para saber si el conductor ya está asignado A OTRO vehículo
  late Future<Map<String, dynamic>> _conductoresStatusFuture;

  // Usamos el nombre completo del conductor para la selección
  String? _conductorSeleccionado;
  bool _isLoading = false;
  // **Asumiendo que tienes una instancia del controlador global o que lo instancias así**
  final VehiculosController _controller = VehiculosController();

  final Color _primaryColor = const Color(0xFF2563EB);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _successColor = const Color(0xFF10B981);
  final Color _errorColor = const Color(0xFFEF4444);
  final Color _warningColor = const Color(0xFFF59E0B);
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _borderColor = const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    // 🔄 Llamamos a la función que nos da la lista de TODOS los conductores y su estado.
    _conductoresStatusFuture = _controller.obtenerConductoresConStatus();
  }

  // 1. ASIGNAR (añadir)
  Future<void> _asignarConductor(String conductor) async {
    // La validación del límite se ha movido/consolidado en el controlador.
    // Solo validamos aquí que haya una selección
    if (_conductorSeleccionado == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await _controller.asignarConductor(
        widget.vehiculo.id ?? '',
        conductor,
      );

      if (success) {
        _mostrarSnackBar('✓ Conductor asignado exitosamente', isError: false);

        // IMPORTANTE: notificamos a la pantalla anterior que hubo un cambio.
        // El resultado `true` indica que la lista anterior debería recargar datos.
        if (mounted) {
          Navigator.pop(context, true);
        }

        // Nota: también podríamos actualizar internamente la lista si quisiéramos
        // mantenernos en esta pantalla, pero el requerimiento fue volver y recargar.
      } else {
        _mostrarSnackBar('✗ Error al asignar conductor', isError: true);
      }
    } catch (e) {
      // Capturar la excepción específica del controlador si el límite fue alcanzado
      _mostrarSnackBar('✗ Error: ${e.toString().contains('máximo de 2 conductores') ? 'El vehículo ya tiene 2 conductores.' : e.toString()}', isError: true);
    } finally {
      // Si ya hicimos pop, mounted será false y no intentaremos setState.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. DESASIGNAR (remover)
  Future<void> _desasignarConductor(String nombreConductor) async {
    setState(() => _isLoading = true);

    try {
      final success = await _controller.desasignarConductor(
        widget.vehiculo.id ?? '',
        nombreConductor,
      );

      if (success) {
        _mostrarSnackBar('✓ Conductor desasignado exitosamente', isError: false);

        // Notificamos a la pantalla anterior que hubo un cambio para que recargue.
        if (mounted) {
          Navigator.pop(context, true);
        }

      } else {
        _mostrarSnackBar('✗ Error al desasignar conductor', isError: true);
      }
    } catch (e) {
      _mostrarSnackBar('✗ Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarSnackBar(String mensaje, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 Acceder a la lista de conductores
    final List<String> conductoresAsignados = widget.vehiculo.conductores;
    final bool limiteAlcanzado = conductoresAsignados.length >= 2;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Asignar Conductores'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Card de información del vehículo (Se mantiene igual)
          // ... (Toda la Card de Vehículo hasta antes del FutureBuilder)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: conductoresAsignados.isNotEmpty ? _successColor : _warningColor,
                width: 2,
              ),
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (conductoresAsignados.isNotEmpty ? _successColor : _warningColor)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.directions_car_rounded,
                        color: conductoresAsignados.isNotEmpty ? _successColor : _warningColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vehículo a gestionar',
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.vehiculo.placa,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Etiqueta de estado de asignación
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _successColor.withOpacity(0.1),     // SIEMPRE VERDE
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _successColor,                   // SIEMPRE VERDE
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_alt_rounded,             // SIEMPRE EL MISMO ÍCONO
                            color: _successColor,                 // SIEMPRE VERDE
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${conductoresAsignados.length} Asignado(s)',   // SOLO LA CANTIDAD
                            style: TextStyle(
                              fontSize: 11,
                              color: _successColor,               // SIEMPRE VERDE
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: _borderColor),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildVehicleDetail(
                        icon: Icons.badge_rounded,
                        label: 'Marca',
                        value: widget.vehiculo.marca,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildVehicleDetail(
                        icon: Icons.directions_car_filled_rounded,
                        label: 'Modelo',
                        value: widget.vehiculo.modelo,
                      ),
                    ),
                  ],
                ),

                // 🔄 LISTA DE CONDUCTORES ASIGNADOS ACTUALES
                if (conductoresAsignados.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(height: 1, color: _borderColor),
                  const SizedBox(height: 12),
                  Text(
                    'Conductores Asignados Actualmente:',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...conductoresAsignados.map((nombre) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _successColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border:
                          Border.all(color: _successColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_pin_rounded,
                              color: _successColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                nombre,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _successColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            // BOTÓN DE DESASIGNAR INDIVIDUAL
                            SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => _desasignarConductor(nombre),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade300),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.red.shade700,
                                    ),
                                  ),
                                )
                                    : const Icon(
                                  Icons.person_remove_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
          // Fin de la Card de información del vehículo

          // Lista de conductores disponibles para asignar
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _conductoresStatusFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: _errorColor),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar conductores',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 🔄 Usamos la lista de TODOS los conductores para mostrarlos
                final List<Map<String, dynamic>> todosConductores = snapshot.data?['todos'] ?? [];
                // Nombres de los conductores actualmente asignados a ESTE vehículo.
                final List<String> asignados = widget.vehiculo.conductores.map((n) => n.trim()).toList();

                // Filtramos la lista para mostrar solo los DISPONIBLES para este vehículo.
                final List<Map<String, dynamic>> conductoresMostrados = todosConductores.where((c) {
                  final String nombre = c['nombre'];
                  final String? idVehiculo = c['idVehiculo'];

                  // 🛑 NUEVO FILTRO:
                  // 1. Excluimos si el conductor ya está asignado a ESTE vehículo (ya sale arriba)
                  if (asignados.contains(nombre.trim())) {
                    return false;
                  }

                  // 2. Incluimos si no tiene vehículo asignado (disponible)
                  // 3. Incluimos si está asignado a OTRO vehículo (Mostramos, pero no se podrá seleccionar/asignar)
                  // En el contexto de "disponibles para ASIGNAR", lo correcto es mostrar solo los que no tienen ningún vehículo.
                  // Si tu `obtenerConductoresConStatus` solo retorna los disponibles o los ocupados, este filtro es correcto.
                  // Lo ajustamos para que sean solo los REALMENTE disponibles para una nueva ASIGNACIÓN.
                  return idVehiculo == null || idVehiculo.isEmpty || idVehiculo == 'Sin asignar';
                }).toList();


                // Si no hay conductores disponibles *y* el límite no está alcanzado
                if (conductoresMostrados.isEmpty && !limiteAlcanzado) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 64, color: _borderColor),
                        const SizedBox(height: 16),
                        Text(
                          'No hay conductores disponibles',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Todos los conductores están ocupados o ya están asignados a este vehículo.',
                          style: TextStyle(
                            color: _textSecondary.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // 🛑 Lógica Clave de Corrección: Mostramos un mensaje de advertencia SOBRE la lista, no la ocultamos.
                if (limiteAlcanzado) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [

                      // 🔄 Ahora construimos la lista de disponibles, incluso si el límite está alcanzado.
                      ...conductoresMostrados.map((conductorData) {
                        final conductor = conductorData['nombre'] as String;
                        final isSelected = _conductorSeleccionado == conductor;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            // 🛑 CAMBIO: Deshabilitamos la interacción (selección) si se alcanza el límite
                            onTap: _isLoading || limiteAlcanzado
                                ? null
                                : () {
                              setState(() {
                                _conductorSeleccionado = isSelected ? null : conductor;
                              });
                            },
                            child: Opacity( // 🛑 CAMBIO: Bajamos la opacidad si el límite está alcanzado
                              opacity: limiteAlcanzado ? 0.6 : 1.0,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? _primaryColor.withOpacity(0.1) : _surfaceColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? _primaryColor : _borderColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                      : [],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: isSelected ? _primaryColor : _backgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: isSelected ? null : Border.all(color: _borderColor),
                                      ),
                                      child: Center(
                                        child: Text(
                                          conductor[0].toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : _textSecondary,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            conductor,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: _textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Disponible para asignación',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected && !limiteAlcanzado) // Deshabilitamos el ícono si hay límite
                                      Icon(
                                        Icons.radio_button_checked_rounded,
                                        color: _primaryColor,
                                        size: 24,
                                      ),
                                    if (limiteAlcanzado) // Mostramos ícono de bloqueo si hay límite
                                      Icon(
                                        Icons.lock_rounded,
                                        color: _textSecondary.withOpacity(0.5),
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }


                // 🔄 Si NO hay límite, mostramos la lista de DISPONIBLES normalmente
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: conductoresMostrados.length,
                  itemBuilder: (context, index) {
                    final conductorData = conductoresMostrados[index];
                    final conductor = conductorData['nombre'] as String;
                    final isSelected = _conductorSeleccionado == conductor;

                    // Contenido original del ListView.builder para cuando no hay límite...
                    // ... (Se mantiene igual a tu código original)
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                          setState(() {
                            // Seleccionamos si es diferente o deseleccionamos si es el mismo
                            _conductorSeleccionado = isSelected ? null : conductor;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? _primaryColor.withOpacity(0.1) : _surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? _primaryColor : _borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected ? _primaryColor : _backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected ? null : Border.all(color: _borderColor),
                                ),
                                child: Center(
                                  child: Text(
                                    conductor[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : _textSecondary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      conductor,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Disponible para asignación',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.radio_button_checked_rounded,
                                  color: _primaryColor,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Botón flotante de asignación (Se mantiene igual)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              border: Border(
                top: BorderSide(color: _borderColor, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: _borderColor),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    // Botón habilitado solo si se seleccionó un conductor y NO hay límite alcanzado
                    onPressed: _conductorSeleccionado != null &&
                        !_isLoading &&
                        !limiteAlcanzado
                        ? () => _asignarConductor(_conductorSeleccionado!)
                        : null,
                    icon: _isLoading
                        ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(
                      _isLoading
                          ? 'Cargando...'
                          : 'Asignar Conductor',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: _primaryColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar (Se mantiene igual)
  Widget _buildVehicleDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: _primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: _textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: _textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}