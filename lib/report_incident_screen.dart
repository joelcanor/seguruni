import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  String _selectedIncidentType = 'Alerta de Seguridad';
  final TextEditingController _descriptionController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _incidentTypes = [
    {
      'nombre': 'Alerta de Seguridad',
      'descripcion': 'Actividad sospechosa, robos, emergencias',
      'icon': Icons.warning,
      'color': Color(0xFFDC2626),
    },
    {
      'nombre': 'Evento en Campus',
      'descripcion': 'Simulacros, actividades especiales, conciertos',
      'icon': Icons.event,
      'color': Color(0xFF2563EB),
    },
    {
      'nombre': 'Información General',
      'descripcion': 'Mantenimiento, avisos, servicios del campus',
      'icon': Icons.info,
      'color': Color(0xFFF59E0B),
    },
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _getHintText() {
    switch (_selectedIncidentType) {
      case 'Alerta de Seguridad':
        return 'Ej: Vi a una persona sospechosa cerca del edificio B, actuaba de manera extraña...';
      case 'Evento en Campus':
        return 'Ej: Hay un simulacro de evacuación el viernes a las 10 AM en todos los edificios...';
      case 'Información General':
        return 'Ej: El baño del segundo piso del edificio C está fuera de servicio...';
      default:
        return 'Describe lo que sucedió...';
    }
  }

  IconData _getSelectedIcon() {
    final type = _incidentTypes.firstWhere(
      (t) => t['nombre'] == _selectedIncidentType,
      orElse: () => _incidentTypes[0],
    );
    return type['icon'];
  }

  Color _getSelectedColor() {
    final type = _incidentTypes.firstWhere(
      (t) => t['nombre'] == _selectedIncidentType,
      orElse: () => _incidentTypes[0],
    );
    return type['color'];
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor describe el incidente'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      final reportData = {
        'tipo': _selectedIncidentType,
        'descripcion': _descriptionController.text.trim(),
        'esAnonimo': _isAnonymous,
        'usuarioId': _isAnonymous ? 'anonimo' : (user?.uid ?? 'desconocido'),
        'usuarioEmail': _isAnonymous ? 'anonimo' : (user?.email ?? 'desconocido'),
        'fechaHora': FieldValue.serverTimestamp(),
        'estado': 'pendiente',
        'ubicacion': 'Campus Principal',
      };

      await FirebaseFirestore.instance
          .collection('reportes')
          .add(reportData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte enviado exitosamente'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        
        _descriptionController.clear();
        setState(() {
          _selectedIncidentType = 'Alerta de Seguridad';
          _isAnonymous = false;
        });
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar reporte: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
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
          'Reportar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _getSelectedIcon(),
              size: 70,
              color: _getSelectedColor(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Reportar o Informar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu reporte ayuda a mantener el campus seguro e informado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tipo de Reporte',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            // Tarjetas de selección de categoría
            ..._incidentTypes.map((type) {
              final isSelected = _selectedIncidentType == type['nombre'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIncidentType = type['nombre'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? type['color'].withOpacity(0.1)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? type['color']
                            : const Color(0xFFE5E7EB),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: type['color'],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            type['icon'],
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type['nombre'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected 
                                      ? type['color']
                                      : const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type['descripcion'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: type['color'],
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            const Text(
              'Descripción',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: _getHintText(),
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _getSelectedColor(),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE7F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2563EB).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tu ubicación (Campus Principal) se compartirá con el reporte',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isAnonymous,
                  onChanged: (bool? value) {
                    setState(() {
                      _isAnonymous = value ?? false;
                    });
                  },
                  activeColor: _getSelectedColor(),
                ),
                const Expanded(
                  child: Text(
                    'Hacer reporte anónimo',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getSelectedColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Enviar Reporte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _getSelectedColor(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: _getSelectedColor(),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}