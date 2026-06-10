// lib/view/test/test_notification_view.dart

import 'package:carmanten/widgets/NotificationService.dart';
import 'package:flutter/material.dart';

class TestNotificationView extends StatelessWidget {
  const TestNotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      appBar: AppBar(
        title: const Text('Test Notificaciones'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón Éxito
            SizedBox(
              width: 250,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  NotificationService.showSuccess(
                    context,
                    'Operación completada exitosamente',
                  );
                },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Mostrar Éxito'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botón Error
            SizedBox(
              width: 250,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  NotificationService.showError(
                    context,
                    'Algo salió mal, intenta nuevamente',
                  );
                },
                icon: const Icon(Icons.error_rounded),
                label: const Text('Mostrar Error'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botón Alerta
            SizedBox(
              width: 250,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  NotificationService.showWarning(
                    context,
                    'Por favor verifica tus datos antes de continuar',
                  );
                },
                icon: const Icon(Icons.warning_rounded),
                label: const Text('Mostrar Alerta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFABF24),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}