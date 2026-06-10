import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../controller/checklist_controller.dart';
import '../../../model/checklist_model.dart';

class HistorialChecklistView extends StatefulWidget {
  final String conductorId;
  final String vehiculoId;

  const HistorialChecklistView({
    super.key,
    required this.conductorId,
    required this.vehiculoId,
  });

  @override
  State<HistorialChecklistView> createState() => _HistorialChecklistViewState();
}

class _HistorialChecklistViewState extends State<HistorialChecklistView> {
  final ChecklistController _checklistController = ChecklistController();
  final TextEditingController _searchCtrl = TextEditingController();

  final Color _primaryColor = const Color(0xFF3B82F6);
  final Color _primaryLight = const Color(0xFFEFF6FF);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _borderColor = const Color(0xFFE2E8F0);
  final Color _successColor = const Color(0xFF10B981);
  final Color _warningColor = const Color(0xFFF59E0B);
  final Color _dangerColor = const Color(0xFFEF4444);

  String _searchQuery = '';
  String _filterEstado = 'todos';

  final Map<String, Map<String, String>> _itemsInfo = {
    'luces': {'label': 'Luces', 'icon': '💡'},
    'frenos': {'label': 'Frenos', 'icon': '🛑'},
    'llantas': {'label': 'Llantas', 'icon': '⭕'},
    'motor': {'label': 'Motor', 'icon': '🔧'},
    'liquidos': {'label': 'Niveles de Líquidos', 'icon': '🛢️'},
  };

  @override
  void initState() {
    super.initState();
    print('[HistorialView] 📋 Inicializando - Conductor: ${widget.conductorId}');
    print('[HistorialView] 🚗 Vehículo: ${widget.vehiculoId}');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Checklist> _filtrarChecklists(List<Checklist> checklists) {
    print('[HistorialView] 🔍 Total de checklists recibidos: ${checklists.length}');

    var resultado = checklists;

    // Filtrar SOLO por conductor (no por vehículo, ya que puede cambiar)
    resultado = resultado.where((c) {
      print('[HistorialView] Comparando - Conductor recibido: ${c.conductorId} vs ${widget.conductorId}');
      return c.conductorId == widget.conductorId;
    }).toList();

    print('[HistorialView] ✓ Después filtro conductor: ${resultado.length}');

    // Filtrar por estado
    if (_filterEstado != 'todos') {
      resultado = resultado.where((c) => c.estado == _filterEstado).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      resultado = resultado.where((checklist) {
        final fecha = '${checklist.fecha.day}/${checklist.fecha.month}/${checklist.fecha.year}';
        final observaciones = checklist.observaciones?.toLowerCase() ?? '';
        return fecha.contains(_searchQuery) || observaciones.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    print('[HistorialView] 📊 Checklists finales a mostrar: ${resultado.length}');
    return resultado;
  }

  void _mostrarOpciones(Checklist checklist) {
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
              'Opciones del Checklist',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.visibility_rounded, color: _primaryColor),
              ),
              title: Text(
                'Ver Detalles',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _mostrarDetalles(checklist);
              },
            ),
            const SizedBox(height: 12),
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
                'Editar Items',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _abrirEdicionItems(checklist);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.note_rounded, color: _primaryColor),
              ),
              title: Text(
                'Editar Observaciones',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _abrirEdicionObservaciones(checklist);
              },
            ),
            const SizedBox(height: 12),
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
                'Eliminar Checklist',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _dangerColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmarEliminacion(checklist);
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

  void _mostrarDetalles(Checklist checklist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Checklist'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetalleRow('Fecha', '${checklist.fecha.day}/${checklist.fecha.month}/${checklist.fecha.year}'),
              _buildDetalleRow('Hora', '${checklist.fecha.hour.toString().padLeft(2, '0')}:${checklist.fecha.minute.toString().padLeft(2, '0')}'),
              _buildDetalleRow(
                'Estado',
                checklist.estado == 'apto' ? 'Apto ✓' : 'No Apto ✗',
              ),
              const SizedBox(height: 16),
              Text(
                'Items Verificados',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...checklist.items.entries.map((entry) {
                final info = _itemsInfo[entry.key] ?? {'label': entry.key, 'icon': '•'};
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(info['icon']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          info['label']!,
                          style: TextStyle(color: _textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: entry.value ? _successColor.withOpacity(0.1) : _dangerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.value ? 'Apto' : 'No Apto',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: entry.value ? _successColor : _dangerColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (checklist.observaciones != null && checklist.observaciones!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Observaciones',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    checklist.observaciones!,
                    style: TextStyle(color: _textPrimary),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _abrirEdicionItems(Checklist checklist) {
    Map<String, bool> itemsEditados = Map.from(checklist.items);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Items del Checklist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: itemsEditados.entries.map((entry) {
                final info = _itemsInfo[entry.key] ?? {'label': entry.key, 'icon': '•'};
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(info['icon']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          info['label']!,
                          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch(
                        value: entry.value,
                        onChanged: (value) {
                          setDialogState(() {
                            itemsEditados[entry.key] = value;
                          });
                        },
                        activeColor: _successColor,
                        inactiveThumbColor: _dangerColor,
                      ),
                    ],
                  ),
                );
              }).toList(),
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
                  final todosAptos = itemsEditados.values.every((item) => item == true);
                  final nuevoEstado = todosAptos ? 'apto' : 'no_apto';

                  final checklistActualizado = checklist.copyWith(
                    items: itemsEditados,
                    estado: nuevoEstado,
                  );

                  await _checklistController.actualizarChecklist(checklistActualizado);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✓ Items y estado actualizados'),
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

  void _abrirEdicionObservaciones(Checklist checklist) {
    final obsCtrl = TextEditingController(text: checklist.observaciones ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Observaciones'),
          content: TextField(
            controller: obsCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Añade observaciones del checklist...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                  final checklistActualizado = checklist.copyWith(
                    observaciones: obsCtrl.text.isEmpty ? null : obsCtrl.text,
                  );

                  await _checklistController.actualizarChecklist(checklistActualizado);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✓ Observaciones actualizadas'),
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

  void _confirmarEliminacion(Checklist checklist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Checklist?'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${checklist.fecha.day}/${checklist.fecha.month}/${checklist.fecha.year}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _dangerColor,
                    ),
                  ),
                  Text(
                    checklist.estado == 'apto' ? 'Estado: Apto ✓' : 'Estado: No Apto ✗',
                    style: TextStyle(color: _textSecondary, fontSize: 12),
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
                await _checklistController.eliminarChecklist(checklist.id);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✓ Checklist eliminado'),
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

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
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
        title: const Text('Historial de Checklists'),
        backgroundColor: _surfaceColor,
        elevation: 0,
        foregroundColor: _textPrimary,
        centerTitle: true,
      ),
      body: Column(
        children: [
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
                hintText: 'Buscar por fecha u observaciones...',
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

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Todos', 'todos'),
                const SizedBox(width: 8),
                _buildFilterChip('✓ Apto', 'apto'),
                const SizedBox(width: 8),
                _buildFilterChip('✗ No Apto', 'no_apto'),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Toca un item para ver detalles. Presiona para opciones.',
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Checklist>>(
              stream: _checklistController.obtenerChecklistsPorConductor(widget.conductorId),
              builder: (context, snapshot) {
                print('[HistorialView] 🔄 StreamBuilder state: ${snapshot.connectionState}');

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('[HistorialView] ❌ Error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('Error al cargar', style: TextStyle(color: _textPrimary)),
                      ],
                    ),
                  );
                }

                final checklists = snapshot.data ?? [];
                print('[HistorialView] 📦 Checklists del stream: ${checklists.length}');

                final checklistsFiltrados = _filtrarChecklists(checklists);

                if (checklists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checklist_rounded, size: 48, color: _textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No hay checklists', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
                        const SizedBox(height: 8),
                        Text('Comienza a registrar checklists', style: TextStyle(color: _textSecondary)),
                      ],
                    ),
                  );
                }

                if (checklistsFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: _textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No se encontraron resultados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: checklistsFiltrados.length,
                  itemBuilder: (context, index) {
                    final checklist = checklistsFiltrados[index];
                    final fecha = checklist.fecha;
                    final fechaFormato = '${fecha.day}/${fecha.month}/${fecha.year}';
                    final horaFormato = '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

                    return GestureDetector(
                      onLongPress: () => _mostrarOpciones(checklist),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: checklist.estado == 'apto' ? _successColor.withOpacity(0.3) : _warningColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: checklist.estado == 'apto' ? _successColor.withOpacity(0.1) : _warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              checklist.estado == 'apto' ? Icons.check_circle : Icons.warning_rounded,
                              color: checklist.estado == 'apto' ? _successColor : _warningColor,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            checklist.estado == 'apto' ? 'Checklist Apto' : 'Checklist No Apto',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: checklist.estado == 'apto' ? _successColor : _warningColor,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 13, color: _textSecondary),
                                  const SizedBox(width: 4),
                                  Text(fechaFormato, style: TextStyle(color: _textSecondary, fontSize: 12)),
                                  const SizedBox(width: 12),
                                  Icon(Icons.access_time, size: 13, color: _textSecondary),
                                  const SizedBox(width: 4),
                                  Text(horaFormato, style: TextStyle(color: _textSecondary, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          trailing: GestureDetector(
                            onTap: () => _mostrarOpciones(checklist),
                            child: Icon(Icons.more_vert_rounded, color: _textSecondary),
                          ),
                          onTap: () => _mostrarDetalles(checklist),
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterEstado == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterEstado = value;
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: _primaryColor.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? _primaryColor : _borderColor,
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? _primaryColor : _textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}