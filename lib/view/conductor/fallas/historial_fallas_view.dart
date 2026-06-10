import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controller/fallas_controller.dart';
import '../../../model/falla_model.dart';

class HistorialFallasView extends StatefulWidget {
  final String conductorId;

  const HistorialFallasView({super.key, required this.conductorId});

  @override
  State<HistorialFallasView> createState() => _HistorialFallasViewState();
}

class _HistorialFallasViewState extends State<HistorialFallasView> {
  final FallasController _controller = FallasController();
  bool _mostrarTodos = false;

  // Filtros y búsqueda (inspirado en HistorialMantenimientosView)
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtroSeleccionado = 'Todos';
  final List<String> _filtros = [
    'Todos',
    'Reportada',
    'En reparación',
    'Resuelto',
  ];

  // Altura común para el widget de estado y el botón de eliminar
  final double _estadoWidgetHeight = 32;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1E88E5);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Historial de Fallas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // BARRA DE BÚSQUEDA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[100],
                  border: Border.all(
                    color: primaryBlue.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) => setState(() {}),
                  style: const TextStyle(fontSize: 15, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Buscar falla...',
                    hintStyle: const TextStyle(color: Color(0xFF999999)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                    prefixIcon: const Icon(
                      Icons.search_outlined,
                      color: primaryBlue,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                      child: const Icon(
                        Icons.close_outlined,
                        color: primaryBlue,
                      ),
                    )
                        : null,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // FILTROS DE ESTADO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
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
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _filtroSeleccionado = filtro;
                          });
                        },
                        backgroundColor: isSelected ? null : Colors.grey[100],
                        selectedColor: primaryBlue,
                        side: BorderSide(
                          color: isSelected ? primaryBlue : primaryBlue.withOpacity(0.12),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // LISTA DE FALLAS
            Expanded(
              child: StreamBuilder<List<Falla>>(
                stream: _controller.obtenerFallasPorConductor(widget.conductorId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando historial...',
                            style: TextStyle(
                              color: Colors.grey[600],
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
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No se han reportado fallas',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Todas las fallas reportadas aparecerán aquí',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // Datos iniciales (el stream ya devuelve fallas del conductor)
                  List<Falla> fallas = snapshot.data!;

                  // Filtrar por estado (si no es 'Todos')
                  if (_filtroSeleccionado != 'Todos') {
                    final filtroNorm = _filtroSeleccionado.trim().toLowerCase();
                    fallas = fallas.where((f) {
                      final estadoNorm = f.estado.trim().toLowerCase();
                      return estadoNorm == filtroNorm;
                    }).toList();
                  }

                  // Filtrar por búsqueda (tipoFalla, descripcion, comentariosAdmin)
                  if (_searchCtrl.text.isNotEmpty) {
                    final q = _searchCtrl.text.toLowerCase();
                    fallas = fallas.where((f) {
                      final tipo = f.tipoFalla.toLowerCase();
                      final desc = f.descripcion.toLowerCase();
                      final admin = (f.comentariosAdmin ?? '').toLowerCase();
                      return tipo.contains(q) || desc.contains(q) || admin.contains(q);
                    }).toList();
                  }

                  if (fallas.isEmpty) {
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

                  int mostrarCount = _mostrarTodos ? fallas.length : (fallas.length > 3 ? 3 : fallas.length);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: mostrarCount,
                          itemBuilder: (context, index) {
                            final falla = fallas[index];

                            // Determinar si el botón eliminar debe estar deshabilitado
                            final estadoNormalized = falla.estado.trim().toLowerCase();
                            final bool eliminarDeshabilitado = estadoNormalized == 'en reparación' || estadoNormalized == 'resuelto';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
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
                                                  falla.tipoFalla,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  falla.descripcion,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(width: 8),

                                          // Contenedor de estado con altura fija
                                          Container(
                                            height: _estadoWidgetHeight,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: _getColorPorEstado(falla.estado).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getColorPorEstado(falla.estado).withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              falla.estado,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _getColorPorEstado(falla.estado),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 8),

                                          // Botón ovalado con icono de basurero con la misma altura
                                          SizedBox(
                                            width: 44,
                                            height: _estadoWidgetHeight,
                                            child: ElevatedButton(
                                              onPressed: eliminarDeshabilitado
                                                  ? null
                                                  : () async {
                                                // Confirmar eliminación
                                                final confirmar = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Eliminar falla'),
                                                    content: const Text('¿Estás seguro de eliminar esta falla?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, false),
                                                        child: const Text('Cancelar'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, true),
                                                        child: const Text('Eliminar'),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirmar ?? false) {
                                                  // Llamar al controlador para eliminar la falla
                                                  await _controller.eliminarFalla(falla.id);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Falla eliminada')),
                                                  );
                                                }
                                              },
                                              style: ButtonStyle(
                                                minimumSize: MaterialStateProperty.all(Size(44, _estadoWidgetHeight)),
                                                padding: MaterialStateProperty.all(EdgeInsets.zero),
                                                backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                                                  if (states.contains(MaterialState.disabled)) return Colors.grey.shade200;
                                                  return Colors.red.shade50;
                                                }),
                                                foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                                                  if (states.contains(MaterialState.disabled)) return Colors.grey.shade400;
                                                  return Colors.red.shade600;
                                                }),
                                                shape: MaterialStateProperty.all(
                                                  RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                ),
                                                elevation: MaterialStateProperty.all(0),
                                              ),
                                              child: Icon(
                                                Icons.delete_outline,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // FOTO SI EXISTE
                                      if (falla.fotoUrl != null && falla.fotoUrl!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: GestureDetector(
                                              onTap: () {
                                                _mostrarFotoExpandida(context, falla.fotoUrl!);
                                              },
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Image.network(
                                                    falla.fotoUrl!,
                                                    height: 200,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Container(
                                                        height: 200,
                                                        color: Colors.grey.shade200,
                                                        child: Center(
                                                          child: CircularProgressIndicator(
                                                            value: loadingProgress.expectedTotalBytes != null
                                                                ? loadingProgress.cumulativeBytesLoaded /
                                                                loadingProgress.expectedTotalBytes!
                                                                : null,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        height: 200,
                                                        color: Colors.grey.shade300,
                                                        child: const Center(
                                                          child: Icon(Icons.image_not_supported_outlined),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  Container(
                                                    height: 200,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.1),
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.zoom_in_outlined,
                                                        color: Colors.white.withOpacity(0.7),
                                                        size: 32,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                      // INFORMACIÓN DETALLADA (FECHA Y HORA)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildInfoItem(
                                              Icons.calendar_today_outlined,
                                              'Fecha',
                                              DateFormat('dd/MM/yyyy').format(falla.createdAtDate),
                                            ),
                                            _buildInfoItem(
                                              Icons.access_time_outlined,
                                              'Hora',
                                              DateFormat('HH:mm').format(falla.createdAtDate),
                                            ),
                                            _buildInfoItem(
                                              Icons.image_outlined,
                                              'Foto',
                                              falla.fotoUrl != null ? 'Sí' : 'No',
                                            ),
                                          ],
                                        ),
                                      ),

                                      // COMENTARIOS DEL ADMINISTRADOR
                                      if (falla.estado.toLowerCase() == 'en reparación' || falla.estado.toLowerCase() == 'resuelto')
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.green.shade100,
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.admin_panel_settings_outlined,
                                                  size: 16,
                                                  color: Colors.green.shade700,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Comentarios del Administrador',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.green.shade700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        falla.comentariosAdmin ?? 'No hay comentarios adicionales',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.green.shade800,
                                                          height: 1.4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // BOTÓN MOSTRAR MÁS/MENOS
                      if (fallas.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[400]!,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    _mostrarTodos = !_mostrarTodos;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _mostrarTodos ? 'Mostrar menos' : 'Mostrar más',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        _mostrarTodos ? Icons.expand_less : Icons.expand_more,
                                        size: 20,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.blue,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _mostrarFotoExpandida(BuildContext context, String fotoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Image.network(
              fotoUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.7),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorPorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'reportada':
        return Colors.orange;
      case 'en reparación':
        return Colors.blue;
      case 'resuelto':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}