import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../controller/documentos_controller.dart';

class DocumentosPersonalesView extends StatefulWidget {
  final String idUsuario;

  const DocumentosPersonalesView({super.key, required this.idUsuario});

  @override
  State<DocumentosPersonalesView> createState() =>
      _DocumentosPersonalesViewState();
}

class _DocumentosPersonalesViewState extends State<DocumentosPersonalesView> {
  bool _isLoading = false;
  String? _loadingMessage;
  final DocumentosController _controller = DocumentosController();

  static const Map<String, Map<String, dynamic>> tiposDoc = {
    'DNI': {
      'icon': Icons.badge_outlined,
      'label': 'DNI',
      'descripcion': 'Frente y reverso',
      'dosLados': true
    },
    'Licencia de Conducir': {
      'icon': Icons.credit_card_outlined,
      'label': 'Licencia',
      'descripcion': 'Ambos lados',
      'dosLados': true
    },
    'Certificado de Conducción': {
      'icon': Icons.school_outlined,
      'label': 'Certificado de inducción',
      'descripcion': 'Frente y reverso',
      'dosLados': false
    },
    'Otros': {
      'icon': Icons.folder_outlined,
      'label': 'Otros Documentos',
      'descripcion': 'Un documento',
      'dosLados': false
    },
  };

  // ======================== MOSTRAR MODAL DE CAPTURA CON PASOS ========================
  void _mostrarModalCaptura(String tipoDocumento) {
    bool dosLados = tiposDoc[tipoDocumento]!['dosLados'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Importante para responsive
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _CapturadoWidget(
        tipoDocumento: tipoDocumento,
        tiposDocMap: tiposDoc,
        dosLados: dosLados,
        onCapturado: (fotos) {
          Navigator.pop(context);
          if (dosLados) {
            _subirDocumentoAmbosLados(
                tipoDocumento, fotos['frente']!, fotos['reverso']!);
          } else {
            _subirDocumentoUnLado(tipoDocumento, fotos['unico']!);
          }
        },
      ),
    );
  }

  // ======================== SUBIR CON AMBOS LADOS ========================
  Future<void> _subirDocumentoAmbosLados(
      String tipoDocumento,
      String rutaFrente,
      String rutaReverso,
      ) async {
    print('🎬 [VIEW] Iniciando subida ambos lados de $tipoDocumento');

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Preparando documentos...';
    });

    try {
      setState(() => _loadingMessage = 'Subiendo FRENTE...');
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _loadingMessage = 'Subiendo REVERSO...');
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _loadingMessage = 'Guardando en base de datos...'
      );

      String? docId = await _controller.subirDocumentoAmbosLados(
        idUsuario: widget.idUsuario,
        tipoDocumento: tipoDocumento,
        rutaFrente: rutaFrente,
        rutaReverso: rutaReverso,
      );

      if (docId != null) {
        print('✅ [VIEW] Documento subido: $docId');

        if (mounted) {
          _mostrarExito('✅ ${tiposDoc[tipoDocumento]!['label']} subido correctamente');
          setState(() {});
        }
      }
    } catch (e) {
      print('❌ [VIEW] Error: $e');
      if (mounted) {
        _mostrarError('Error: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }

  // ======================== SUBIR UN LADO ========================
  Future<void> _subirDocumentoUnLado(
      String tipoDocumento,
      String rutaDocumento,
      ) async {
    print('🎬 [VIEW] Iniciando subida un lado de $tipoDocumento');

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Subiendo documento...';
    });

    try {
      setState(() => _loadingMessage = 'Guardando en base de datos...');

      String? docId = await _controller.subirDocumentoUnLado(
        idUsuario: widget.idUsuario,
        tipoDocumento: tipoDocumento,
        rutaDocumento: rutaDocumento,
      );

      if (docId != null) {
        print('✅ [VIEW] Documento subido: $docId');

        if (mounted) {
          _mostrarExito('✅ ${tiposDoc[tipoDocumento]!['label']} subido correctamente');
          setState(() {});
        }
      }
    } catch (e) {
      print('❌ [VIEW] Error: $e');
      if (mounted) {
        _mostrarError('Error: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }

  void _mostrarExito(String mensaje) {
    print('✅ [VIEW] Mostrando éxito: $mensaje');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    print('❌ [VIEW] Mostrando error: $mensaje');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8F9FC),
          appBar: AppBar(
            title: const Text('Mis Documentos',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D21))),
            backgroundColor: Colors.white,
            elevation: 0.5,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Botones de subida
                const Text('Subir Documento',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1D21))),
                const SizedBox(height: 12),
                ...tiposDoc.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: _isLoading ? null : () => _mostrarModalCaptura(entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isLoading
                                ? Colors.grey.shade300
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(entry.value['icon'],
                                  color: Colors.blue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.value['label'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(entry.value['descripcion'],
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_outlined,
                                size: 16,
                                color: _isLoading
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade300),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 30),

                // Documentos cargados
                const Text('Documentos Subidos',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1D21))),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(widget.idUsuario)
                      .collection('documentos')
                      .orderBy('fechaCarga', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.folder_open_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('Sin documentos cargados',
                                style: TextStyle(color: Color(0xFF64748B))),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var data = doc.data() as Map<String, dynamic>;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8)
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
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      tiposDoc[data['tipoDocumento']]?['icon'] ??
                                          Icons.description_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(data['tipoDocumento'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text(
                                          data['nombreArchivoFrente'] ??
                                              data['nombreArchivo'] ??
                                              'Documento',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: data['estado'] ==
                                          'pendiente_revision'
                                          ? Colors.orange.shade50
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      data['estado'] == 'pendiente_revision'
                                          ? 'Pendiente'
                                          : 'Aprobado',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: data['estado'] ==
                                              'pendiente_revision'
                                              ? Colors.orange
                                              : Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Cargado: ${DateFormat('dd/MM/yyyy').format((data['fechaCarga'] as Timestamp).toDate())}',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (data['urlFrente'] != null)
                                    Expanded(
                                      child: _buildBotonVer('Frente',
                                          data['urlFrente'], 'frente'),
                                    ),
                                  if (data['urlFrente'] != null)
                                    const SizedBox(width: 8),
                                  if (data['urlReverso'] != null)
                                    Expanded(
                                      child: _buildBotonVer('Reverso',
                                          data['urlReverso'], 'reverso'),
                                    ),
                                  if (data['urlDocumento'] != null)
                                    Expanded(
                                      child: _buildBotonVer('Ver',
                                          data['urlDocumento'], 'documento'),
                                    ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 40,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _eliminarDocumento(doc.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Icon(Icons.delete_outline,
                                          size: 16,
                                          color: Colors.red.shade600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _loadingMessage ?? 'Procesando...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1D21),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBotonVer(String label, String url, String tipo) {
    return OutlinedButton.icon(
      onPressed: () {
        print('👁️ [VIEW] Ver $tipo: $url');
        _mostrarImagenPreview(url);
      },
      icon: const Icon(Icons.image_outlined, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _mostrarImagenPreview(String url) {
    print('🖼️ [VIEW] Mostrando preview: $url');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ [VIEW] Error cargando: $error');
            return const Center(child: Text('Error cargando imagen'));
          },
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

  void _eliminarDocumento(String docId) {
    print('🗑️ [VIEW] Pidiendo confirmación para eliminar: $docId');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Documento'),
        content:
        const Text('¿Estás seguro de que deseas eliminar este documento?'),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ [VIEW] Usuario canceló eliminación');
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              print('🗑️ [VIEW] Usuario confirmó eliminación');

              try {
                await _controller.eliminarDocumento(
                  idUsuario: widget.idUsuario,
                  idDocumento: docId,
                );
                if (mounted) {
                  _mostrarExito('Documento eliminado');
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  _mostrarError('Error: $e');
                }
              }
            },
            child: const Text('Eliminar',
                style:
                TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ======================== WIDGET DE CAPTURA MEJORADO ========================
class _CapturadoWidget extends StatefulWidget {
  final String tipoDocumento;
  final Map<String, Map<String, dynamic>> tiposDocMap;
  final bool dosLados;
  final Function(Map<String, String>) onCapturado;

  const _CapturadoWidget({
    required this.tipoDocumento,
    required this.tiposDocMap,
    required this.dosLados,
    required this.onCapturado,
  });

  @override
  State<_CapturadoWidget> createState() => _CapturadoWidgetState();
}

class _CapturadoWidgetState extends State<_CapturadoWidget> {
  int paso = 1;
  String? rutaFrente;
  String? rutaReverso;
  String? rutaUnico;
  final ImagePicker _picker = ImagePicker();

  Future<void> _capturarFoto(int numeroPaso) async {
    final foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (foto != null) {
      setState(() {
        if (widget.dosLados) {
          if (numeroPaso == 1) {
            rutaFrente = foto.path;
            paso = 2;
          } else {
            rutaReverso = foto.path;
            paso = 3;
          }
        } else {
          rutaUnico = foto.path;
          paso = 3;
        }
      });
    }
  }

  void _recapturarFoto(int numeroPaso) {
    setState(() {
      if (widget.dosLados) {
        if (numeroPaso == 1) {
          rutaFrente = null;
        } else {
          rutaReverso = null;
        }
        paso = numeroPaso;
      } else {
        rutaUnico = null;
        paso = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85, // 85% del alto de la pantalla
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header fijo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Capturar ${widget.tiposDocMap[widget.tipoDocumento]?['label'] ?? 'Documento'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D21),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          // Contenido desplazable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (paso == 1)
                    _buildPasoCaptura(
                      numero: 1,
                      total: widget.dosLados ? 2 : 1,
                      titulo: '📷 Captura el FRENTE',
                      descripcion: 'Asegúrate de que toda la información sea legible y esté bien iluminada',
                      onCapturar: () => _capturarFoto(1),
                    )
                  else if (paso == 2)
                    _buildPasoCaptura(
                      numero: 2,
                      total: 2,
                      titulo: '📷 Captura el REVERSO',
                      descripcion: 'Toma una foto clara del reverso del documento',
                      onCapturar: () => _capturarFoto(2),
                    )
                  else
                    _buildPasoConfirmacion(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasoCaptura({
    required int numero,
    required int total,
    required String titulo,
    required String descripcion,
    required VoidCallback onCapturar,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Indicador de progreso
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: List.generate(
                total,
                    (index) => Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: index < total - 1 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index < numero ? Colors.blue : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Icono ilustrativo
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: 50,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // Textos
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D21),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            descripcion,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),

          // Botón de acción
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCapturar,
              icon: const Icon(Icons.camera_alt, size: 22),
              label: const Text(
                'Abrir Cámara',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: Colors.blue.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botón secundario
          if (numero > 1)
            TextButton(
              onPressed: () => _recapturarFoto(numero - 1),
              child: const Text(
                'Volver al paso anterior',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasoConfirmacion() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header de confirmación
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 32,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Fotos Capturadas!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D21),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.dosLados
                    ? 'Revisa que ambas fotos sean legibles'
                    : 'Revisa que la foto sea legible',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Grid de previews responsive
        if (widget.dosLados)
          _buildGridDosLados()
        else
          _buildPreviewUnico(),

        const SizedBox(height: 32),

        // Botones de acción
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (widget.dosLados) {
                      _recapturarFoto(1);
                    } else {
                      _recapturarFoto(1);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Volver a Capturar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.dosLados) {
                      widget.onCapturado({
                        'frente': rutaFrente!,
                        'reverso': rutaReverso!,
                      });
                    } else {
                      widget.onCapturado({
                        'unico': rutaUnico!,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Confirmar y Subir',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGridDosLados() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 350;
        final imageSize = isSmallScreen ? 120.0 : 140.0;

        return Row(
          children: [
            Expanded(
              child: _buildPreviewItem(
                titulo: 'FRENTE',
                ruta: rutaFrente!,
                imageSize: imageSize,
                onRetake: () => _recapturarFoto(1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPreviewItem(
                titulo: 'REVERSO',
                ruta: rutaReverso!,
                imageSize: imageSize,
                onRetake: () => _recapturarFoto(2),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewUnico() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = constraints.maxWidth * 0.6;

        return _buildPreviewItem(
          titulo: 'DOCUMENTO',
          ruta: rutaUnico!,
          imageSize: imageSize,
          onRetake: () => _recapturarFoto(1),
        );
      },
    );
  }

  Widget _buildPreviewItem({
    required String titulo,
    required String ruta,
    required double imageSize,
    required VoidCallback onRetake,
  }) {
    return Column(
      children: [
        // Badge del tipo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Contenedor de la imagen
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Imagen
                Image.file(
                  File(ruta),
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                ),

                // Botón de retomar en esquina
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onRetake,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Texto de retomar
        GestureDetector(
          onTap: onRetake,
          child: Text(
            'Retomar',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}