import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // 1. Reproducir alarma a todo volumen
      await _playAlarm();

      // 2. Hacer llamada al 911
      await _call911();

      // 3. Enviar reporte a Firebase
      await _sendEmergencyReport();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Alerta de emergencia enviada! Llamando al 911...'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 3),
          ),
        );
      }
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
      setState(() {
        _isEmergencyActive = false;
      });
    }
  }

  Future<void> _playAlarm() async {
    try {
      // Establecer volumen al máximo
      await _audioPlayer.setVolume(1.0);
      
      // Reproducir sonido de alarma en loop
      // Puedes usar un asset local o una URL de sonido de alarma
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Detener la alarma después de 30 segundos
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
        await launchUrl(phoneUri);
      } else {
        throw Exception('No se puede realizar la llamada');
      }
    } catch (e) {
      debugPrint('Error al llamar al 911: $e');
      rethrow;
    }
  }

  Future<void> _sendEmergencyReport() async {
    try {
      // Obtener ubicación actual
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        debugPrint('No se pudo obtener la ubicación: $e');
      }

      // Obtener usuario actual
      final user = FirebaseAuth.instance.currentUser;
      
      // Crear documento de reporte en Firebase
      final reportData = {
        'tipoIncidente': 'Llamada de emergencia',
        'descripcion': 'Alerta de emergencia activada mediante el botón SOS. Se ha iniciado una llamada al 911 y se ha activado la alarma del dispositivo.',
        'timestamp': FieldValue.serverTimestamp(),
        'ubicacion': position != null
            ? {
                'latitud': position.latitude,
                'longitud': position.longitude,
              }
            : null,
        'userId': user?.uid,
        'userEmail': user?.email,
        'esEmergencia': true,
        'estado': 'activa',
      };

      // Guardar en Firestore (asume que tienes una colección 'reportes')
      await FirebaseFirestore.instance
          .collection('reportes')
          .add(reportData);

      debugPrint('Reporte de emergencia enviado exitosamente');
    } catch (e) {
      debugPrint('Error al enviar reporte: $e');
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
                setState(() {
                  _isEmergencyActive = false;
                });
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
                            color: Colors.white.withOpacity(0.5),
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