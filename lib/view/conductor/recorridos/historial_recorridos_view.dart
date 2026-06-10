import 'package:flutter/material.dart';
import '../../../controller/recorridos_controller.dart';
import '../../../model/recorrido_model.dart';

class HistorialRecorridosView extends StatefulWidget {
  final String conductorId;
  final String vehiculoId;

  const HistorialRecorridosView({
    super.key,
    required this.conductorId,
    required this.vehiculoId,
  });

  @override
  State<HistorialRecorridosView> createState() => _HistorialRecorridosViewState();
}

class _HistorialRecorridosViewState extends State<HistorialRecorridosView> {
  final RecorridoController _recorridoController = RecorridoController();
  final TextEditingController _searchCtrl = TextEditingController();

  // Colores
  final Color _primaryColor = const Color(0xFF3B82F6);
  final Color _primaryLight = const Color(0xFFEFF6FF);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _borderColor = const Color(0xFFE2E8F0);
  final Color _successColor = const Color(0xFF10B981);
  final Color _dangerColor = const Color(0xFFEF4444);

  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Filtrar recorridos según búsqueda
  List<Recorrido> _filtrarRecorridos(List<Recorrido> recorridos) {
    if (_searchQuery.isEmpty) {
      return recorridos;
    }

    return recorridos.where((recorrido) {
      final kmInicio = recorrido.kmInicial.toString();
      final kmFin = recorrido.kmFinal.toString();
      final distancia = recorrido.distancia.toString();
      final fecha = '${recorrido.fecha.day}/${recorrido.fecha.month}/${recorrido.fecha.year}';
      final observaciones = recorrido.observaciones?.toLowerCase() ?? '';

      return kmInicio.contains(_searchQuery) ||
          kmFin.contains(_searchQuery) ||
          distancia.contains(_searchQuery) ||
          fecha.contains(_searchQuery) ||
          observaciones.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Mostrar opciones (editar/eliminar)
  void _mostrarOpciones(Recorrido recorrido) {
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
            Text(
              'Opciones del Recorrido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            // Opción: Editar
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_rounded, color: _primaryColor),
              ),
              title: Text(
                'Editar Recorrido',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _abrirFormularioEdicion(recorrido);
              },
            ),
            const SizedBox(height: 12),
            // Opción: Eliminar
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _dangerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_rounded, color: _dangerColor),
              ),
              title: Text(
                'Eliminar Recorrido',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _dangerColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmarEliminacion(recorrido);
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textSecondary,
                side: BorderSide(color: _borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  // Formulario de edición
  void _abrirFormularioEdicion(Recorrido recorrido) {
    final kmInicialCtrl = TextEditingController(text: recorrido.kmInicial.toString());
    final kmFinalCtrl = TextEditingController(text: recorrido.kmFinal.toString());
    final observacionesCtrl = TextEditingController(text: recorrido.observaciones ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Recorrido'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: kmInicialCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Km Inicial',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: kmFinalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Km Final',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: observacionesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Observaciones',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                setDialogState(() => isLoading = true);
                try {
                  final kmInicial = int.parse(kmInicialCtrl.text);
                  final kmFinal = int.parse(kmFinalCtrl.text);

                  if (kmFinal <= kmInicial) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Km Final debe ser mayor que Km Inicial'),
                        backgroundColor: _dangerColor,
                      ),
                    );
                    setDialogState(() => isLoading = false);
                    return;
                  }

                  final distancia = kmFinal - kmInicial;

                  final recorridoActualizado = Recorrido(
                    id: recorrido.id,
                    conductorId: recorrido.conductorId,
                    vehiculoId: recorrido.vehiculoId,
                    kmInicial: kmInicial,
                    kmFinal: kmFinal,
                    distancia: distancia,
                    observaciones: observacionesCtrl.text.isEmpty ? null : observacionesCtrl.text,
                    fecha: recorrido.fecha,
                  );

                  await _recorridoController.actualizarRecorrido(recorridoActualizado);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✓ Recorrido actualizado'),
                        backgroundColor: _successColor,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: _dangerColor,
                    ),
                  );
                }
                setDialogState(() => isLoading = false);
              },
              child: isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // Confirmar eliminación
  void _confirmarEliminacion(Recorrido recorrido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Recorrido?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(color: _textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '${recorrido.distancia} km',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _dangerColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${recorrido.kmInicial} → ${recorrido.kmFinal}',
                    style: TextStyle(color: _textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _dangerColor),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _recorridoController.eliminarRecorrido(recorrido.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✓ Recorrido eliminado'),
                      backgroundColor: _successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: _dangerColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Historial de Recorridos'),
        backgroundColor: _surfaceColor,
        elevation: 0,
        foregroundColor: _textPrimary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: _surfaceColor,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por km, fecha u observaciones...',
                prefixIcon: Icon(Icons.search, color: _primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: _textSecondary),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Descripción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Consulta histórica de todos los recorridos registrados. Toca un recorrido para editar o eliminar.',
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
                height: 1.5,
              ),
            ),
          ),
          // Lista de recorridos
          Expanded(
            child: StreamBuilder<List<Recorrido>>(
              stream: _recorridoController.obtenerRecorridosPorConductor(widget.conductorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('Error al cargar recorridos', style: TextStyle(color: _textPrimary)),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(color: _textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final recorridos = snapshot.data ?? [];
                final recorridosFiltrados = _filtrarRecorridos(recorridos);

                if (recorridos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.route_outlined, size: 48, color: _textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No hay recorridos registrados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
                        const SizedBox(height: 8),
                        Text('Comienza a registrar recorridos para verlos aquí', style: TextStyle(color: _textSecondary)),
                      ],
                    ),
                  );
                }

                if (recorridosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: _textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No se encontraron coincidencias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
                        const SizedBox(height: 8),
                        Text('Intenta con otros términos de búsqueda', style: TextStyle(color: _textSecondary)),
                      ],
                    ),
                  );
                }

                // Calcular totales
                int totalKm = 0;
                int totalRecorridos = recorridosFiltrados.length;
                for (var recorrido in recorridosFiltrados) {
                  totalKm += recorrido.distancia;
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recorridosFiltrados.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total de Recorridos', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                                    const SizedBox(height: 4),
                                    Text(totalRecorridos.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Distancia Total', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                                    const SizedBox(height: 4),
                                    Text('$totalKm km', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    final recorrido = recorridosFiltrados[index - 1];
                    final fecha = recorrido.fecha;
                    final fechaFormato = '${fecha.day}/${fecha.month}/${fecha.year}';
                    final horaFormato = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

                    return GestureDetector(
                      onLongPress: () => _mostrarOpciones(recorrido),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Encabezado con distancia
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Text(
                                    '${recorrido.distancia} km',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green.shade600),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _mostrarOpciones(recorrido),
                                  child: Icon(Icons.more_vert_rounded, color: _textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Información de km
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Km Inicial', style: TextStyle(fontSize: 12, color: _textSecondary)),
                                      const SizedBox(height: 2),
                                      Text('${recorrido.kmInicial} km', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
                                    ],
                                  ),
                                ),
                                Container(width: 1, height: 40, color: _borderColor),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Km Final', style: TextStyle(fontSize: 12, color: _textSecondary)),
                                      const SizedBox(height: 2),
                                      Text('${recorrido.kmFinal} km', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Fecha y hora
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: _textSecondary),
                                const SizedBox(width: 6),
                                Text(fechaFormato, style: TextStyle(fontSize: 13, color: _textSecondary)),
                                const SizedBox(width: 12),
                                Icon(Icons.access_time, size: 16, color: _textSecondary),
                                const SizedBox(width: 6),
                                Text(horaFormato, style: TextStyle(fontSize: 13, color: _textSecondary)),
                              ],
                            ),
                            if (recorrido.observaciones != null && recorrido.observaciones!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Observaciones', style: TextStyle(fontSize: 12, color: _primaryColor, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(recorrido.observaciones!, style: TextStyle(fontSize: 13, color: _textPrimary)),
                                  ],
                                ),
                              ),
                            ],
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
}