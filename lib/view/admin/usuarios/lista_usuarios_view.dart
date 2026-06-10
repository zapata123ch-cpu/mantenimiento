import 'package:flutter/material.dart';
import '../../../controller/usuarios_controller.dart';
import '../../../widgets/NotificationService.dart';
import '../../auth/registrar_view.dart';
import 'detalle_usuario_view.dart';

class ListaUsuariosView extends StatefulWidget {
  const ListaUsuariosView({super.key});

  @override
  State<ListaUsuariosView> createState() => _ListaUsuariosViewState();
}

class _ListaUsuariosViewState extends State<ListaUsuariosView>
    with TickerProviderStateMixin {
  final UsuariosController _controller = UsuariosController();
  late Future<List<Map<String, dynamic>>> _usuariosFuture;
  late TabController _tabController;

  String _filtroEstadoConductores = 'Todos';
  String _filtroEstadoAdmins = 'Todos';
  String _filtroEstadoGeneral = 'Todos';
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _usuariosFuture = _controller.obtenerTodosUsuarios();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _recargarUsuarios() {
    setState(() {
      _usuariosFuture = _controller.obtenerTodosUsuarios();
    });
  }

  Future<void> _aprobarUsuario(String userId) async {
    try {
      await _controller.aprobarUsuario(userId);
      _recargarUsuarios();
      NotificationService.showSuccess(
          context, '✅ Usuario aprobado exitosamente');
    } catch (e) {
      NotificationService.showError(context, '❌ Error al aprobar: $e');
    }
  }

  Future<void> _rechazarUsuario(String userId) async {
    try {
      await _controller.rechazarUsuario(userId);
      _recargarUsuarios();
      NotificationService.showSuccess(context, '✅ Usuario rechazado');
    } catch (e) {
      NotificationService.showError(context, '❌ Error al rechazar: $e');
    }
  }

  Future<void> _eliminarRol(String userId) async {
    try {
      await _controller.asignarRol(userId, '');
      _recargarUsuarios();
      NotificationService.showSuccess(context, '✅ Rol eliminado exitosamente');
    } catch (e) {
      NotificationService.showError(context, '❌ Error al eliminar rol: $e');
    }
  }

  Future<void> _asignarRol(String userId, String rol) async {
    try {
      await _controller.asignarRol(userId, rol);
      _recargarUsuarios();
      NotificationService.showSuccess(
          context, '✅ Rol $rol asignado exitosamente');
    } catch (e) {
      NotificationService.showError(context, '❌ Error al asignar rol: $e');
    }
  }

  Future<void> _eliminarUsuario(String userId) async {
    try {
      await _controller.eliminarUsuario(userId);
      _recargarUsuarios();
      NotificationService.showSuccess(
          context, '✅ Usuario eliminado exitosamente');
    } catch (e) {
      NotificationService.showError(context, '❌ Error al eliminar: $e');
    }
  }

  void _mostrarDialogoEliminacion(
      BuildContext context, String userId, String nombreUsuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Eliminar a $nombreUsuario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarUsuario(userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue.shade600,
          labelColor: Colors.blue.shade600,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Conductores'),
            Tab(text: 'Admins'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildRolTab('Conductores', 'Conductor', _filtroEstadoConductores,
                  (valor) => setState(() => _filtroEstadoConductores = valor)),
          _buildRolTab('Administradores', 'Admin', _filtroEstadoAdmins,
                  (valor) => setState(() => _filtroEstadoAdmins = valor)),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return Column(
      children: [
        _buildHeaderBusqueda(_filtroEstadoGeneral, (valor) {
          setState(() => _filtroEstadoGeneral = valor);
        }),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _usuariosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoading();
              }
              if (snapshot.hasError) {
                return _buildError();
              }

              final usuarios = snapshot.data ?? [];
              final usuariosSinRol = usuarios.where((u) {
                final rol = u['rol'] as String?;
                return rol == null || rol.isEmpty;
              }).toList();

              final usuariosFiltrados =
              _controller.buscarUsuarios(usuariosSinRol, _busqueda);
              final usuariosConFiltro =
              _controller.filtrarPorEstado(usuariosFiltrados, _filtroEstadoGeneral);

              if (usuariosConFiltro.isEmpty) {
                return _buildEmpty('Sin usuarios sin rol');
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: usuariosConFiltro.length,
                itemBuilder: (context, index) {
                  final usuario = usuariosConFiltro[index];
                  return _usuarioCard(context, usuario, esGeneral: true);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRolTab(String nombreRol, String rol, String filtroEstado,
      Function(String) onFiltroChanged) {
    return Column(
      children: [
        _buildHeaderBusqueda(filtroEstado, onFiltroChanged),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _usuariosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoading();
              }
              if (snapshot.hasError) {
                return _buildError();
              }

              final usuarios = snapshot.data ?? [];
              final usuariosFiltrados =
              usuarios.where((u) => u['rol'] == rol).toList();

              final usuariosConFiltro = _controller.filtrarPorEstado(
                _controller.buscarUsuarios(usuariosFiltrados, _busqueda),
                filtroEstado,
              );

              if (usuariosConFiltro.isEmpty) {
                return _buildEmpty('Sin $nombreRol');
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: usuariosConFiltro.length,
                itemBuilder: (context, index) {
                  final usuario = usuariosConFiltro[index];
                  return _usuarioCard(context, usuario, esGeneral: false);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBusqueda(String filtro, Function(String) onFiltroChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _busqueda = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar usuario...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                onSelected: onFiltroChanged,
                itemBuilder: (BuildContext context) => [
                  'Todos',
                  'Pendiente',
                  'Aprobado',
                  'Rechazado'
                ]
                    .map((String choice) => PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                    children: [
                      _buildEstadoIcon(choice),
                      const SizedBox(width: 8),
                      Text(choice),
                    ],
                  ),
                ))
                    .toList(),
                icon: Icon(Icons.filter_list, color: Colors.grey.shade600),
                tooltip: 'Filtro',
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrarView()),
                  ).then((_) => _recargarUsuarios());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Icon(Icons.add, size: 20, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoIcon(String estado) {
    final color = _getEstadoColor(estado);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(
          estado == 'Pendiente'
              ? Icons.schedule
              : estado == 'Aprobado'
              ? Icons.check_circle
              : estado == 'Rechazado'
              ? Icons.cancel
              : Icons.all_inclusive,
          size: 12,
          color: color,
        ),
      ),
    );
  }
  Widget _usuarioCard(BuildContext context, Map<String, dynamic> usuario,
      {required bool esGeneral}) {
    final estado = usuario['estado'] as String? ?? 'Desconocido';
    final estadoColor = _getEstadoColor(estado);
    final rol = usuario['rol'] as String? ?? 'Sin rol';
    final dni = usuario['dni'] as String? ?? 'N/A';
    final telefono = usuario['telefono'] as String? ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleUsuarioView(usuario: usuario),
            ),
          ).then((_) => _recargarUsuarios());
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Header con datos y menú
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person, color: Colors.blue.shade600, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${usuario['nombres'] ?? ''} ${usuario['apellidos'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            usuario['email'] ?? 'Sin email',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: estadoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        estado,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: estadoColor,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'ver') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetalleUsuarioView(usuario: usuario),
                            ),
                          ).then((_) => _recargarUsuarios());
                        } else if (value == 'eliminar') {
                          _mostrarDialogoEliminacion(
                            context,
                            usuario['uid'],
                            usuario['nombres'],
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'ver',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 16),
                              SizedBox(width: 8),
                              Text('Ver detalles'),
                            ],
                          ),
                        ),

                        const PopupMenuDivider(),

                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      icon: Icon(Icons.more_vert,
                          size: 18, color: Colors.grey.shade600),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Información adicional
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem('DNI', dni, Icons.badge),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoItem('Teléfono', telefono, Icons.phone),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoItem('Rol', rol, Icons.security),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Acciones principales
                if (estado == 'Pendiente')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _aprobarUsuario(usuario['uid']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Aprobar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _rechazarUsuario(usuario['uid']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Rechazar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ),
                    ],
                  )
                // NUEVA LÓGICA: Si es Rechazado y es la pestaña General, mostrar 'Cambiar a Aprobado'
                else if (estado == 'Rechazado' && esGeneral)
                  ElevatedButton(
                    onPressed: () => _aprobarUsuario(usuario['uid']), // Llama a la función de APROBAR
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const SizedBox(
                      width: double.infinity,
                      child: Text('Cambiar a Aprobado', // Texto solicitado
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  )
                // LÓGICA ORIGINAL: Asignar Rol (ahora se ejecuta para 'Aprobado' en pestaña General)
                else if (esGeneral)
                    ElevatedButton(
                      onPressed: () => _mostrarDialogoAsignarRol(
                        context,
                        usuario['uid'],
                        usuario['nombres'],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const SizedBox(
                        width: double.infinity,
                        child: Text('Asignar Rol',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    )


                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _eliminarRol(usuario['uid']),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: BorderSide(color: Colors.orange.shade600),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Quitar Rol',
                                style: TextStyle(
                                  color: Colors.orange.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoAsignarRol(
      BuildContext context, String userId, String nombreUsuario) {
    String? rolSeleccionado;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            contentPadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
            titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
            actionsPadding: const EdgeInsets.all(20),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Asignar Rol',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 24,
                    color: Colors.grey.shade600,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona el rol para $nombreUsuario',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Opción Conductor
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: rolSeleccionado == 'Conductor'
                          ? Colors.blue.shade800
                          : Colors.grey.shade300,
                      width: rolSeleccionado == 'Conductor' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: rolSeleccionado == 'Conductor'
                        ? Colors.blue.shade50
                        : Colors.grey.shade50,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          rolSeleccionado = 'Conductor';
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: rolSeleccionado == 'Conductor'
                                      ? Colors.blue.shade800
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                                color: rolSeleccionado == 'Conductor'
                                    ? Colors.blue.shade800
                                    : Colors.transparent,
                              ),
                              child: rolSeleccionado == 'Conductor'
                                  ? Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Conductor',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Puede gestionar vehículos y realizar mantenimientos',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Opción Admin
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: rolSeleccionado == 'Admin'
                          ? Colors.blue.shade800
                          : Colors.grey.shade300,
                      width: rolSeleccionado == 'Admin' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: rolSeleccionado == 'Admin'
                        ? Colors.blue.shade50
                        : Colors.grey.shade50,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          rolSeleccionado = 'Admin';
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: rolSeleccionado == 'Admin'
                                      ? Colors.blue.shade800
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                                color: rolSeleccionado == 'Admin'
                                    ? Colors.blue.shade800
                                    : Colors.transparent,
                              ),
                              child: rolSeleccionado == 'Admin'
                                  ? Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Administrador',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Acceso completo al sistema y gestión de usuarios',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
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
            // ACCIONES (BOTONES) AÑADIDOS AQUÍ
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Botón Cancelar
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Botón Asignar Rol
                  ElevatedButton(
                    onPressed: rolSeleccionado == null
                        ? null // Deshabilitado si no hay rol seleccionado
                        : () {
                      Navigator.pop(context); // Cierra el diálogo
                      _asignarRol(userId, rolSeleccionado!); // Llama a la acción
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Asignar Rol',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 12),
          Text('Cargando...', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text('Error al cargar', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _recargarUsuarios,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(mensaje, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.amber.shade600;
      case 'Aprobado':
        return Colors.green.shade600;
      case 'Rechazado':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }
}