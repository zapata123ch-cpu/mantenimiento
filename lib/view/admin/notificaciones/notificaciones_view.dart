import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '/controller/alertas_controller.dart';

class AlertasAdminView extends StatefulWidget {
  const AlertasAdminView({super.key});

  @override
  State<AlertasAdminView> createState() => _AlertasAdminViewState();
}

class _AlertasAdminViewState extends State<AlertasAdminView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AlertasAdminController _ctrl = AlertasAdminController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A1A2F),
        elevation: 0,
        title: const Text(
          'Alertas y Reportes',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0A1A2F),
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5252), Color(0xFFE53935)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              tabs: [
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_late_rounded, size: 18),
                      const SizedBox(width: 6),
                      StreamBuilder<QuerySnapshot>(
                        stream: _ctrl.streamChecklistsBadge(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData
                              ? snapshot.data!.docs.where((doc) => !_ctrl.estaOculta(doc.id)).length
                              : 0;
                          return count > 0
                              ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5252),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                              : const SizedBox();
                        },
                      ),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18),
                      const SizedBox(width: 6),
                      StreamBuilder<QuerySnapshot>(
                        stream: _ctrl.streamFallasBadge(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData
                              ? snapshot.data!.docs.where((doc) => !_ctrl.estaOculta(doc.id)).length
                              : 0;
                          return count > 0
                              ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                              : const SizedBox();
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChecklistsNoAptos(),
          _buildFallasPendientes(),
        ],
      ),
    );
  }

  // ==================== TAB 1: CHECKLISTS NO APTOS ====================
  Widget _buildChecklistsNoAptos() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ctrl.streamChecklistsListado(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'Sin alertas de checklists',
            subtitle: 'Todos los checklists están en estado APTO',
            color: const Color(0xFF00C853),
          );
        }

        // Filtrar localmente las notificaciones eliminadas
        final docsFiltrados = snapshot.data!.docs.where((doc) => !_ctrl.estaOculta(doc.id)).toList();

        if (docsFiltrados.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'Sin alertas de checklists',
            subtitle: 'Todos los checklists están en estado APTO',
            color: const Color(0xFF00C853),
          );
        }

        final checklists = docsFiltrados;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF5252).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.priority_high_rounded,
                        color: Color(0xFFFF5252),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vehículos marcados como NO APTOS',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0A1A2F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: checklists.length,
                itemBuilder: (context, index) {
                  final doc = checklists[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildChecklistCard(data, doc.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChecklistCard(Map<String, dynamic> data, String docId) {
    final vehiculoId = data['vehiculoId'] ?? 'Desconocido';
    final conductorId = data['conductorId'] ?? 'Sin conductor';
    final estado = data['estado'] ?? 'no apto';
    final observaciones = data['observaciones'] ?? 'Sin observaciones';
    final items = data['items'] as Map<String, dynamic>?;
    final fecha = data['createdAt'] ?? data['fecha'];

    List<String> itemsFallidos = [];
    if (items != null) {
      items.forEach((key, value) {
        if (value == false) {
          itemsFallidos.add(key.toUpperCase());
        }
      });
    }

    return FutureBuilder<Map<String, String>>(
      future: _ctrl.obtenerDatos(vehiculoId, conductorId),
      builder: (context, snapshot) {
        final placa = snapshot.data?['placa'] ?? vehiculoId;
        final nombreConductor = snapshot.data?['nombre'] ?? conductorId;

        return _buildChecklistCardUI(
          placa: placa,
          nombreConductor: nombreConductor,
          estado: estado,
          observaciones: observaciones,
          itemsFallidos: itemsFallidos,
          fecha: fecha,
          docId: docId,
        );
      },
    );
  }

  Widget _buildChecklistCardUI({
    required String placa,
    required String nombreConductor,
    required String estado,
    required String observaciones,
    required List<String> itemsFallidos,
    required dynamic fecha,
    required String docId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF5252).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5252).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5252),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF5252).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.assignment_late_rounded,
                        color: Color(0xFFFF5252),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Placa: $placa',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A1A2F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5252),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              estado.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildInfoRow(
                  Icons.person_rounded,
                  'Conductor',
                  nombreConductor,
                  const Color(0xFF2196F3),
                ),
                const SizedBox(height: 8),

                _buildInfoRow(
                  Icons.access_time_rounded,
                  'Fecha',
                  _formatDate(fecha),
                  const Color(0xFF64748B),
                ),
                const SizedBox(height: 12),

                if (itemsFallidos.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: Color(0xFFFF5252),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Items con falla:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A1A2F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: itemsFallidos.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF5252).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF5252),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                if (observaciones.isNotEmpty && observaciones != 'Sin observaciones') ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Observaciones:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0A1A2F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              observaciones,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: FALLAS REPORTADAS ====================
  Widget _buildFallasPendientes() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ctrl.streamFallasListado(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'Sin fallas reportadas',
            subtitle: 'No hay fallas reportadas en este momento',
            color: const Color(0xFF00C853),
          );
        }

        // Filtrar localmente las notificaciones eliminadas
        final docsFiltrados = snapshot.data!.docs.where((doc) => !_ctrl.estaOculta(doc.id)).toList();

        if (docsFiltrados.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'Sin fallas reportadas',
            subtitle: 'No hay fallas reportadas en este momento',
            color: const Color(0xFF00C853),
          );
        }

        final fallas = docsFiltrados;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFB300).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFFFB300),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Fallas reportadas por conductores',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0A1A2F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fallas.length,
                itemBuilder: (context, index) {
                  final doc = fallas[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildFallaCard(data, doc.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallaCard(Map<String, dynamic> data, String docId) {
    final vehiculoId = data['vehiculoId'] ?? 'Desconocido';
    final conductorId = data['conductorId'] ?? 'Sin conductor';
    final tipoFalla = data['tipoFalla'] ?? 'Sin especificar';
    final descripcion = data['descripcion'] ?? 'Sin descripción';
    final fotoUrl = data['fotoUrl'];
    final fecha = data['createdAt'];

    return FutureBuilder<Map<String, String>>(
      future: _ctrl.obtenerDatos(vehiculoId, conductorId),
      builder: (context, snapshot) {
        final placa = snapshot.data?['placa'] ?? vehiculoId;
        final nombreConductor = snapshot.data?['nombre'] ?? conductorId;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFB300).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFB300),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFB300).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFFB300),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Placa: $placa',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0A1A2F),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'REPORTADA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      Icons.build_circle_rounded,
                      'Tipo de Falla',
                      tipoFalla,
                      const Color(0xFFFF5252),
                    ),
                    const SizedBox(height: 8),

                    _buildInfoRow(
                      Icons.person_rounded,
                      'Conductor',
                      nombreConductor,
                      const Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 8),

                    _buildInfoRow(
                      Icons.access_time_rounded,
                      'Fecha',
                      _formatDate(fecha),
                      const Color(0xFF64748B),
                    ),
                    const SizedBox(height: 12),

                    if (fotoUrl != null) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          fotoUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.description_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Descripción:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0A1A2F),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                descripcion,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _obtenerDatos(String vehiculoId, String conductorId) {
    // Método auxiliar si en algún lugar se desea acceder directamente desde la vista.
    return _ctrl.obtenerDatos(vehiculoId, conductorId);
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A1A2F),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A1A2F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Sin fecha';

    try {
      if (date is Timestamp) {
        return DateFormat('dd/MM/yyyy HH:mm').format(date.toDate());
      } else if (date is String) {
        return date;
      }
      return 'Fecha inválida';
    } catch (e) {
      return 'Error fecha';
    }
  }
}