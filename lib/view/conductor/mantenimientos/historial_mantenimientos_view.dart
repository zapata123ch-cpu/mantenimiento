import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controller/mantenimientos_controller.dart';
import '../../../model/mantenimiento_model.dart';
import 'ejecutar_mantenimiento_view.dart';

class HistorialMantenimientosView extends StatefulWidget {
  final String vehiculoId;
  final String conductorId;

  const HistorialMantenimientosView({
    super.key,
    required this.vehiculoId,
    required this.conductorId,
  });

  @override
  State<HistorialMantenimientosView> createState() =>
      _HistorialMantenimientosViewState();
}

class _HistorialMantenimientosViewState
    extends State<HistorialMantenimientosView> {
  final MantenimientosController _controller = MantenimientosController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtroSeleccionado = 'Todos';
  final List<String> _filtros = [
    'Todos',
    'Pendiente',
    'Aceptado',
    'Urgente',
    'Completado'
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _mostrarMenuOpciones(BuildContext context, Mantenimiento mantenimiento) {
    const Color primaryBlue = Color(0xFF1E88E5);
    const Color iconBlue = Color(0xFF1976D2);

    final bool opcionesDeshabilitadas = mantenimiento.estado == 'Completado';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              enabled: !opcionesDeshabilitadas,
              leading: Icon(
                Icons.edit_outlined,
                color: opcionesDeshabilitadas ? Colors.grey.shade400 : iconBlue,
              ),
              title: Text(
                'Editar',
                style: TextStyle(
                  color: opcionesDeshabilitadas ? Colors.grey.shade400 : null,
                ),
              ),
              onTap: opcionesDeshabilitadas
                  ? null
                  : () {
                Navigator.pop(context);
                _mostrarDialogoEditar(context, mantenimiento);
              },
            ),
            ListTile(
              enabled: !opcionesDeshabilitadas,
              leading: Icon(
                Icons.delete_outline,
                color: opcionesDeshabilitadas ? Colors.grey.shade400 : Colors.red,
              ),
              title: Text(
                'Eliminar',
                style: TextStyle(
                  color: opcionesDeshabilitadas ? Colors.grey.shade400 : null,
                ),
              ),
              onTap: opcionesDeshabilitadas
                  ? null
                  : () {
                Navigator.pop(context);
                _mostrarConfirmacionEliminar(context, mantenimiento);
              },
            ),
            if (mantenimiento.estado == 'Aceptado' ||
                mantenimiento.estado == 'Urgente')
              ListTile(
                leading: const Icon(Icons.play_arrow_outlined, color: Colors.green),
                title: const Text('Ejecutar'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EjecutarMantenimientoView(mantenimiento: mantenimiento),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEditar(
      BuildContext context, Mantenimiento mantenimiento) {
    final _formKey = GlobalKey<FormState>();
    final _descripcionCtrl =
    TextEditingController(text: mantenimiento.observaciones ?? '');
    String _tipoServicioSeleccionado = mantenimiento.tipoServicio;
    DateTime? _fechaSeleccionada = mantenimiento.fechaProgramada;

    const Color primaryBlue = Color(0xFF1E88E5);
    const Color darkBlue = Color(0xFF1565C0);
    const Color lightGrey = Color(0xFFF5F5F5);
    const Color textDark = Color(0xFF212121);
    const Color textGrey = Color(0xFF757575);
    const Color iconBlue = Color(0xFF1976D2);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: iconBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Editar Mantenimiento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo de Servicio
                  const Text(
                    'Tipo de Servicio',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      value: _tipoServicioSeleccionado,
                      items: ['Preventivo', 'Correctivo']
                          .map((tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(
                          tipo,
                          style: const TextStyle(
                            fontSize: 14,
                            color: textDark,
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _tipoServicioSeleccionado = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Fecha Programada
                  const Text(
                    'Fecha Programada',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fechaSeleccionada ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: primaryBlue,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: textDark,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _fechaSeleccionada = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: iconBlue,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _fechaSeleccionada != null
                                  ? DateFormat('dd/MM/yyyy')
                                  .format(_fechaSeleccionada!)
                                  : 'Selecciona fecha',
                              style: TextStyle(
                                fontSize: 14,
                                color: _fechaSeleccionada != null
                                    ? textDark
                                    : textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Observaciones
                  const Text(
                    'Observaciones',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descripcionCtrl,
                    maxLines: 4,
                    style: const TextStyle(
                      fontSize: 14,
                      color: textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Añade observaciones del mantenimiento...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: textGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, darkBlue],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final mantenimientoActualizado = Mantenimiento(
                      id: mantenimiento.id,
                      vehiculoId: mantenimiento.vehiculoId,
                      conductorId: mantenimiento.conductorId,
                      tipoServicio: _tipoServicioSeleccionado,
                      tipoMantenimiento: _tipoServicioSeleccionado,
                      fechaProgramada: _fechaSeleccionada!,
                      precio: mantenimiento.precio,
                      observaciones: _descripcionCtrl.text.isEmpty
                          ? null
                          : _descripcionCtrl.text,
                      estado: mantenimiento.estado,
                      serviciosRealizados: mantenimiento.serviciosRealizados,
                      piezasCambiadas: mantenimiento.piezasCambiadas,
                      comentarios: mantenimiento.comentarios,
                    );

                    _controller.guardarMantenimiento(mantenimientoActualizado).then((_) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('✅ Mantenimiento actualizado'),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }).catchError((e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red.shade600,
                        ),
                      );
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Guardar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarConfirmacionEliminar(
      BuildContext context, Mantenimiento mantenimiento) {
    const Color primaryBlue = Color(0xFF1E88E5);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Mantenimiento'),
        content: const Text(
            '¿Está seguro de que desea eliminar este registro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _controller.eliminarMantenimientoPorId(mantenimiento.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('✅ Mantenimiento eliminado'),
                    backgroundColor: Colors.green.shade400,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red.shade400,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1E88E5);
    const Color lightGrey = Color(0xFFF5F5F5);
    const Color textDark = Color(0xFF212121);
    const Color iconBlue = Color(0xFF1976D2);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de Mantenimientos',
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
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: lightGrey,
                border: Border.all(
                  color: primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (value) => setState(() {}),
                style: const TextStyle(fontSize: 16, color: textDark),
                decoration: InputDecoration(
                  hintText: 'Buscar mantenimiento...',
                  hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: const Icon(
                    Icons.search_outlined,
                    color: iconBlue,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.close_outlined,
                      color: iconBlue,
                    ),
                  )
                      : null,
                ),
              ),
            ),
          ),

          // FILTROS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
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
                          color: isSelected ? Colors.white : textDark,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _filtroSeleccionado = filtro;
                        });
                      },
                      backgroundColor: isSelected ? null : lightGrey,
                      selectedColor: primaryBlue,
                      side: BorderSide(
                        color: isSelected
                            ? primaryBlue
                            : primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // LISTA DE MANTENIMIENTOS
          Expanded(
            child: StreamBuilder<List<Mantenimiento>>(
              stream: _controller
                  .obtenerMantenimientosPorVehiculo(widget.vehiculoId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryBlue,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.build_circle_outlined,
                          size: 64,
                          color: Color(0xFFDDDDDD),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay mantenimientos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var mantenimientos = snapshot.data!
                    .where((m) => m.conductorId == widget.conductorId)
                    .toList();

                // Filtrar por estado
                if (_filtroSeleccionado != 'Todos') {
                  mantenimientos = mantenimientos
                      .where((m) => m.estado == _filtroSeleccionado)
                      .toList();
                }

                // Filtrar por búsqueda
                if (_searchCtrl.text.isNotEmpty) {
                  mantenimientos = mantenimientos
                      .where((m) =>
                  m.tipoServicio
                      .toLowerCase()
                      .contains(_searchCtrl.text.toLowerCase()) ||
                      (m.observaciones != null &&
                          m.observaciones!
                              .toLowerCase()
                              .contains(_searchCtrl.text.toLowerCase())))
                      .toList();
                }

                if (mantenimientos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.filter_alt_outlined,
                          size: 64,
                          color: Color(0xFFDDDDDD),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay resultados',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: mantenimientos.length,
                  itemBuilder: (context, index) {
                    final m = mantenimientos[index];
                    final esPreventivo = m.tipoServicio == 'Preventivo';
                    final puedeEjecutar = m.estado == 'Aceptado' || m.estado == 'Urgente';

                    return GestureDetector(
                      onTap: () => _mostrarMenuOpciones(context, m),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: esPreventivo
                                        ? const Color(0xFF1976D2)
                                        .withOpacity(0.1)
                                        : const Color(0xFFF57C00)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    esPreventivo
                                        ? Icons.shield_outlined
                                        : Icons.build_outlined,
                                    color: esPreventivo
                                        ? const Color(0xFF1976D2)
                                        : const Color(0xFFF57C00),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.tipoServicio,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd/MM/yyyy')
                                            .format(m.fechaProgramada),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF999999),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getColorEstado(m.estado)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getColorEstado(m.estado)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    m.estado,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _getColorEstado(m.estado),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (m.observaciones != null &&
                                m.observaciones!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                m.observaciones!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF666666),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '...',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: iconBlue,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  Color _getColorEstado(String estado) {
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
}