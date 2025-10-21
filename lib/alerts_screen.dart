import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alertas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAlertCard(
            title: 'Alerta de Seguridad',
            message: 'Se reportó actividad sospechosa cerca del Edificio C. Mantente alerta.',
            time: 'Hace 15 minutos',
            priority: 'high',
            icon: Icons.warning,
          ),
          const SizedBox(height: 12),
          _buildAlertCard(
            title: 'Información General',
            message: 'Mantenimiento programado en estacionamiento norte mañana de 8-10 AM.',
            time: 'Hace 2 horas',
            priority: 'medium',
            icon: Icons.info,
          ),
          const SizedBox(height: 12),
          _buildAlertCard(
            title: 'Evento en Campus',
            message: 'Simulacro de evacuación programado para el viernes a las 10:00 AM.',
            time: 'Hace 5 horas',
            priority: 'low',
            icon: Icons.event,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String message,
    required String time,
    required String priority,
    required IconData icon,
  }) {
    Color priorityColor;
    Color bgColor;
    
    switch (priority) {
      case 'high':
        priorityColor = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEE2E2);
        break;
      case 'medium':
        priorityColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      default:
        priorityColor = const Color(0xFF2563EB);
        bgColor = const Color(0xFFDCE7F8);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}