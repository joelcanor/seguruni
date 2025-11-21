import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineService {
  static const String EMERGENCY_BOX = 'emergency_reports';
  
  // ========================================
  // 🔧 INICIALIZACIÓN
  // ========================================
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(EMERGENCY_BOX);
  }
  
  // ========================================
  // 💾 GUARDAR EMERGENCIA OFFLINE
  // ========================================
  static Future<String> saveEmergencyOffline({
    required double latitude,
    required double longitude,
    required String userId,
    String? userName,
  }) async {
    final box = Hive.box(EMERGENCY_BOX);
    
    final reportData = {
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId,
      'userName': userName ?? 'Usuario',
      'timestamp': DateTime.now().toIso8601String(),
      'synced': false,
      'type': 'emergency',
      'tipoIncidente': '🚨 EMERGENCIA 911',
      'descripcion': 
          '🚨 ALERTA DE EMERGENCIA ACTIVADA 🚨\n\n'
          'El usuario ha presionado el botón de pánico SOS.\n\n'
          'Acciones tomadas:\n'
          '• Se ha iniciado llamada al 911\n'
          '• Alarma del dispositivo activada\n'
          '• Reporte enviado a las autoridades\n\n'
          'REQUIERE ATENCIÓN INMEDIATA',
      'prioridad': 'CRITICA',
    };
    
    final key = await box.add(reportData);
    print('✅ Emergencia guardada offline con key: $key');
    
    return key.toString();
  }
  
  // ========================================
  // 🌐 VERIFICAR CONEXIÓN
  // ========================================
  static Future<bool> hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile) || 
           result.contains(ConnectivityResult.wifi) ||
           result.contains(ConnectivityResult.ethernet);
  }
  
  // ========================================
  // 📤 SINCRONIZAR EMERGENCIAS PENDIENTES
  // ========================================
  static Future<void> syncPendingEmergencies() async {
    if (!await hasConnection()) {
      print('❌ Sin conexión, no se puede sincronizar');
      return;
    }
    
    final box = Hive.box(EMERGENCY_BOX);
    final pendingReports = <MapEntry<dynamic, dynamic>>[];
    
    // Obtener reportes no sincronizados
    for (var key in box.keys) {
      final report = box.get(key);
      if (report != null && report['synced'] == false) {
        pendingReports.add(MapEntry(key, report));
      }
    }
    
    print('📤 Sincronizando ${pendingReports.length} emergencias...');
    
    for (var entry in pendingReports) {
      try {
        // Preparar datos para Firebase
        final reportData = Map<String, dynamic>.from(entry.value);
        reportData.remove('synced'); // Remover campo de control
        
        // Convertir timestamp de String a Timestamp
        final timestampStr = reportData['timestamp'];
        reportData['fechaHora'] = FieldValue.serverTimestamp();
        reportData['fechaHoraLocal'] = timestampStr;
        
        // Agregar campos adicionales de Firebase
        reportData['tipo'] = 'Alerta de Seguridad';
        reportData['ubicacion'] = reportData['latitude'] != null
            ? 'Lat: ${reportData['latitude'].toStringAsFixed(4)}, Lng: ${reportData['longitude'].toStringAsFixed(4)}'
            : 'Ubicación no disponible';
        reportData['coordenadas'] = reportData['latitude'] != null
            ? {
                'latitud': reportData['latitude'],
                'longitud': reportData['longitude'],
              }
            : null;
        reportData['esAnonimo'] = false;
        reportData['esEmergencia'] = true;
        reportData['tipoEmergencia'] = 'BOTON_PANICO_SOS';
        reportData['estado'] = 'ACTIVA';
        reportData['llamada911'] = true;
        reportData['alarmaActivada'] = true;
        
        // Enviar a Firestore
        await FirebaseFirestore.instance
            .collection('reportes')
            .add(reportData);
        
        // Marcar como sincronizado
        final updatedReport = Map<String, dynamic>.from(entry.value);
        updatedReport['synced'] = true;
        await box.put(entry.key, updatedReport);
        
        print('✅ Emergencia sincronizada: ${entry.key}');
      } catch (e) {
        print('❌ Error sincronizando ${entry.key}: $e');
      }
    }
  }
  
  // ========================================
  // 🔄 MONITOREO AUTOMÁTICO DE CONEXIÓN
  // ========================================
  static void startAutoSync() {
    Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.contains(ConnectivityResult.mobile) || 
                           results.contains(ConnectivityResult.wifi) ||
                           results.contains(ConnectivityResult.ethernet);
      
      if (hasConnection) {
        print('🌐 Conexión restaurada, sincronizando...');
        syncPendingEmergencies();
      }
    });
  }
  
  // ========================================
  // 📊 OBTENER EMERGENCIAS PENDIENTES
  // ========================================
  static int getPendingCount() {
    final box = Hive.box(EMERGENCY_BOX);
    int count = 0;
    
    for (var key in box.keys) {
      final report = box.get(key);
      if (report != null && report['synced'] == false) {
        count++;
      }
    }
    
    return count;
  }
  
  // ========================================
  // 📋 OBTENER TODAS LAS EMERGENCIAS PENDIENTES
  // ========================================
  static List<Map<String, dynamic>> getPendingEmergencies() {
    final box = Hive.box(EMERGENCY_BOX);
    final pending = <Map<String, dynamic>>[];
    
    for (var key in box.keys) {
      final report = box.get(key);
      if (report != null && report['synced'] == false) {
        final reportMap = Map<String, dynamic>.from(report);
        reportMap['localKey'] = key.toString();
        pending.add(reportMap);
      }
    }
    
    return pending;
  }
  
  // ========================================
  // 🗑️ LIMPIAR EMERGENCIAS SINCRONIZADAS
  // ========================================
  static Future<void> clearSyncedEmergencies() async {
    final box = Hive.box(EMERGENCY_BOX);
    final keysToDelete = <dynamic>[];
    
    for (var key in box.keys) {
      final report = box.get(key);
      if (report != null && report['synced'] == true) {
        keysToDelete.add(key);
      }
    }
    
    for (var key in keysToDelete) {
      await box.delete(key);
    }
    
    print('🗑️ Limpiadas ${keysToDelete.length} emergencias sincronizadas');
  }
}