import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/controller/alertas_controller.dart';

class NotificacionesView extends StatefulWidget {
  final String usuarioActualId;

  const NotificacionesView({super.key, required this.usuarioActualId});

  @override
  State<NotificacionesView> createState() => _NotificacionesViewState();
}

class _NotificacionesViewState extends State<NotificacionesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificacionesController _ctrl = NotificacionesController();

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
          'Notificaciones',
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
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDDDDDD), Color(0xFFD1D1D1)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              tabs: [
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.build_circle_outlined, size: 18),
                      const SizedBox(width: 6),
                      StreamBuilder<QuerySnapshot>(
                        stream: _ctrl.streamMantenimientos(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData
                              ? snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return _ctrl.esMantenimientoRelevante(data, widget.usuarioActualId) &&
                                !_ctrl.estaOculta(doc.id);
                          }).length
                              : 0;

                          return count > 0
                              ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
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
                        stream: _ctrl.streamFallas(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData
                              ? snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return _ctrl.esFallaRelevante(data, widget.usuarioActualId) &&
                                !_ctrl.estaOculta(doc.id);
                          }).length
                              : 0;

                          return count > 0
                              ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF44336),
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
          // PESTAÑA 1: MANTENIMIENTOS
          _buildMantenimientosTab(),

          // PESTAÑA 2: FALLAS
          _buildFallasTab(),
        ],
      ),
    );
  }

  Widget _buildMantenimientosTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ctrl.streamMantenimientos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final mantenimientos = snapshot.hasData
            ? snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _ctrl.esMantenimientoRelevante(data, widget.usuarioActualId) &&
              !_ctrl.estaOculta(doc.id);
        }).toList()
            : [];

        if (mantenimientos.isEmpty) {
          return _buildEmptyState(
            icon: Icons.build_circle_outlined,
            title: 'No hay mantenimientos',
            subtitle: 'Los mantenimientos programados aparecerán aquí',
            color: const Color(0xFF2196F3),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header informativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2196F3).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF2196F3),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Mantenimientos programados',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0A1A2F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lista de mantenimientos
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mantenimientos.length,
                itemBuilder: (context, index) {
                  final doc = mantenimientos[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;
                  final estadoMantenimiento = data['estado'] ?? 'Pendiente'; // Valor por defecto 'Pendiente'

                  // === LÓGICA DE COLOR E ICONO CONDICIONAL ===
                  late Color accent;
                  late Color backgroundColor;
                  late IconData icono;

                  if (estadoMantenimiento == 'Aceptado') { // Asumiendo 'Completado' es el estado "aceptado" o "listo"
                    accent = const Color(0xFF00C853);      // Verde
                    backgroundColor = const Color(0xFFE8F5E8);
                    icono = Icons.check_circle_rounded;
                  } else if (estadoMantenimiento == 'Urgente' || estadoMantenimiento == 'Pendiente') {
                    accent = const Color(0xFFFF7700);      // Amarillo/Ámbar (similar a fallas 'En reparación')
                    backgroundColor = const Color(0xFFFFF8E1);
                    icono = Icons.build_circle_rounded;
                  } else {
                    // Estado por defecto (si no coincide con nada)
                    accent = const Color(0xFF2196F3);      // Azul
                    backgroundColor = const Color(0xFFE3F2FD);
                    icono = Icons.build_rounded;
                  }
                  // ===========================================

                  return _buildNotificationCard(
                    docId: docId,
                    titulo: 'Mantenimiento $estadoMantenimiento',
                    mensaje: 'Tipo: ${data['tipoServicio'] ?? '-'}\nObs: ${data['observaciones'] ?? '-'}',
                    fecha: data['fechaProgramada'] != null
                        ? _ctrl.formatDate(data['fechaProgramada'])
                        : (data['createdAt'] != null ? _ctrl.formatDate(data['createdAt']) : 'Sin fecha'),
                    accent: accent,
                    backgroundColor: backgroundColor,
                    icono: icono,
                    tipo: 'mantenimiento',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildFallasTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ctrl.streamFallas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final fallas = snapshot.hasData
            ? snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _ctrl.esFallaRelevante(data, widget.usuarioActualId) &&
              !_ctrl.estaOculta(doc.id);
        }).toList()
            : [];

        if (fallas.isEmpty) {
          return _buildEmptyState(
            icon: Icons.warning_amber_rounded,
            title: 'No hay fallas reportadas',
            subtitle: 'Las fallas reportadas aparecerán aquí',
            color: const Color(0xFFF44336),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header informativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF44336).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFF44336),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Estado de las fallas reportadas en tus vehículos',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0A1A2F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lista de fallas
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fallas.length,
                itemBuilder: (context, index) {
                  final doc = fallas[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;
                  final estadoFalla = data['estado'] ?? 'N/A';

                  late Color accent;
                  late Color backgroundColor;
                  late IconData icono;

                  if (estadoFalla == 'Resuelto') {
                    accent = const Color(0xFF00C853);
                    backgroundColor = const Color(0xFFE8F5E8);
                    icono = Icons.done_all_rounded;
                  } else if (estadoFalla == 'En reparación') {
                    accent = const Color(0xFFFFB300);
                    backgroundColor = const Color(0xFFFFF8E1);
                    icono = Icons.build_rounded;
                  } else {
                    accent = const Color(0xFFF44336);
                    backgroundColor = const Color(0xFFFFEBEE);
                    icono = Icons.warning_rounded;
                  }

                  return _buildNotificationCard(
                    docId: docId,
                    titulo: 'Falla $estadoFalla',
                    mensaje: 'Tipo: ${data['tipoFalla'] ?? '-'}\nDesc: ${data['descripcion'] ?? '-'}',
                    fecha: data['fechaReporte'] != null
                        ? _ctrl.formatDate(data['fechaReporte'])
                        : (data['createdAt'] != null ? _ctrl.formatDate(data['createdAt']) : 'Sin fecha'),
                    accent: accent,
                    backgroundColor: backgroundColor,
                    icono: icono,
                    tipo: 'falla',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required String docId,
    required String titulo,
    required String mensaje,
    required String fecha,
    required Color accent,
    required Color backgroundColor,
    required IconData icono,
    required String tipo,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Indicador lateral
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icono,
                    color: accent,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Contenido textual
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A1A2F),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mensaje,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fecha,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
}