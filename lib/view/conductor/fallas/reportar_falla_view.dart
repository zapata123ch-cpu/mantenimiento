import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../../../controller/fallas_controller.dart';
import '../../../model/falla_model.dart';
import 'historial_fallas_view.dart';

class ReportarFallaView extends StatefulWidget {
  final String vehiculoId;
  final String conductorId;

  const ReportarFallaView({
    super.key,
    required this.vehiculoId,
    required this.conductorId,
  });

  @override
  State<ReportarFallaView> createState() => _ReportarFallaViewState();
}

class _ReportarFallaViewState extends State<ReportarFallaView> {
  final _formKey = GlobalKey<FormState>();
  final _tipoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  bool _cargando = false;
  bool _mostrarTodos = false;

  File? _fotoSeleccionada;
  final ImagePicker _picker = ImagePicker();
  final FallasController _controller = FallasController();

  // Seleccionar foto de galería o cámara
  Future<void> _seleccionarFoto(ImageSource source) async {
    try {
      final XFile? foto = await _picker.pickImage(source: source);
      if (foto != null) {
        setState(() {
          _fotoSeleccionada = File(foto.path);
        });
      }
    } catch (e) {
      print('Error seleccionando foto: $e');
    }
  }

  // Subir foto a Firebase Storage
  Future<String?> _subirFoto() async {
    if (_fotoSeleccionada == null) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('fallas/${widget.conductorId}/$timestamp.jpg');

      await ref.putFile(_fotoSeleccionada!);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error subiendo foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir foto: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return null;
    }
  }

  Future<void> _guardarFalla() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      String? fotoUrl;
      if (_fotoSeleccionada != null) {
        fotoUrl = await _subirFoto();
      }

      final falla = Falla(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        vehiculoId: widget.vehiculoId,
        conductorId: widget.conductorId,
        tipoFalla: _tipoCtrl.text,
        descripcion: _descripcionCtrl.text,
        fotoUrl: fotoUrl,
        createdAt: Timestamp.now(),
      );

      print('📌 Guardando falla: ${falla.toJson()}');

      await _controller.guardarFalla(falla);

      print('✅ Falla guardada exitosamente');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Falla reportada correctamente'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      _tipoCtrl.clear();
      _descripcionCtrl.clear();
      setState(() => _fotoSeleccionada = null);
    } catch (e) {
      print('❌ Error al guardar falla: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reportar falla: $e'),
          backgroundColor: Colors.red.shade600,
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
    _tipoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Reportar Falla',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistorialFallasView(
                    conductorId: widget.conductorId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER INFORMATIVO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Reportar Nueva Falla',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Describe el problema del vehículo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FORMULARIO
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // TIPO DE FALLA
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        child: TextFormField(
                          controller: _tipoCtrl,
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Tipo de falla',
                            hintText: 'Ej: Frenos, motor, luces...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            labelStyle: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          validator: (v) =>
                          v == null || v.isEmpty ? 'Campo obligatorio' : null,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // DESCRIPCIÓN
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        child: TextFormField(
                          controller: _descripcionCtrl,
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            hintText: 'Detalles de la falla...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            labelStyle: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          maxLines: 3,
                          validator: (v) =>
                          v == null || v.isEmpty ? 'Campo obligatorio' : null,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // SELECCIONAR FOTO (OPCIONAL)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.image_outlined,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Foto de la falla (opcional)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_fotoSeleccionada == null)
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _seleccionarFoto(ImageSource.camera),
                                        icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                                        label: const Text('Cámara', style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[800],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _seleccionarFoto(ImageSource.gallery),
                                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                                        label: const Text('Galería', style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[800],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _fotoSeleccionada!,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () => setState(() => _fotoSeleccionada = null),
                                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                                      label: const Text('Eliminar foto', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // BOTÓN REPORTAR
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _guardarFalla,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
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
                                      Icons.report_problem_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Reportar Falla',
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

                      const SizedBox(height: 32),

                      // HISTORIAL RECIENTE
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.history_outlined,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Fallas Recientes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // LISTA DE FALLAS
                            StreamBuilder<List<Falla>>(
                              stream: _controller.obtenerFallasPorConductor(widget.conductorId),
                              builder: (context, snapshot) {
                                print('🔄 Snapshot state: ${snapshot.connectionState}, data: ${snapshot.data}');

                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  );
                                }

                                if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.assignment_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'No hay fallas reportadas',
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final fallas = snapshot.data!;
                                final mostrarFallas = fallas.length > 3 && !_mostrarTodos
                                    ? fallas.sublist(0, 3)
                                    : fallas;

                                return Column(
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: mostrarFallas.length,
                                      itemBuilder: (context, index) {
                                        final f = mostrarFallas[index];
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      f.tipoFalla,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.black,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _getColorPorEstado(f.estado).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      f.estado,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: _getColorPorEstado(f.estado),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                f.descripcion,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('dd/MM/yy - HH:mm').format(f.createdAtDate),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),

                                    if (fallas.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey[400]!,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => HistorialFallasView(
                                                      conductorId: widget.conductorId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: const [
                                                    Text(
                                                      'Ver historial completo',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Icon(
                                                      Icons.arrow_forward_rounded,
                                                      size: 16,
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
                          ],
                        ),
                      ),
                    ],
                  ),
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
      case 'urgente':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}