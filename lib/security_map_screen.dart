import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' show cos, sqrt, asin;

class SecurityMapScreen extends StatefulWidget {
  const SecurityMapScreen({super.key});

  @override
  State<SecurityMapScreen> createState() => _SecurityMapScreenState();
}

class _SecurityMapScreenState extends State<SecurityMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isNavigating = false;
  
  static const LatLng _defaultCenter = LatLng(21.20237594178445, -99.44698116178421);
  
  final List<SecurityPoint> _securityPoints = [
    SecurityPoint(
      id: '1',
      title: 'Caseta de Seguridad',
      position: const LatLng(21.21520355477791, -99.4625916182965),
      type: SecurityPointType.guardPost,
      phone: '555-1234',
      description: 'Vigilancia 24/7',
    ),
    SecurityPoint(
      id: '2',
      title: 'Centro de Salud',
      position: const LatLng(21.2161032095733, -99.46135351817169),
      type: SecurityPointType.medical,
      phone: '555-5678',
      description: 'Atención médica',
    ),
    SecurityPoint(
      id: '3',
      title: 'Punto de Luz Emergencia',
      position: const LatLng(21.215573120729854, -99.46272144474756),
      type: SecurityPointType.emergencyLight,
      phone: '911',
      description: 'Botón de pánico',
    ),
  ];

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  SecurityPoint? _selectedPoint;
  String? _routeDistance;
  String? _routeDuration;
  List<LatLng>? _routePoints;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _createMarkers();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  String _calculateDistance(LatLng start, LatLng end) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) * c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) / 2;
    double distanceInMeters = 12742 * asin(sqrt(a)) * 1000;
    
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  void _updateDistances() {
    if (_currentPosition == null) return;
    
    for (var point in _securityPoints) {
      point.distance = _calculateDistance(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        point.position,
      );
    }
    
    _securityPoints.sort((a, b) {
      double distA = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        a.position.latitude,
        a.position.longitude,
      );
      double distB = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        b.position.latitude,
        b.position.longitude,
      );
      return distA.compareTo(distB);
    });
    
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      _updateDistances();
      _createMarkers();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        ),
      );

      // Escuchar cambios de ubicación
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        setState(() {
          _currentPosition = position;
        });
        _updateDistances();
        _createMarkers();
        
        // Si está navegando, actualizar ruta
        if (_isNavigating && _selectedPoint != null) {
          _updateNavigationDistance();
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error al obtener ubicación: $e');
    }
  }

  void _updateNavigationDistance() {
    if (_currentPosition == null || _selectedPoint == null) return;
    
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _selectedPoint!.position.latitude,
      _selectedPoint!.position.longitude,
    );
    
    setState(() {
      _routeDistance = distance < 1000
          ? '${distance.round()}m'
          : '${(distance / 1000).toStringAsFixed(1)}km';
      
      double hours = distance / 1000 / 4.5;
      int minutes = (hours * 60).round();
      _routeDuration = minutes > 0 ? '$minutes min' : 'Llegando...';
    });

    // Si llegaste (menos de 20 metros)
    if (distance < 20) {
      _stopNavigation();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Has llegado a ${_selectedPoint!.title}!'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _createMarkers() {
    _markers = _securityPoints.map((point) {
      return Marker(
        markerId: MarkerId(point.id),
        position: point.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(point.type.hue),
        infoWindow: InfoWindow(
          title: point.title,
          snippet: point.distance,
        ),
        onTap: () {
          setState(() {
            _selectedPoint = point;
          });
        },
      );
    }).toSet();

    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Mi ubicación'),
        ),
      );
    }
  }

  void _goToMyLocation() async {
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          17.0,
        ),
      );
    } else {
      await _getCurrentLocation();
    }
  }

  Future<void> _startNavigation() async {
    if (_selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un punto de seguridad primero'),
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener tu ubicación'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );

    try {
      // 🔧 REEMPLAZA CON TU API KEY
      const String googleAPIKey = 'AIzaSyCGkMDMMJqfuxRnYPp-guHr0yTlhN6i1GA';

      PolylinePoints polylinePoints = PolylinePoints();
      
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          destination: PointLatLng(_selectedPoint!.position.latitude, _selectedPoint!.position.longitude),
          mode: TravelMode.walking,
        ),
        googleApiKey: googleAPIKey,
      );

      Navigator.pop(context);

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        setState(() {
          _routePoints = polylineCoordinates;
          _isNavigating = true;
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              color: const Color(0xFF10B981),
              width: 6,
              points: polylineCoordinates,
              patterns: [PatternItem.dash(30), PatternItem.gap(20)],
            ),
          );

          double totalDistance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            _selectedPoint!.position.latitude,
            _selectedPoint!.position.longitude,
          );
          
          _routeDistance = totalDistance < 1000
              ? '${totalDistance.round()}m'
              : '${(totalDistance / 1000).toStringAsFixed(1)}km';
          
          double hours = totalDistance / 1000 / 4.5;
          int minutes = (hours * 60).round();
          _routeDuration = '$minutes min';
        });

        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            _currentPosition!.latitude < _selectedPoint!.position.latitude
                ? _currentPosition!.latitude
                : _selectedPoint!.position.latitude,
            _currentPosition!.longitude < _selectedPoint!.position.longitude
                ? _currentPosition!.longitude
                : _selectedPoint!.position.longitude,
          ),
          northeast: LatLng(
            _currentPosition!.latitude > _selectedPoint!.position.latitude
                ? _currentPosition!.latitude
                : _selectedPoint!.position.latitude,
            _currentPosition!.longitude > _selectedPoint!.position.longitude
                ? _currentPosition!.longitude
                : _selectedPoint!.position.longitude,
          ),
        );

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navegación iniciada a ${_selectedPoint!.title}'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo calcular la ruta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      print('Error al calcular ruta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al calcular ruta: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _polylines.clear();
      _routeDistance = null;
      _routeDuration = null;
      _routePoints = null;
    });
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
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isNavigating ? 'Navegando...' : 'Mapa de Seguridad',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isNavigating)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _stopNavigation,
              tooltip: 'Detener navegación',
            ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? Container(
                  color: const Color(0xFFE5E7EB),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF10B981),
                    ),
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude)
                        : _defaultCenter,
                    zoom: 15.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  onTap: (_) {
                    if (!_isNavigating) {
                      setState(() {
                        _selectedPoint = null;
                      });
                    }
                  },
                ),

          // Banner de navegación activa
          if (_isNavigating && _routeDistance != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.navigation,
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
                            _selectedPoint?.title ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_routeDistance • $_routeDuration',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _stopNavigation,
                    ),
                  ],
                ),
              ),
            ),

          // Panel de información
          if (!_isNavigating)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Puntos de Seguridad',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._securityPoints.map((point) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildSecurityPoint(
                                  point: point,
                                  isSelected: _selectedPoint?.id == point.id,
                                ),
                              )),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _goToMyLocation,
                                  icon: const Icon(Icons.my_location),
                                  label: const Text('Mi Ubicación'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _startNavigation,
                                  icon: const Icon(Icons.navigation),
                                  label: const Text('Navegar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Botón de centrar ubicación (solo en navegación)
          if (_isNavigating)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _goToMyLocation,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityPoint({
    required SecurityPoint point,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPoint = point;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(point.position, 17.0),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: point.type.color.withOpacity(isSelected ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: point.type.color.withOpacity(isSelected ? 0.6 : 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: point.type.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(point.type.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${point.distance} • ${point.description}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.arrow_forward_ios,
              size: 16,
              color: isSelected ? point.type.color : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

class SecurityPoint {
  final String id;
  final String title;
  final LatLng position;
  final SecurityPointType type;
  final String phone;
  final String description;
  String distance;

  SecurityPoint({
    required this.id,
    required this.title,
    required this.position,
    required this.type,
    required this.phone,
    required this.description,
    this.distance = 'Calculando...',
  });
}

enum SecurityPointType {
  guardPost,
  medical,
  emergencyLight,
}

extension SecurityPointTypeExtension on SecurityPointType {
  IconData get icon {
    switch (this) {
      case SecurityPointType.guardPost:
        return Icons.security;
      case SecurityPointType.medical:
        return Icons.local_hospital;
      case SecurityPointType.emergencyLight:
        return Icons.light;
    }
  }

  Color get color {
    switch (this) {
      case SecurityPointType.guardPost:
        return const Color(0xFF10B981);
      case SecurityPointType.medical:
        return const Color(0xFFDC2626);
      case SecurityPointType.emergencyLight:
        return const Color(0xFFF59E0B);
    }
  }

  double get hue {
    switch (this) {
      case SecurityPointType.guardPost:
        return BitmapDescriptor.hueGreen;
      case SecurityPointType.medical:
        return BitmapDescriptor.hueRed;
      case SecurityPointType.emergencyLight:
        return BitmapDescriptor.hueOrange;
    }
  }
}