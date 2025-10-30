import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Controlar qué secciones están expandidas
  bool _seguridadExpanded = false;
  bool _eventosExpanded = false;
  bool _infoExpanded = false;

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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reportes')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar alertas',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay alertas disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las nuevas alertas aparecerán aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // Separar reportes por categoría
          final allReportes = snapshot.data!.docs;
          
          final alertasSeguridad = allReportes.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['tipo'] == 'Alerta de Seguridad';
          }).toList();
          
          final eventosEnCampus = allReportes.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['tipo'] == 'Evento en Campus';
          }).toList();
          
          final informacionGeneral = allReportes.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['tipo'] == 'Información General';
          }).toList();

          // Ordenar por fecha
          alertasSeguridad.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['fechaHora'] as Timestamp?;
            final bTime = bData['fechaHora'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          eventosEnCampus.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['fechaHora'] as Timestamp?;
            final bTime = bData['fechaHora'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          informacionGeneral.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['fechaHora'] as Timestamp?;
            final bTime = bData['fechaHora'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return SingleChildScrollView(
            child: Column(
              children: [
                // Sección Alertas de Seguridad
                _buildExpandableCategorySection(
                  title: 'Alertas de Seguridad',
                  icon: Icons.warning,
                  color: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEE2E2),
                  reportes: alertasSeguridad,
                  isExpanded: _seguridadExpanded,
                  onToggle: () {
                    setState(() {
                      _seguridadExpanded = !_seguridadExpanded;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Sección Eventos en Campus
                _buildExpandableCategorySection(
                  title: 'Eventos en Campus',
                  icon: Icons.event,
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFDCE7F8),
                  reportes: eventosEnCampus,
                  isExpanded: _eventosExpanded,
                  onToggle: () {
                    setState(() {
                      _eventosExpanded = !_eventosExpanded;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Sección Información General
                _buildExpandableCategorySection(
                  title: 'Información General',
                  icon: Icons.info,
                  color: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFEF3C7),
                  reportes: informacionGeneral,
                  isExpanded: _infoExpanded,
                  onToggle: () {
                    setState(() {
                      _infoExpanded = !_infoExpanded;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandableCategorySection({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required List<QueryDocumentSnapshot> reportes,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header clickeable
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${reportes.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: color,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          
          // Contenido expandible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildReportesList(
              reportes: reportes,
              icon: icon,
              color: color,
              bgColor: bgColor,
              title: title,
            ),
            crossFadeState: isExpanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildReportesList({
    required List<QueryDocumentSnapshot> reportes,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
  }) {
    if (reportes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No hay reportes de $title',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: reportes.length,
      itemBuilder: (context, index) {
        final reporte = reportes[index].data() as Map<String, dynamic>;
        final descripcion = reporte['descripcion'] ?? 'Sin descripción';
        final fechaHora = reporte['fechaHora'] as Timestamp?;
        final ubicacion = reporte['ubicacion'] ?? 'Campus Principal';
        final esAnonimo = reporte['esAnonimo'] ?? false;
        
        String timeAgo = 'Hace un momento';
        if (fechaHora != null) {
          final difference = DateTime.now().difference(fechaHora.toDate());
          if (difference.inMinutes < 60) {
            timeAgo = 'Hace ${difference.inMinutes} minutos';
          } else if (difference.inHours < 24) {
            timeAgo = 'Hace ${difference.inHours} horas';
          } else {
            timeAgo = 'Hace ${difference.inDays} días';
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAlertCard(
            message: descripcion,
            time: timeAgo,
            location: ubicacion,
            isAnonymous: esAnonimo,
            icon: icon,
            color: color,
            bgColor: bgColor,
          ),
        );
      },
    );
  }

  Widget _buildAlertCard({
    required String message,
    required String time,
    required String location,
    required bool isAnonymous,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
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
                      message,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        if (isAnonymous)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.visibility_off,
                                  size: 12,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Anónimo',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}