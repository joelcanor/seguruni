import 'package:flutter/material.dart';
import 'emergency_screen.dart';
import 'report_incident_screen.dart';
import 'security_map_screen.dart';
import 'alerts_screen.dart';
import 'accompaniment_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF9333EA)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFF2563EB),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'CampusGuard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.circle,
                  color: Color(0xFF10B981),
                  size: 12,
                ),
                SizedBox(width: 6),
                Text(
                  'Conectado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo y título
            const Icon(
              Icons.shield_outlined,
              color: Color(0xFF2563EB),
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'CampusGuard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu seguridad es nuestra prioridad',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 40),
            // Botón de Emergencia
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: Material(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencyScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.phone_in_talk,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'EMERGENCIA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Grid de opciones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildOptionCard(
                          context: context,
                          icon: Icons.camera_alt,
                          title: 'Reportar Incidente',
                          color: const Color(0xFFEA580C),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReportIncidentScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildOptionCard(
                          context: context,
                          icon: Icons.location_on,
                          title: 'Mapa de Seguridad',
                          color: const Color(0xFF10B981),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SecurityMapScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOptionCard(
                          context: context,
                          icon: Icons.notifications,
                          title: 'Alertas',
                          color: const Color(0xFF2563EB),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AlertsScreen(),
                              ),
                            );
                          },
                          badge: 3,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildOptionCard(
                          context: context,
                          icon: Icons.people,
                          title: 'Acompañamiento',
                          color: const Color(0xFF9333EA),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AccompanimentScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Ubicación activa
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.navigation,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Ubicación activa - Campus Principal',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (badge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}