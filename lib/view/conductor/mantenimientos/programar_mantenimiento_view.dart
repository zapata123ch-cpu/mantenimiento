import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controller/mantenimientos_controller.dart';
import '../../../model/mantenimiento_model.dart';
import 'ejecutar_mantenimiento_view.dart';
import 'historial_mantenimientos_view.dart';

class ProgramarMantenimientoView extends StatefulWidget {
  final String vehiculoId;
  final String conductorId;

  const ProgramarMantenimientoView({
    super.key,
    required this.vehiculoId,
    required this.conductorId,
  });

  @override
  State<ProgramarMantenimientoView> createState() =>
      _ProgramarMantenimientoViewState();
}

class _ProgramarMantenimientoViewState
    extends State<ProgramarMantenimientoView> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();

  String _tipoServicioSeleccionado = 'Preventivo';
  final List<String> _tiposServicio = ['Preventivo', 'Correctivo'];
  DateTime? _fechaSeleccionada;

  bool _cargando = false;
  final MantenimientosController _controller = MantenimientosController();

  // Seleccionar fecha
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  // Guardar mantenimiento
  Future<void> _guardarMantenimiento() async {
    if (!_formKey.currentState!.validate() || _fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor completa todos los campos obligatorios'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      final mantenimiento = Mantenimiento(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vehiculoId: widget.vehiculoId,
        conductorId: widget.conductorId,
        tipoServicio: _tipoServicioSeleccionado,
        tipoMantenimiento: _tipoServicioSeleccionado,
        fechaProgramada: _fechaSeleccionada!,
        precio: 0.0,
        observaciones:
        _descripcionCtrl.text.isEmpty ? null : _descripcionCtrl.text,
        estado: 'Pendiente',
      );

      await _controller.guardarMantenimiento(mantenimiento);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Mantenimiento programado correctamente'),
          backgroundColor: Colors.green.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Limpiar formulario
      setState(() {
        _tipoServicioSeleccionado = 'Preventivo';
        _descripcionCtrl.clear();
        _fechaSeleccionada = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar mantenimiento: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    try {
      _descripcionCtrl.dispose();
    } catch (e) {
      print('Error disponiendo _descripcionCtrl: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1E88E5);
    const Color lightGrey = Color(0xFFF5F5F5);
    const Color textDark = Color(0xFF212121);
    const Color iconBlue = Color(0xFF1976D2);

    final fechaText = _fechaSeleccionada != null
        ? DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)
        : 'Selecciona una fecha';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Programar Mantenimiento',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER CON ICONO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.build_circle_outlined,
                      color: iconBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Nuevo Mantenimiento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Programa un nuevo servicio para el vehículo',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // FORMULARIO MEJORADO
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // TIPO DE SERVICIO (COMBO BOX)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: lightGrey,
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: SizedBox.shrink(),
                      value: _tipoServicioSeleccionado,
                      hint: const Text(
                        'Selecciona tipo de servicio',
                        style: TextStyle(
                          color: Color(0xFF999999),
                        ),
                      ),
                      items: _tiposServicio.map((String tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo,
                          child: Row(
                            children: [
                              Icon(
                                tipo == 'Preventivo'
                                    ? Icons.shield_outlined
                                    : Icons.build_outlined,
                                size: 18,
                                color: iconBlue,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                tipo,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _tipoServicioSeleccionado = newValue!;
                        });
                      },
                      selectedItemBuilder: (BuildContext context) {
                        return _tiposServicio.map<Widget>((String item) {
                          return Row(
                            children: [
                              Icon(
                                item == 'Preventivo'
                                    ? Icons.shield_outlined
                                    : Icons.build_outlined,
                                size: 18,
                                color: iconBlue,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textDark,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // FECHA PROGRAMADA
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: lightGrey,
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _seleccionarFecha(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: iconBlue,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fecha programada',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF999999),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fechaText,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _fechaSeleccionada != null
                                          ? textDark
                                          : const Color(0xFFCCCCCC),
                                      fontWeight: _fechaSeleccionada != null
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Color(0xFFCCCCCC),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // OBSERVACIONES / DESCRIPCIONES
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: lightGrey,
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      controller: _descripcionCtrl,
                      style: const TextStyle(fontSize: 16, color: textDark),
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Observaciones / Descripciones',
                        labelStyle: const TextStyle(
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: 'Notas adicionales sobre el mantenimiento (opcional)',
                        hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        prefixIcon: const Icon(
                          Icons.note_outlined,
                          color: iconBlue,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // BOTÓN ENVIAR
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: primaryBlue,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _cargando ? null : _guardarMantenimiento,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedOpacity(
                              opacity: _cargando ? 0 : 1,
                              duration: const Duration(milliseconds: 200),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.schedule_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Programar Mantenimiento',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_cargando)
                              const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // LISTA DE MANTENIMIENTOS PROGRAMADOS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: lightGrey,
                border: Border.all(
                  color: primaryBlue.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.list_alt_outlined,
                        color: iconBlue,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Mantenimientos Programados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Mantenimiento>>(
                    stream: _controller.obtenerMantenimientosPorVehiculo(widget.vehiculoId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryBlue,
                          ),
                        );
                      }

                      final mantenimientos = snapshot.data!
                          .where((m) => m.conductorId == widget.conductorId)
                          .toList();

                      if (mantenimientos.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Color(0xFFDDDDDD),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No hay mantenimientos programados',
                                style: TextStyle(
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // ✅ MOSTRAR MÁXIMO 2, EL BOTÓN VER MÁS SOLO SI HAY MÁS DE 1
                      final mostrados = mantenimientos.length > 2
                          ? mantenimientos.sublist(0, 2)
                          : mantenimientos;
                      final tieneQueMostrarVerMas = mantenimientos.length > 1;

                      return Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: mostrados.length,
                            itemBuilder: (context, index) {
                              final m = mostrados[index];
                              final esPreventivo = m.tipoServicio == 'Preventivo';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  border: Border.all(
                                    color: primaryBlue.withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Indicador de tipo de servicio
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: esPreventivo
                                            ? const Color(0xFF1976D2).withOpacity(0.1)
                                            : const Color(0xFFF57C00).withOpacity(0.1),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                            '${DateFormat('dd/MM/yyyy').format(m.fechaProgramada)} • ${m.estado}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF999999),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (m.estado == 'Aceptado' || m.estado == 'Urgente')
                                      Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: const Color(0xFF4CAF50),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(10),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EjecutarMantenimientoView(
                                                          mantenimiento: m),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(
                                                    Icons.play_arrow_outlined,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Ejecutar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          // ✅ BOTÓN VER MÁS - SOLO SI HAY MÁS DE 1
                          if (tieneQueMostrarVerMas)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            HistorialMantenimientosView(
                                              vehiculoId: widget.vehiculoId,
                                              conductorId: widget.conductorId,
                                            ),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryBlue,
                                    side: BorderSide(
                                      color: primaryBlue.withOpacity(0.3),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Ver más',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
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
          ],
        ),
      ),
    );
  }
}