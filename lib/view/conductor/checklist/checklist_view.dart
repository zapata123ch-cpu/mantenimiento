import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../controller/checklist_controller.dart';
import '../../../model/checklist_model.dart';
import '../../../rutas/app_routes.dart';

class ChecklistView extends StatefulWidget {
  final String conductorId;
  final String vehiculoId;

  const ChecklistView({
    super.key,
    required this.conductorId,
    required this.vehiculoId,
  });

  @override
  State<ChecklistView> createState() => _ChecklistViewState();
}

class _ChecklistViewState extends State<ChecklistView> {
  // Estado del checklist
  Map<String, bool?> _checklistItems = {
    'luces': null,
    'frenos': null,
    'llantas': null,
    'motor': null,
    'liquidos': null,
  };

  String _estadoVehiculo = 'pendiente'; // pendiente, apto, no_apto
  final TextEditingController _observacionesCtrl = TextEditingController();
  bool _cargando = false;

  final ChecklistController _checklistController = ChecklistController();

  // Colores
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

  // Mapeo de items
  final Map<String, Map<String, String>> _itemsInfo = {
    'luces': {
      'label': 'Luces',
      'icon': '💡',
      'description': 'Faros, luces de freno y direccionales'
    },
    'frenos': {
      'label': 'Frenos',
      'icon': '🛑',
      'description': 'Funcionamiento y pastillas'
    },
    'llantas': {
      'label': 'Llantas',
      'icon': '⭕',
      'description': 'Presión, desgaste y daños'
    },
    'motor': {
      'label': 'Motor',
      'icon': '🔧',
      'description': 'Ruidos, pérdidas de aceite'
    },
    'liquidos': {
      'label': 'Líquidos',
      'icon': '🛢️',
      'description': 'Aceite, refrigerante, limpiaparabrisas'
    },
  };

  bool get _todoVerificado {
    return _checklistItems.values.every((value) => value != null);
  }

  bool get _hayAlgunNoApto {
    return _checklistItems.values.any((value) => value == false);
  }

  int get _itemsCompletados {
    return _checklistItems.values.where((v) => v != null).length;
  }

  void _finalizarChecklist() {
    if (!_todoVerificado) {
      _mostrarError('Por favor verifica todos los items del checklist');
      return;
    }

    setState(() {
      _estadoVehiculo = _hayAlgunNoApto ? 'no_apto' : 'apto';
    });

    if (_hayAlgunNoApto) {
      _mostrarAdvertencia(
        '⚠️ Vehículo marcado como NO APTO\nSe notificará al Admin automáticamente',
      );
    } else {
      _mostrarExito('✅ Checklist completado - Vehículo APTO para ruta');
    }
  }

  Future<void> _guardarChecklist() async {
    print("=== 🟦 INICIANDO GUARDADO DEL CHECKLIST ===");

    if (_estadoVehiculo == 'pendiente') {
      print("❌ ERROR: Estado del vehículo sigue en PENDIENTE");
      _mostrarError('Primero debes completar el checklist');
      return;
    }

    setState(() => _cargando = true);

    try {
      final itemsMap = <String, bool>{};
      _checklistItems.forEach((key, value) {
        if (value != null) itemsMap[key] = value;
      });

      final idGenerado = const Uuid().v4();
      final now = DateTime.now();

      final checklist = Checklist(
        id: idGenerado,
        conductorId: widget.conductorId,
        vehiculoId: widget.vehiculoId,
        fecha: now,
        items: itemsMap,
        estado: _estadoVehiculo,
        observaciones:
        _observacionesCtrl.text.isEmpty ? null : _observacionesCtrl.text,
        createdAt: now,
      );

      await _checklistController.guardarChecklist(checklist);
      _mostrarExito('✓ Checklist guardado correctamente');

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _checklistItems = {
              'luces': null,
              'frenos': null,
              'llantas': null,
              'motor': null,
              'liquidos': null,
            };
            _estadoVehiculo = 'pendiente';
            _observacionesCtrl.clear();
          });
        }
      });
    } catch (e) {
      _mostrarError('Error al guardar: $e');
    } finally {
      setState(() => _cargando = false);
    }
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
        backgroundColor: _dangerColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarAdvertencia(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: _warningColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
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
        backgroundColor: _successColor,
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
        title: const Text('Checklist Previo'),
        backgroundColor: _surfaceColor,
        elevation: 0,
        foregroundColor: _textPrimary,
        centerTitle: true,
        // En ChecklistView, en el AppBar, reemplaza la sección actions:

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // ✅ Navegar a historial con la ruta correcta
                    Navigator.pushNamed(
                      context,
                      AppRoutes.conductorHistorialChecklist, // ← USA LA RUTA CORRECTA
                      arguments: {
                        'conductorId': widget.conductorId,
                        'vehiculoId': widget.vehiculoId,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, color: _primaryColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Historial',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de progreso
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso del Checklist',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_itemsCompletados/5',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _itemsCompletados / 5,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Card informativo mejorado
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.info_rounded, color: _primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verifica cada componente antes de salir. Tu seguridad es nuestra prioridad.',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Título con contador
            Row(
              children: [
                Text(
                  'Verificaciones Requeridas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${5 - _itemsCompletados} pendiente${5 - _itemsCompletados != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Items del checklist mejorados
            ..._checklistItems.keys.map((key) {
              final info = _itemsInfo[key]!;
              final isChecked = _checklistItems[key];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isChecked == null
                          ? _borderColor
                          : isChecked
                          ? _successColor.withOpacity(0.3)
                          : _dangerColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: isChecked != null
                        ? [
                      BoxShadow(
                        color: (isChecked ? _successColor : _dangerColor)
                            .withOpacity(0.08),
                        blurRadius: 8,
                      )
                    ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isChecked == null
                                        ? _backgroundColor
                                        : isChecked
                                        ? _successColor.withOpacity(0.1)
                                        : _dangerColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isChecked == null
                                          ? _borderColor
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      info['icon']!,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        info['label']!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        info['description']!,
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
                          ),
                          // Badge de estado
                          if (isChecked != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isChecked ? _successColor : _dangerColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isChecked
                                        ? Icons.check_rounded
                                        : Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isChecked ? 'Apto' : 'No Apto',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _checklistItems[key] = true);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isChecked == true
                                        ? _successColor
                                        : _backgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isChecked == true
                                        ? null
                                        : Border.all(color: _borderColor),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Apto ✓',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: isChecked == true
                                            ? Colors.white
                                            : _textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _checklistItems[key] = false);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isChecked == false
                                        ? _dangerColor
                                        : _backgroundColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isChecked == false
                                        ? null
                                        : Border.all(color: _borderColor),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No apto ✗',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: isChecked == false
                                            ? Colors.white
                                            : _textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            // Observaciones
            Text(
              'Observaciones (Opcional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _observacionesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: Ruido en el motor, desgaste en llantas...',
                hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
                filled: true,
                fillColor: _surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            const SizedBox(height: 20),

            // Indicador de estado
            if (_todoVerificado)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _hayAlgunNoApto
                      ? _warningColor.withOpacity(0.1)
                      : _successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hayAlgunNoApto
                        ? _warningColor.withOpacity(0.3)
                        : _successColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hayAlgunNoApto
                          ? Icons.warning_rounded
                          : Icons.verified_user_rounded,
                      color: _hayAlgunNoApto ? _warningColor : _successColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _hayAlgunNoApto
                            ? 'Vehículo con problemas. Admin será notificado.'
                            : '¡Vehículo listo para ruta! Buen viaje.',
                        style: TextStyle(
                          color: _hayAlgunNoApto
                              ? _warningColor
                              : _successColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Botones de acción
            if (_estadoVehiculo == 'pendiente')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finalizarChecklist,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Finalizar Checklist',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _cargando ? null : _guardarChecklist,
                      icon: _cargando
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _cargando ? 'Guardando...' : 'Guardar Checklist',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _cargando
                          ? null
                          : () {
                        setState(() {
                          _checklistItems = {
                            'luces': null,
                            'frenos': null,
                            'llantas': null,
                            'motor': null,
                            'liquidos': null,
                          };
                          _estadoVehiculo = 'pendiente';
                          _observacionesCtrl.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textSecondary,
                        side: BorderSide(color: _borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reiniciar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _observacionesCtrl.dispose();
    super.dispose();
  }
}