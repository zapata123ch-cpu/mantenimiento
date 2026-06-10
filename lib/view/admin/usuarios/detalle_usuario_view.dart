import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetalleUsuarioView extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const DetalleUsuarioView({super.key, required this.usuario});

  @override
  State<DetalleUsuarioView> createState() => _DetalleUsuarioViewState();
}

class _DetalleUsuarioViewState extends State<DetalleUsuarioView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Detalle de Usuario',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // TARJETA DE USUARIO
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded,
                          size: 44, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.usuario['nombres'] ?? 'N/A'} ${widget.usuario['apellidos'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.usuario['email'] ?? 'Sin email',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge(
                        'Estado',
                        widget.usuario['estado'] ?? 'N/A',
                        _getEstadoColor(widget.usuario['estado'] ?? ''),
                      ),
                      const SizedBox(width: 12),
                      _buildBadge(
                        'Rol',
                        widget.usuario['rol'] ?? 'Sin rol',
                        _getRolColor(widget.usuario['rol'] ?? ''),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'DNI',
                          widget.usuario['dni'] ?? 'N/A',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoItem(
                          'Teléfono',
                          widget.usuario['telefono'] ?? 'N/A',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // DOCUMENTOS
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Documentos Subidos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(widget.usuario['uid'])
                        .collection('documentos')
                        .orderBy('fechaCarga', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.folder_open_outlined,
                                  size: 48,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text(
                                'Sin documentos subidos',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index];
                          var data = doc.data() as Map<String, dynamic>;

                          return _buildDocumentoCard(
                            docId: doc.id,
                            data: data,
                            usuarioId: widget.usuario['uid'],
                          );
                        },
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

  Widget _buildDocumentoCard({
    required String docId,
    required Map<String, dynamic> data,
    required String usuarioId,
  }) {
    final estado = data['estado'] ?? 'pendiente_revision';
    final isPendiente = estado == 'pendiente_revision';
    final tipoDocumento = data['tipoDocumento'] ?? 'Documento';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipoDocumento,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cargado: ${DateFormat('dd/MM/yyyy HH:mm').format((data['fechaCarga'] as Timestamp).toDate())}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPendiente
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPendiente
                          ? Colors.orange.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    isPendiente ? 'Pendiente' : 'Aprobado',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPendiente
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Imágenes/Documentos
            if (data['urlFrente'] != null)
              _buildFotosRow(data, tipoDocumento),

            const SizedBox(height: 16),

            // Botones de acción
            if (isPendiente)
              Row(
                children: [
                  Expanded(
                    child: _buildBotonAccion(
                      label: 'Aprobar',
                      color: Colors.green,
                      icon: Icons.check_circle_outline,
                      onPressed: () =>
                          _aprobarDocumento(docId, usuarioId, tipoDocumento),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildBotonAccion(
                      label: 'Rechazar',
                      color: Colors.red,
                      icon: Icons.cancel_outlined,
                      onPressed: () => _rechazarDocumento(
                        docId,
                        usuarioId,
                        tipoDocumento,
                      ),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: Chip(
                  label: const Text('Aprobado'),
                  backgroundColor: Colors.green.shade50,
                  labelStyle: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotosRow(Map<String, dynamic> data, String tipoDocumento) {
    final tieneFrente = data['urlFrente'] != null;
    final tieneReverso = data['urlReverso'] != null;
    final tieneDocumento = data['urlDocumento'] != null;

    if (tieneFrente && tieneReverso) {
      return Row(
        children: [
          Expanded(
            child: _buildFotoPreview(
              titulo: 'FRENTE',
              url: data['urlFrente'],
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFotoPreview(
              titulo: 'REVERSO',
              url: data['urlReverso'],
              color: Colors.purple,
            ),
          ),
        ],
      );
    } else if (tieneDocumento) {
      return _buildFotoPreview(
        titulo: tipoDocumento,
        url: data['urlDocumento'],
        color: Colors.blue,
        fullWidth: true,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFotoPreview({
    required String titulo,
    required String url,
    required Color color,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: () => _mostrarImagenPreview(url),
      child: Container(
        height: fullWidth ? 150 : 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          color: color.withOpacity(0.05),
        ),
        child: Stack(
          children: [
            // Imagen de fondo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
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
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.grey),
                  );
                },
              ),
            ),

            // Badge del lado
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Icono de ver
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.zoom_in_rounded,
                    size: 24, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonAccion({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _aprobarDocumento(
      String docId,
      String usuarioId,
      String tipoDocumento,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuarioId)
          .collection('documentos')
          .doc(docId)
          .update({'estado': 'aprobado'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documento aprobado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rechazarDocumento(
      String docId,
      String usuarioId,
      String tipoDocumento,
      ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Documento'),
        content: const Text('¿Estás seguro de que deseas rechazar este documento? Se eliminará permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(usuarioId)
                    .collection('documentos')
                    .doc(docId)
                    .delete();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Documento rechazado y eliminado'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarImagenPreview(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Vista Previa'),
              automaticallyImplyLeading: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0.5,
            ),
            Expanded(
              child: Image.network(
                url,
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
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text('Error cargando imagen'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.amber.shade500;
      case 'Aprobado':
        return Colors.green.shade500;
      case 'Rechazado':
        return Colors.red.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  Color _getRolColor(String rol) {
    switch (rol) {
      case 'Conductor':
        return Colors.blue.shade500;
      case 'Admin':
        return Colors.purple.shade500;
      default:
        return Colors.grey.shade500;
    }
  }
}