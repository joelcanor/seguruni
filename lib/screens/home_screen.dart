import 'package:flutter/material.dart';
import '../emergency_screen.dart';
import '../report_incident_screen.dart';
import '../security_map_screen.dart';
import 'alerts_screen.dart';
import '../accompaniment_screen.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final user = AuthService().currentUser;
    setState(() {
      _isLoggedIn = user != null;
    });
  }

  // Navegar a una pantalla con verificación de login
  Future<void> _navigateWithAuth(Widget screen) async {
    if (!_isLoggedIn) {
      // Mostrar diálogo para iniciar sesión
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Iniciar sesión requerido'),
          content: const Text('Necesitas iniciar sesión para acceder a esta función.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              child: const Text(
                'Iniciar sesión',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (shouldLogin == true && mounted) {
        // Ir a login y esperar resultado
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        
        // Si inició sesión exitosamente, actualizar estado y navegar
        if (result == true && mounted) {
          await _checkLoginStatus();
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            );
          }
        }
      }
    } else {
      // Ya está autenticado, navegar directamente
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService().signOut();
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    final maxWidth = isWeb ? 600.0 : double.infinity;

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
          if (_isLoggedIn) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.circle, color: Color(0xFF10B981), size: 12),
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
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
              tooltip: 'Cerrar sesión',
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
                if (result == true) {
                  _checkLoginStatus();
                }
              },
              icon: const Icon(Icons.login, color: Colors.white, size: 20),
              label: const Text(
                'Iniciar sesión',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
                if (result == true) {
                  _checkLoginStatus();
                }
              },
              icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
              label: const Text(
                'Registro',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: EdgeInsets.symmetric(horizontal: isWeb ? 0 : 24),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 40),
              // Logo y título
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF9333EA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'CampusGuard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu seguridad es nuestra prioridad',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 40),
              // Botón de Emergencia (SIN LOGIN REQUERIDO)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
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
                            SizedBox(height: 4),
                            Text(
                              'Presiona aquí',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Grid de opciones (REQUIEREN LOGIN)
              Row(
                children: [
                  Expanded(
                    child: _buildOptionCard(
                      icon: Icons.camera_alt,
                      title: 'Reportar\nIncidente',
                      color: const Color(0xFFEA580C),
                      onTap: () => _navigateWithAuth(const ReportIncidentScreen()),
                      requiresAuth: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOptionCard(
                      icon: Icons.location_on,
                      title: 'Mapa de\nSeguridad',
                      color: const Color(0xFF10B981),
                      onTap: () => _navigateWithAuth(const SecurityMapScreen()),
                      requiresAuth: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildOptionCard(
                      icon: Icons.notifications,
                      title: 'Alertas',
                      color: const Color(0xFF2563EB),
                      onTap: () => _navigateWithAuth(const AlertsScreen()),
                      badge: 3,
                      requiresAuth: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildOptionCard(
                      icon: Icons.people,
                      title: 'Acompañamiento',
                      color: const Color(0xFF9333EA),
                      onTap: () => _navigateWithAuth(const AccompanimentScreen()),
                      requiresAuth: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Ubicación activa
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.navigation,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ubicación activa - Campus Principal',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    int? badge,
    bool requiresAuth = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 130,
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                if (requiresAuth && !_isLoggedIn)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.white.withOpacity(0.5),
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}