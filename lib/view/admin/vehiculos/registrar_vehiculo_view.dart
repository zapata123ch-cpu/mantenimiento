import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../controller/vehiculos_controller.dart';
import '../../../model/vehiculo_model.dart';

class RegistrarVehiculoView extends StatefulWidget {
  const RegistrarVehiculoView({super.key});

  @override
  State<RegistrarVehiculoView> createState() => _RegistrarVehiculoViewState();
}

class _RegistrarVehiculoViewState extends State<RegistrarVehiculoView> {
  final _formKey = GlobalKey<FormState>();
  final VehiculosController _controller = VehiculosController();
  bool _isLoading = false;

  // Controladores de texto
  late TextEditingController _placaCtrl;
  late TextEditingController _marcaCtrl;
  late TextEditingController _modeloCtrl;
  late TextEditingController _anoCtrl;
  late TextEditingController _colorCtrl;

  // Documentos: nombre del archivo
  Map<String, String?> _documentosArchivos = {
    'SOAT': null,
    'TIV': null,
    'CITV': null,
    'TUC': null,
  };

  // Documentos: archivo File (para subir a Storage)
  Map<String, File?> _documentosFiles = {
    'SOAT': null,
    'TIV': null,
    'CITV': null,
    'TUC': null,
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _placaCtrl = TextEditingController();
    _marcaCtrl = TextEditingController();
    _modeloCtrl = TextEditingController();
    _anoCtrl = TextEditingController();
    _colorCtrl = TextEditingController();

  }

  Future<void> _seleccionarArchivo(String tipoDocumento) async {
    try {
      print('📁 Abriendo selector de archivos para: $tipoDocumento');

      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (resultado != null && resultado.files.single.path != null) {
        final path = resultado.files.single.path!;
        final fileName = resultado.files.single.name;
        final file = File(path);

        // Validar tamaño del archivo (máximo 1MB = 1048576 bytes)
        final fileSize = await file.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        print('📊 Tamaño del archivo: ${fileSizeMB.toStringAsFixed(2)} MB');

        if (fileSize > 1048576) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'El archivo es muy grande (${fileSizeMB.toStringAsFixed(2)} MB). Máximo permitido: 1 MB',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        setState(() {
          _documentosArchivos[tipoDocumento] = fileName;
          _documentosFiles[tipoDocumento] = file;
        });

        print('✓ Archivo válido y guardado: $fileName');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$tipoDocumento cargado: $fileName (${fileSizeMB.toStringAsFixed(2)} MB)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('❌ No se seleccionó archivo');
      }
    } catch (e) {
      print('❌ Error al cargar archivo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _registrarVehiculo() async {
    if (!_formKey.currentState!.validate()) return;

    // Verificar que todos los documentos estén cargados
    for (var doc in _documentosFiles.entries) {
      if (doc.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falta cargar el documento ${doc.key}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      print('[UI] 🚗 Iniciando registro de vehículo: ${_placaCtrl.text}');

      final vehiculo = Vehiculo(
        placa: _placaCtrl.text.toUpperCase(),
        marca: _marcaCtrl.text,
        modelo: _modeloCtrl.text,
        ano: int.parse(_anoCtrl.text),
        color: _colorCtrl.text,

        estado: 'Activo',
        kilometrajeAcumulado: 0,
        documentosBase64: {}, // Se llenará con las URLs de Storage
        fechaRegistro: DateTime.now(),
      );

      // Crear vehículo con archivos
      final resultado = await _controller.crearVehiculoConArchivos(
        vehiculo,
        _documentosFiles,
      );

      if (mounted) {
        if (resultado != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Vehículo registrado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al registrar el vehículo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('[UI] ❌ Error en registro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _documentoCard(String nombreDoc) {
    final cargado = _documentosArchivos[nombreDoc] != null;
    return GestureDetector(
      onTap: () => _seleccionarArchivo(nombreDoc),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cargado ? Colors.blue.shade600 : Colors.grey.shade200,
            width: 2,
          ),
          color: cargado
              ? Colors.blue.shade50
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: cargado
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cargado
                    ? Colors.blue.shade100
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                cargado ? Icons.check_circle : Icons.cloud_upload_outlined,
                size: 32,
                color: cargado ? Colors.blue.shade600 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nombreDoc,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                cargado
                    ? _documentosArchivos[nombreDoc]!
                    : 'Tap para cargar\n(Máx. 1MB)',
                style: TextStyle(
                  fontSize: 12,
                  color: cargado
                      ? Colors.blue.shade600
                      : Colors.grey.shade500,
                  fontWeight: cargado ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Registrar Vehículo',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nuevo Vehículo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Completa los datos requeridos',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Información del Vehículo'),
              const SizedBox(height: 18),

              // Placa
              _buildTextField(
                controller: _placaCtrl,
                label: 'Placa del Vehículo',
                hint: 'ABC-123',
                icon: Icons.confirmation_number,
                validator: (v) =>
                v?.isEmpty ?? true ? 'Ingresa la placa' : null,
              ),
              const SizedBox(height: 14),

              // Marca y Modelo
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _marcaCtrl,
                      label: 'Marca',
                      hint: 'Toyota',
                      icon: Icons.branding_watermark,
                      validator: (v) =>
                      v?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _modeloCtrl,
                      label: 'Modelo',
                      hint: 'Hiace 2020',
                      icon: Icons.model_training,
                      validator: (v) =>
                      v?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Año y Color
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _anoCtrl,
                      label: 'Año',
                      hint: '2024',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Requerido';
                        if (int.tryParse(v!) == null)
                          return 'Debe ser un número';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _colorCtrl,
                      label: 'Color',
                      hint: 'Blanco',
                      icon: Icons.color_lens,
                      validator: (v) =>
                      v?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              _buildSectionTitle('Documentos Obligatorios'),
              const SizedBox(height: 8),
              Text(
                'Carga en PDF o imagen (JPG/PNG) • Máximo 1MB por archivo',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: ['SOAT', 'TIV', 'CITV', 'TUC']
                    .map((doc) => _documentoCard(doc))
                    .toList(),
              ),
              const SizedBox(height: 36),

              // Botones
              Column(
                children: [
                  // Botón Registrar
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade800.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _registrarVehiculo,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.blue.shade800,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                          : const Icon(
                        Icons.check_circle,
                        size: 22,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isLoading ? 'Registrando...' : 'Registrar Vehículo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botón Cancelar
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(
                          color: Colors.blue.shade800,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,        // <-- sigue siendo obligatorio
    Widget? prefixIcon,            // <-- opcional, si llega, reemplaza al icon
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        // 👉 Si se envía prefixIcon, se usa.
        // 👉 Si no, se usa el icon normal.
        prefixIcon: prefixIcon ??
            Icon(
              icon,
              color: Colors.blue.shade600,
            ),

        prefixText: prefixText,
        prefixStyle: prefixText != null
            ? TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.blue.shade600,
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _placaCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _anoCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }
}