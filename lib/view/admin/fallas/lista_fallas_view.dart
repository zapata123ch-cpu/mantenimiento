import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controller/fallas_controller.dart';
import '../../../model/falla_model.dart';
import 'detalle_falla_view.dart';

class ListaFallasView extends StatefulWidget {
  const ListaFallasView({super.key});

  @override
  State<ListaFallasView> createState() => _ListaFallasViewState();
}

class _ListaFallasViewState extends State<ListaFallasView> {
  final FallasController _controller = FallasController();
  String _filtroSeleccionado = 'Todos';
  final List<String> _filtros = [
    'Todos',
    'Reportada',
    'En reparación',
    'Resuelto'
  ];

  late Future<Map<String, String>> _datosPreCargados;

  @override
  void initState() {
    super.initState();
    _datosPreCargados = _precargarTodosDatos();
  }

  // Precarga TODOS los datos de una vez
  Future<Map<String, String>> _precargarTodosDatos() async {
    final nombresConductores = <String, String>{};
    final placasVehiculos = <String, String>{};

    try {
      print('🔄 Iniciando precarga de datos...');
      final fallas = await _controller.obtenerTodasLasFallas().first;
      print('📋 Se encontraron ${fallas.length} fallas');

      for (final falla in fallas) {
        print('\n🔎 Procesando falla: ${falla.id}');
        print('   conductorId: ${falla.conductorId}');
        print('   vehiculoId: ${falla.vehiculoId}');

        // Cargar conductor por conductorId
        if (!nombresConductores.containsKey(falla.conductorId)) {
          print('   ⏳ Obteniendo nombre del conductor...');
          final nombre = await _controller.obtenerNombreConductor(falla.conductorId);
          print('   📞 Respuesta de obtenerNombreConductor: "$nombre"');
          print('   📞 Tipo: ${nombre.runtimeType}');
          nombresConductores[falla.conductorId] = nombre;
          print('   ✅ Guardado en mapa: ${falla.conductorId} = "$nombre"');
        } else {
          print('   ⏭️  Ya existe en mapa: ${falla.conductorId} = "${nombresConductores[falla.conductorId]}"');
        }

        // Cargar vehículo por vehiculoId
        if (!placasVehiculos.containsKey(falla.vehiculoId)) {
          print('   ⏳ Obteniendo placa del vehículo...');
          final placa = await _controller.obtenerPlacaVehiculo(falla.vehiculoId);
          placasVehiculos[falla.vehiculoId] = placa;
          print('   ✅ Vehículo ${falla.vehiculoId} = "$placa"');
        }
      }

      // Combinar ambos mapas
      final mapaFinal = <String, String>{};
      mapaFinal.addAll(nombresConductores);
      mapaFinal.addAll(placasVehiculos);

      print('\n📊 PRECARGA COMPLETADA:');
      print('   Conductores: ${nombresConductores.length}');
      print('   Vehículos: ${placasVehiculos.length}');
      print('   Total en mapa: ${mapaFinal.length}');
      nombresConductores.forEach((k, v) => print('     $k → $v'));

      return mapaFinal;
    } catch (e) {
      print('❌ Error precargando datos: $e');
    }

    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Reportes de Fallas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // FILTROS
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrar por estado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filtros.map((filtro) {
                      final isSelected = _filtroSeleccionado == filtro;
                      return Container(
                        margin: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(
                            filtro,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.blue[800],
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _filtroSeleccionado = filtro;
                            });
                          },
                          backgroundColor: Colors.blue[50],
                          selectedColor: Colors.blue[800],
                          side: BorderSide(
                            color: isSelected
                                ? Colors.blue[800]!
                                : Colors.blue.withOpacity(0.2),
                            width: 1.5,
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

          // LISTA DE FALLAS
          Expanded(
            child: FutureBuilder<Map<String, String>>(
              future: _datosPreCargados,
              builder: (context, futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue[800],
                    ),
                  );
                }

                final datosPreCargados = futureSnapshot.data ?? {};

                return StreamBuilder<List<Falla>>(
                  stream: _controller.obtenerTodasLasFallas(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue[800],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 64,
                              color: Colors.blue.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay fallas reportadas',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final allFallas = snapshot.data!;

                    final fallas = _filtroSeleccionado == 'Todos'
                        ? allFallas
                        : allFallas
                        .where((f) => f.estado == _filtroSeleccionado)
                        .toList();

                    if (fallas.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_alt_outlined,
                              size: 64,
                              color: Colors.blue.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay fallas en estado $_filtroSeleccionado',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: fallas.length,
                      itemBuilder: (context, index) {
                        final falla = fallas[index];
                        final isPendiente = falla.estado == 'Reportada';

                        // Obtener datos del mapa precargado
                        final nombreConductor = datosPreCargados[falla.conductorId] ?? falla.conductorId;
                        final placaVehiculo = datosPreCargados[falla.vehiculoId] ?? falla.vehiculoId;

                        print('🎯 Renderizando falla ${falla.id}:');
                        print('   conductorId: ${falla.conductorId}');
                        print('   nombreConductor del mapa: "$nombreConductor"');
                        print('   Mapa contiene: ${datosPreCargados.keys.toList()}');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                            border: Border.all(
                              color: isPendiente
                                  ? Colors.orange.withOpacity(0.3)
                                  : Colors.blue.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetalleFallaView(falla: falla),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ENCABEZADO (AHORA CON ICONO ELIMINAR)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                falla.tipoFalla,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue[800],
                                                ),
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

                                        // Estado + botón eliminar (alineados verticalmente)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              children: [
                                                // Contenedor de estado
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: _getColorPorEstado(falla.estado).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: _getColorPorEstado(falla.estado).withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    falla.estado,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: _getColorPorEstado(falla.estado),
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 8),

                                                // Botón eliminar (estilo compacto similar al ejemplo)
                                                SizedBox(
                                                  height: 36,
                                                  width: 44,
                                                  child: ElevatedButton(
                                                    onPressed: () => _confirmarYEliminarFalla(falla),
                                                    style: ButtonStyle(
                                                      minimumSize: MaterialStateProperty.all(const Size(44, 36)),
                                                      padding: MaterialStateProperty.all(EdgeInsets.zero),
                                                      backgroundColor: MaterialStateProperty.all(Colors.red.shade50),
                                                      foregroundColor: MaterialStateProperty.all(Colors.red.shade600),
                                                      shape: MaterialStateProperty.all(
                                                        RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      ),
                                                      elevation: MaterialStateProperty.all(0),
                                                    ),
                                                    child: const Icon(
                                                      Icons.delete_rounded,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // FOTO Y DETALLES
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // FOTO
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.blue.withOpacity(0.1),
                                              width: 1,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: falla.fotoUrl != null
                                                ? Image.network(
                                              falla.fotoUrl!,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.blue[50],
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.blue[300],
                                                    size: 32,
                                                  ),
                                                );
                                              },
                                            )
                                                : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.blue[50],
                                              child: Icon(
                                                Icons.camera_alt_outlined,
                                                color: Colors.blue[300],
                                                size: 32,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        // INFORMACIÓN
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today_outlined,
                                                      size: 14,
                                                      color: Colors.blue[800],
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      DateFormat('dd/MM/yyyy').format(falla.createdAtDate),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.blue[800],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.access_time_outlined,
                                                      size: 14,
                                                      color: Colors.blue[800],
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      DateFormat('HH:mm').format(falla.createdAtDate),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.blue[800],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // DESCRIPCIÓN
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50]?.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.description_outlined,
                                                size: 16,
                                                color: Colors.blue[800],
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Descripción',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            falla.descripcion,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // COMENTARIOS ADMIN
                                    if (falla.comentariosAdmin != null && falla.comentariosAdmin!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.admin_panel_settings_outlined,
                                                  size: 16,
                                                  color: Colors.blue[800],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Comentarios Admin',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.blue[800],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              falla.comentariosAdmin!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 16),

                                    // BOTÓN DE ACCIÓN
                                    if (falla.estado == 'Reportada' || falla.estado == 'En reparación')
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[800],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => DetalleFallaView(falla: falla),
                                              ),
                                            );
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.build_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Text(
                                                'Revisar Falla',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else if (falla.estado == 'Resuelto')
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green[700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Falla Resuelta',
                                              style: TextStyle(
                                                color: Colors.green[700],
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
                          ),
                        );
                      },
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

  // Confirmación y eliminación de falla
  Future<void> _confirmarYEliminarFalla(Falla falla) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar falla'),
        content: Text('¿Estás seguro de eliminar la falla "${falla.tipoFalla}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmar ?? false) {
      try {
        await _controller.eliminarFalla(falla.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Falla eliminada'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.blue[800],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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