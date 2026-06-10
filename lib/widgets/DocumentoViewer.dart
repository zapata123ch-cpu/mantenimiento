import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DocumentoViewer extends StatefulWidget {
  final String url;
  final String titulo;

  const DocumentoViewer({
    Key? key,
    required this.url,
    required this.titulo,
  }) : super(key: key);

  @override
  State<DocumentoViewer> createState() => _DocumentoViewerState();
}

class _DocumentoViewerState extends State<DocumentoViewer> with SingleTickerProviderStateMixin {
  static const Color _primaryColor = Color(0xFF3B82F6);
  static const Color _accentColor = Color(0xFF60A5FA);
  static const Color _darkColor = Color(0xFF0F172A);
  static const Color _lightColor = Color(0xFFF8FAFC);
  static const Color _successColor = Color(0xFF10B981);

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  double _progreso = 0.0;
  bool _estaDescargando = false;
  String? _rutaArchivoDescargado;
  bool _showParticles = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showParticles = false);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _obtenerTipoArchivo(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();

    if (path.endsWith('.pdf')) return 'pdf';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'jpg';
    if (path.endsWith('.png')) return 'png';
    if (path.endsWith('.gif')) return 'gif';

    return 'imagen';
  }

  Future<bool> _solicitarPermisos() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> _descargarYMostrarArchivo() async {
    try {
      _animationController.reset();
      _animationController.forward();
      setState(() => _showParticles = true);

      final permisosOtorgados = await _solicitarPermisos();
      if (!permisosOtorgados) {
        _mostrarError('Se necesitan permisos de almacenamiento');
        return;
      }

      final carpetaApp = await getApplicationDocumentsDirectory();
      final carpetaDescargas = '${carpetaApp.path}/downloads';

      final dir = Directory(carpetaDescargas);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final tipoArchivo = _obtenerTipoArchivo(widget.url);
      final extension = tipoArchivo == 'pdf' ? 'pdf' : 'jpg';
      final nombreArchivo = _obtenerNombreArchivo(widget.titulo, extension);
      final rutaArchivo = '$carpetaDescargas/$nombreArchivo';

      final dio = Dio();

      setState(() {
        _estaDescargando = true;
        _progreso = 0.0;
        _rutaArchivoDescargado = null;
      });

      await dio.download(
        widget.url,
        rutaArchivo,
        onReceiveProgress: (recibido, total) {
          if (total != -1) {
            setState(() => _progreso = recibido / total);
          }
        },
        deleteOnError: true,
      );

      setState(() {
        _estaDescargando = false;
        _rutaArchivoDescargado = rutaArchivo;
      });

      if (!mounted) return;
      _mostrarNotificacionExito(rutaArchivo);

    } catch (e) {
      if (!mounted) return;
      setState(() => _estaDescargando = false);
      _mostrarError('Error al descargar: $e');
    }
  }

  String _obtenerNombreArchivo(String titulo, String extension) {
    final nombreLimpio = titulo
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[-\s]+'), '_')
        .toLowerCase();
    return '${nombreLimpio}_${DateTime.now().millisecondsSinceEpoch}.$extension';
  }

  Future<void> _abrirArchivo(String rutaArchivo) async {
    try {
      final resultado = await OpenFile.open(rutaArchivo);
      if (resultado.type != ResultType.done) {
        _mostrarError('No se pudo abrir: ${resultado.message}');
      }
    } catch (e) {
      _mostrarError('Error al abrir: $e');
    }
  }

  void _mostrarNotificacionExito(String rutaArchivo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _successColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Descarga completada',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Text(
                    'Documento guardado correctamente',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'ABRIR',
          textColor: Colors.white,
          backgroundColor: _successColor.withOpacity(0.8),
          onPressed: () => _abrirArchivo(rutaArchivo),
        ),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje, style: const TextStyle(color: Colors.white))),
          ],
        ),
        action: SnackBarAction(
          label: 'CERRAR',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _lightColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)],
            ),
          ),
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: _progreso,
              strokeWidth: 6,
              backgroundColor: _lightColor,
              valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
          Text(
            '${(_progreso * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkColor),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 400),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: widget.url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: _lightColor,
            child: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_primaryColor))),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.red.shade100,
            child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipoArchivo = _obtenerTipoArchivo(widget.url);

    return Scaffold(
      backgroundColor: _lightColor,
      appBar: AppBar(
        title: Text(widget.titulo, style: const TextStyle(fontWeight: FontWeight.w700, color: _darkColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _darkColor,
        centerTitle: true,
        actions: [
          if (_rutaArchivoDescargado != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.open_in_new_rounded, color: _primaryColor),
                onPressed: () => _abrirArchivo(_rutaArchivoDescargado!),
                tooltip: 'Abrir archivo',
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_lightColor, _lightColor, Colors.white],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) => Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(opacity: _fadeAnimation.value, child: child),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono según tipo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_primaryColor, _accentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: Icon(
                        tipoArchivo == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.titulo,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _darkColor, height: 1.2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _estaDescargando
                          ? 'Descargando documento...'
                          : _rutaArchivoDescargado != null
                          ? '¡Listo para revisar!'
                          : 'Presiona descargar para obtener el documento',
                      style: TextStyle(fontSize: 16, color: _darkColor.withOpacity(0.6), fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Preview si es imagen
                    if (tipoArchivo != 'pdf' && !_estaDescargando) ...[
                      _buildImagePreview(),
                      const SizedBox(height: 40),
                    ],

                    // Indicador de progreso
                    if (_estaDescargando)
                      _buildProgressIndicator()
                    else if (_rutaArchivoDescargado != null)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _successColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: _successColor.withOpacity(0.3), width: 2),
                        ),
                        child: const Icon(Icons.check_rounded, size: 40, color: _successColor),
                      )
                    else
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.download_rounded, size: 40, color: _primaryColor),
                      ),

                    const SizedBox(height: 40),

                    // Botones
                    if (_rutaArchivoDescargado == null)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _estaDescargando ? null : _descargarYMostrarArchivo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: _primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_estaDescargando ? Icons.downloading_rounded : Icons.download_rounded, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                _estaDescargando ? 'DESCARGANDO...' : 'DESCARGAR',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _abrirArchivo(_rutaArchivoDescargado!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _successColor,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: _successColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.open_in_browser_rounded, size: 24),
                              SizedBox(width: 12),
                              Text('ABRIR DOCUMENTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _descargarYMostrarArchivo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: const BorderSide(color: _primaryColor, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh_rounded, size: 24),
                              SizedBox(width: 12),
                              Text('DESCARGAR NUEVAMENTE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    if (!_estaDescargando && _rutaArchivoDescargado == null)
                      Text(
                        tipoArchivo == 'pdf' ? 'Formato PDF • Descarga segura' : 'Imagen • Descarga segura',
                        style: TextStyle(fontSize: 12, color: _darkColor.withOpacity(0.4), fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}