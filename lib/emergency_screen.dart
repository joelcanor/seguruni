import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/offline_service.dart';  // 🆕 NUEVO

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _isEmergencyActive = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleEmergency() async {
    setState(() {
      _isEmergencyActive = true;
    });

    try {
      // ✅ PASO 1: PRIMERO enviar el reporte
      await _sendEmergencyReport();
      
      // ✅ PASO 2: Reproducir alarma
      _playAlarm();
      
      // ✅ PASO 3: Pequeña espera
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Alerta de emergencia enviada! Llamando al 911...'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // ✅ PASO 4: Llamada
      await _call911();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar emergencia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEmergencyActive = false;
        });
      }
    }
  }

  Future<void> _playAlarm() async {
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      Future.delayed(const Duration(seconds: 30), () {
        _audioPlayer.stop();
      });
    } catch (e) {
      debugPrint('Error al reproducir alarma: $e');
    }
  }

  Future<void> _call911() async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: '911');
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se puede realizar la llamada');
      }
    } catch (e) {
      debugPrint('Error al llamar al 911: $e');
      rethrow;
    }
  }

  // 🆕 VERSIÓN CON OFFLINE SIMPLIFICADA
  Future<void> _sendEmergencyReport() async {
    try {
      debugPrint('🚨 INICIANDO ENVÍO DE REPORTE DE EMERGENCIA');
      
      // ========================================
      // 📍 OBTENER UBICACIÓN
      // ========================================
      Position? position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied && 
            permission != LocationPermission.deniedForever) {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
          debugPrint('📍 Ubicación obtenida: ${position.latitude}, ${position.longitude}');
        }
      } catch (e) {
        debugPrint('⚠️ No se pudo obtener la ubicación: $e');
      }

      // ========================================
      // 👤 OBTENER USUARIO
      // ========================================
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('👤 Usuario: ${user?.email ?? "Sin usuario"}');
      
      // ========================================
      // 💾 GUARDAR PRIMERO EN HIVE (OFFLINE)
      // ========================================
      debugPrint('💾 Guardando primero en almacenamiento local...');
      await OfflineService.saveEmergencyOffline(
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        userId: user?.uid ?? 'usuario_anonimo',
        userName: user?.email ?? 'Usuario sin email',
      );
      debugPrint('✅ GUARDADO LOCAL EXITOSO (BACKUP GARANTIZADO)');

      // ========================================
      // 🌐 VERIFICAR CONEXIÓN E INTENTAR ENVIAR
      // ========================================
      final hasConnection = await OfflineService.hasConnection();
      debugPrint('🌐 Estado de conexión: ${hasConnection ? "ONLINE" : "OFFLINE"}');

      if (hasConnection) {
        // ========================================
        // 📤 ENVIAR A FIREBASE
        // ========================================
        debugPrint('📤 Enviando reporte a Firestore...');
        
        final reportData = {
          'tipo': 'Alerta de Seguridad',
          'tipoIncidente': '🚨 EMERGENCIA 911',
          'descripcion': 
              '🚨 ALERTA DE EMERGENCIA ACTIVADA 🚨\n\n'
              'El usuario ha presionado el botón de pánico SOS.\n\n'
              'Acciones tomadas:\n'
              '• Se ha iniciado llamada al 911\n'
              '• Alarma del dispositivo activada\n'
              '• Reporte enviado a las autoridades\n\n'
              'REQUIERE ATENCIÓN INMEDIATA',
          
          'fechaHora': FieldValue.serverTimestamp(),
          'fechaHoraLocal': DateTime.now().toIso8601String(),
          
          'ubicacion': position != null
              ? 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}'
              : 'Ubicación no disponible',
          
          'coordenadas': position != null
              ? {
                  'latitud': position.latitude,
                  'longitud': position.longitude,
                  'precision': position.accuracy,
                }
              : null,
          
          'userId': user?.uid ?? 'usuario_anonimo',
          'userEmail': user?.email ?? 'Sin email',
          'esAnonimo': false,
          'esEmergencia': true,
          'tipoEmergencia': 'BOTON_PANICO_SOS',
          'estado': 'ACTIVA',
          'prioridad': 'CRITICA',
          'llamada911': true,
          'alarmaActivada': true,
        };
        
        await FirebaseFirestore.instance
            .collection('reportes')
            .add(reportData);

        debugPrint('✅ REPORTE ENVIADO A FIREBASE');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Emergencia enviada exitosamente'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // ========================================
        // 📡 SIN INTERNET
        // ========================================
        debugPrint('📡 SIN CONEXIÓN - Emergencia guardada localmente');
        debugPrint('🔄 Se sincronizará automáticamente al restaurar conexión');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📡 Sin internet - Emergencia guardada localmente\nSe enviará automáticamente al conectar'),
              backgroundColor: Color(0xFFF59E0B),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('❌ ERROR AL ENVIAR REPORTE: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFDC2626),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergencia',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'EMERGENCIA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Mantén presionado el botón para activar la alerta de emergencia',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onLongPress: _handleEmergency,
              onLongPressEnd: (_) {
                if (mounted) {
                  setState(() {
                    _isEmergencyActive = false;
                  });
                }
              },
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: _isEmergencyActive
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_in_talk,
                      size: 70,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'MANTÉN\nPRESIONADO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            if (_isEmergencyActive)
              const Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Enviando alerta...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}