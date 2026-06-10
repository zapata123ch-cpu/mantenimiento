// lib/services/notification_service.dart

import 'package:flutter/material.dart';

enum NotificationType { success, error, warning }

class NotificationService {
  static void show(
      BuildContext context, {
        required String message,
        required NotificationType type,
        Duration duration = const Duration(seconds: 4),
      }) {
    late Color backgroundColor;
    late Color accentColor;
    late Color textColor;
    late IconData icon;

    switch (type) {
      case NotificationType.success:
        backgroundColor = const Color(0xFFF8FCFA);
        accentColor = const Color(0xFF00C853);
        textColor = const Color(0xFF1A1A1A);
        icon = Icons.check_rounded;
        break;
      case NotificationType.error:
        backgroundColor = const Color(0xFFFEF8F8);
        accentColor = const Color(0xFFF44336);
        textColor = const Color(0xFF1A1A1A);
        icon = Icons.close_rounded;
        break;
      case NotificationType.warning:
        backgroundColor = const Color(0xFFFFFBEB);
        accentColor = const Color(0xFFFFB300);
        textColor = const Color(0xFF1A1A1A);
        icon = Icons.info_rounded;
        break;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.95 + (0.05 * value),
                    child: child,
                  ),
                ),
              );
            },
            child: _DismissibleNotification(
              onDismiss: () => overlayEntry.remove(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: accentColor.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Icono con acento sutil
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: accentColor,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Mensaje
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Indicador de progreso y botón cerrar
                    GestureDetector(
                      onTap: () => overlayEntry.remove(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accentColor.withOpacity(0.3),
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.05),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.black.withOpacity(0.4),
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
      ),
    );

    overlay.insert(overlayEntry);

    // Animación de progreso
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: NotificationType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, type: NotificationType.error);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message: message, type: NotificationType.warning);
  }
}

class _DismissibleNotification extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const _DismissibleNotification({
    required this.child,
    required this.onDismiss,
  });

  @override
  State<_DismissibleNotification> createState() => _DismissibleNotificationState();
}

class _DismissibleNotificationState extends State<_DismissibleNotification> with SingleTickerProviderStateMixin {
  late AnimationController _dismissController;
  double _dragOffsetX = 0.0;
  double _dragOffsetY = 0.0;
  bool _isDismissing = false;
  bool _isPanning = false;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  void _handleDismiss({required double velocityX, required double velocityY}) {
    if (!_isDismissing) {
      _isDismissing = true;

      // Determinar dirección del desliz
      final double finalX = _dragOffsetX.abs() > 100 ? (_dragOffsetX > 0 ? 600 : -600) : _dragOffsetX;
      final double finalY = _dragOffsetY.abs() > 100 ? (_dragOffsetY < 0 ? -600 : _dragOffsetY) : _dragOffsetY;

      _dismissController.forward(from: 0.0).then((_) {
        widget.onDismiss();
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    _isPanning = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;

    setState(() {
      _dragOffsetX += details.delta.dx;
      _dragOffsetY += details.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDismissing) return;

    _isPanning = false;

    final velocityX = details.velocity.pixelsPerSecond.dx;
    final velocityY = details.velocity.pixelsPerSecond.dy;

    // Umbral para eliminar: más de 100px o velocidad significativa
    final bool shouldDismissX = _dragOffsetX.abs() > 100 || velocityX.abs() > 500;
    final bool shouldDismissY = _dragOffsetY.abs() > 100 || velocityY.abs() > 500;

    if (shouldDismissX || shouldDismissY) {
      _handleDismiss(velocityX: velocityX, velocityY: velocityY);
    } else {
      // Animar de vuelta a la posición original
      _animateReset();
    }
  }

  void _animateReset() {
    final resetController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    final resetX = Tween<double>(begin: _dragOffsetX, end: 0.0).animate(
      CurvedAnimation(parent: resetController, curve: Curves.easeOut),
    );

    final resetY = Tween<double>(begin: _dragOffsetY, end: 0.0).animate(
      CurvedAnimation(parent: resetController, curve: Curves.easeOut),
    );

    resetX.addListener(() {
      setState(() => _dragOffsetX = resetX.value);
    });

    resetY.addListener(() {
      setState(() => _dragOffsetY = resetY.value);
    });

    resetController.forward().then((_) {
      resetController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dragProgress = (_dragOffsetX.abs() + _dragOffsetY.abs()) / 300;
    final opacity = 1.0 - (dragProgress * 0.7).clamp(0.0, 0.7);
    final scale = 1.0 - (dragProgress * 0.1).clamp(0.0, 0.1);
    final rotation = _dragOffsetX * 0.001; // Rotación sutil

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _dismissController,
        builder: (context, child) {
          double animX = _dragOffsetX;
          double animY = _dragOffsetY;

          if (_isDismissing) {
            final progress = _dismissController.value;
            animX = _dragOffsetX + (_dragOffsetX > 0 ? 800 : -800) * progress;
            animY = _dragOffsetY + (_dragOffsetY < 0 ? -800 : 800) * progress;
          }

          return Transform.translate(
            offset: Offset(animX, animY),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: _isDismissing ? 1.0 - (_dismissController.value * 0.2) : scale,
                child: Opacity(
                  opacity: _isDismissing ? 1.0 - _dismissController.value : opacity,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _dismissController.dispose();
    super.dispose();
  }
}

class Timeline {
  final TickerProvider vsync;
  final List<_TimelineEntry> _entries = [];

  Timeline(this.vsync);

  void addTween<T>({
    required Tween<T> tween,
    required Duration duration,
    required Function(T) onUpdate,
    Duration delay = Duration.zero,
  }) {
    final controller = AnimationController(
      duration: duration,
      vsync: vsync,
    );

    final animation = tween.animate(controller);

    animation.addListener(() {
      onUpdate(animation.value);
    });

    _entries.add(_TimelineEntry(controller, delay));

    Future.delayed(delay, () {
      controller.forward();
    });
  }

  void dispose() {
    for (var entry in _entries) {
      entry.controller.dispose();
    }
  }
}

class _TimelineEntry {
  final AnimationController controller;
  final Duration delay;

  _TimelineEntry(this.controller, this.delay);
}