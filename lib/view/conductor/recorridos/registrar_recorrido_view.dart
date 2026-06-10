import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../controller/auth_controller.dart';
import '../../../controller/recorridos_controller.dart';
import '../../../model/recorrido_model.dart';
import '../../../model/vehiculo_model.dart';
import '../../../controller/vehiculos_controller.dart';
import '../../../rutas/app_routes.dart';

class RegistrarRecorridoView extends StatefulWidget {
  final String conductorId;
  final String vehiculoId;

  const RegistrarRecorridoView({
    super.key,
    required this.conductorId,
    required this.vehiculoId,
  });

  @override
  State<RegistrarRecorridoView> createState() => _RegistrarRecorridoViewState();
}

class _RegistrarRecorridoViewState extends State<RegistrarRecorridoView> {
  final RecorridoController _recorridoController = RecorridoController();
  final VehiculosController _vehiculoController = VehiculosController();

  // Estados
  int? _kmInicial;
  int? _kmFinal;
  String _estado = "esperando_km_inicial";
  bool _cargando = false;

  // Colores
  final Color _primaryColor = const Color(0xFF3B82F6);
  final Color _primaryLight = const Color(0xFFEFF6FF);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _borderColor = const Color(0xFFE2E8F0);

  // Controladores
  final TextEditingController _kmCtrl = TextEditingController();
  final TextEditingController _obsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatosGuardados();
  }

  Future<void> _cargarDatosGuardados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kmInicialGuardado = prefs.getInt('km_inicial_${widget.vehiculoId}');
      final estadoGuardado = prefs.getString('estado_${widget.vehiculoId}');

      if (kmInicialGuardado != null) {
        setState(() {
          _kmInicial = kmInicialGuardado;
          _estado = estadoGuardado ?? "esperando_km_final";
        });
        print('✅ Datos temporales recuperados: $_kmInicial km');
      } else {
        print('📝 No hay datos guardados - esperando que el usuario ingrese km inicial');
      }
    } catch (e) {
      print('Error cargando datos guardados: $e');
    }
  }

  Future<void> _guardarKmInicialTemporal(int km, String estado) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('km_inicial_${widget.vehiculoId}', km);
      await prefs.setString('estado_${widget.vehiculoId}', estado);
      print('✅ Km inicial guardado temporalmente: $km');
    } catch (e) {
      print('Error guardando km temporal: $e');
    }
  }

  Future<void> _limpiarDatosTemporales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('km_inicial_${widget.vehiculoId}');
      await prefs.remove('estado_${widget.vehiculoId}');
      print('✅ Datos temporales eliminados');
    } catch (e) {
      print('Error limpiando datos: $e');
    }
  }

  void _registrarKmInicial() {
    final kmIngresado = int.tryParse(_kmCtrl.text);

    if (kmIngresado == null || kmIngresado < 0) {
      _mostrarError('Por favor ingresa un número válido');
      return;
    }

    setState(() {
      _kmInicial = kmIngresado;
      _estado = "esperando_km_final";
      _kmCtrl.clear();
    });

    _guardarKmInicialTemporal(kmIngresado, "esperando_km_final");
    _mostrarExito('✅ Km inicial registrado: $_kmInicial km\n(Guardado temporalmente)');
  }

  void _registrarKmFinal() {
    final kmIngresado = int.tryParse(_kmCtrl.text);

    if (kmIngresado == null || kmIngresado < 0) {
      _mostrarError('Por favor ingresa un número válido');
      return;
    }

    if (kmIngresado < _kmInicial!) {
      _mostrarError('El km final no puede ser menor al inicial');
      return;
    }

    setState(() {
      _kmFinal = kmIngresado;
      _estado = "completado";
    });

    _mostrarExito('✅ Km final registrado: $_kmFinal km');
  }

  void _editarKmInicial() {
    final controllerEditar = TextEditingController(
      text: _kmInicial.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Km Inicial'),
          content: TextField(
            controller: controllerEditar,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ingresa el nuevo km',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final kmNuevo = int.tryParse(controllerEditar.text);

                if (kmNuevo == null || kmNuevo < 0) {
                  Navigator.pop(context);
                  _mostrarError('Ingresa un número válido');
                  controllerEditar.dispose();
                  return;
                }

                Navigator.pop(context);

                // Esperar a que el diálogo se cierre completamente
                await Future.delayed(const Duration(milliseconds: 100));

                setState(() {
                  _kmInicial = kmNuevo;
                  _kmFinal = null;
                  _estado = "esperando_km_final";
                  _kmCtrl.clear();
                });

                _guardarKmInicialTemporal(kmNuevo, "esperando_km_final");
                _mostrarExito('✅ Km inicial actualizado: $kmNuevo km');
                controllerEditar.dispose();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ).then((_) {
      // Disponer cuando el diálogo se cierre
      if (!controllerEditar.hasListeners) {
        try {
          controllerEditar.dispose();
        } catch (e) {
          print('Error: $e');
        }
      }
    });
  }

  Future<void> _guardarRecorrido() async {
    setState(() => _cargando = true);

    try {
      final distancia = (_kmFinal! - _kmInicial!).abs();

      final recorrido = Recorrido(
        id: const Uuid().v4(),
        conductorId: widget.conductorId,
        vehiculoId: widget.vehiculoId,
        fecha: DateTime.now(),
        kmInicial: _kmInicial!,
        kmFinal: _kmFinal!,
        distancia: distancia,
        observaciones: _obsCtrl.text.isEmpty ? null : _obsCtrl.text,
        estado: 'Completado',
      );

      await _recorridoController.guardarRecorrido(recorrido);
      await _limpiarDatosTemporales();

      setState(() {
        _kmInicial = null;
        _kmFinal = null;
        _estado = "esperando_km_inicial";
        _kmCtrl.clear();
        _obsCtrl.clear();
        _cargando = false;
      });

      _mostrarExito('✅ Recorrido guardado correctamente en la BD');
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('❌ Error: $e');
    }
  }

  void _limpiarFormulario() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Limpiar formulario?'),
        content: const Text('Se borrará el km inicial guardado temporalmente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await _limpiarDatosTemporales();
              setState(() {
                _estado = "esperando_km_inicial";
                _kmInicial = null;
                _kmFinal = null;
                _kmCtrl.clear();
                _obsCtrl.clear();
              });
              Navigator.pop(context);
              _mostrarExito('✅ Formulario limpiado');
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Registrar Recorrido'),
        backgroundColor: _surfaceColor,
        elevation: 0,
        foregroundColor: _textPrimary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de instrucciones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: _primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _estado == "esperando_km_inicial"
                          ? 'Registra el km del odómetro ANTES de salir'
                          : 'Registra el km del odómetro AL REGRESAR',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // KM INICIAL - CON OPCIÓN DE EDITAR
            Text(
              'Km Inicial',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _kmInicial != null ? Colors.green : _borderColor,
                  width: _kmInicial != null ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _kmInicial != null ? '$_kmInicial km' : 'No registrado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kmInicial != null ? _primaryColor : _textSecondary,
                        ),
                      ),
                      if (_kmInicial != null)
                        Text(
                          '(Guardado temporalmente)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_kmInicial != null)
                        IconButton(
                          icon: Icon(Icons.edit, color: _primaryColor),
                          onPressed: _editarKmInicial,
                          tooltip: 'Editar km inicial',
                        ),
                      if (_kmInicial != null)
                        Icon(Icons.check_circle, color: Colors.green.shade500),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // CAMPOS DE ENTRADA
            if (_estado == "esperando_km_inicial" || _estado == "esperando_km_final") ...[
              Text(
                _estado == "esperando_km_inicial"
                    ? 'Ingresa Km Inicial'
                    : 'Ingresa Km Final',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _kmCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Ej: 3450',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _estado == "esperando_km_inicial"
                      ? _registrarKmInicial
                      : _registrarKmFinal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _estado == "esperando_km_inicial"
                        ? 'Registrar Km Inicial'
                        : 'Registrar Km Final',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],

            // CUANDO ESTÁ COMPLETADO
            if (_estado == "completado") ...[
              const SizedBox(height: 24),
              Text(
                'Km Final',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_kmFinal km',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                    Icon(Icons.check_circle, color: Colors.green.shade500),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Distancia calculada
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distancia Recorrida',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_kmFinal! - _kmInicial!} km',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Observaciones
              Text(
                'Observaciones (Opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _obsCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ej: Viaje a provincia, tráfico moderado...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),

              const SizedBox(height: 24),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _cargando ? null : _limpiarFormulario,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Limpiar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: _textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _cargando ? null : _guardarRecorrido,
                      icon: _cargando
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                          : const Icon(Icons.save),
                      label: Text(_cargando ? 'Guardando...' : 'Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // HISTORIAL DE RECORRIDOS
            const SizedBox(height: 40),
            Text(
              'Historial Reciente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<Recorrido>>(
              stream: _recorridoController.obtenerRecorridosPorVehiculo(widget.vehiculoId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar historial: ${snapshot.error}'),
                  );
                }

                final recorridos = snapshot.data ?? [];
                final ultimosTres = recorridos.take(3).toList();

                if (ultimosTres.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Center(
                      child: Text(
                        'No hay recorridos registrados',
                        style: TextStyle(color: _textSecondary),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    ...ultimosTres.map((recorrido) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.route,
                                color: _primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${recorrido.distancia} km recorridos',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Km ${recorrido.kmInicial} - ${recorrido.kmFinal}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${recorrido.fecha.day}/${recorrido.fecha.month}/${recorrido.fecha.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.conductorHistorialRecorridos,
                            arguments: widget.vehiculoId,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: _primaryColor, width: 2),
                        ),
                        child: Text(
                          'Ver más',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      _kmCtrl.dispose();
    } catch (e) {
      print('Error disponiendo _kmCtrl: $e');
    }
    try {
      _obsCtrl.dispose();
    } catch (e) {
      print('Error disponiendo _obsCtrl: $e');
    }
    super.dispose();
  }
}