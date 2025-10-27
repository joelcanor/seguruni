import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart'; // <--- 1. IMPORTAR GEOCODING

class AccompanimentScreen extends StatefulWidget {
  const AccompanimentScreen({super.key});

  @override
  State<AccompanimentScreen> createState() => _AccompanimentScreenState();
}

class _AccompanimentScreenState extends State<AccompanimentScreen> {
  Position? _currentPosition;
  String _currentAddress = 'Obteniendo ubicación...';
  LatLng? _destinationLocation;
  String _destinationAddress = 'Selecciona tu destino';
  bool _isLoadingLocation = true;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // <--- 2. AÑADIR FUNCIÓN DE AYUDA (GEOCODIFICACIÓN INVERSA) --->
  Future<String> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Construir una dirección legible, filtrando partes nulas o vacías
        String street = place.street ?? '';
        String locality = place.locality ?? '';
        String subLocality = place.subLocality ?? '';
        String administrativeArea = place.administrativeArea ?? '';

        // Unir las partes que no estén vacías
        String address = [street, subLocality, locality, administrativeArea]
            .where((part) => part.isNotEmpty)
            .join(', ');

        return address.isNotEmpty ? address : 'Ubicación seleccionada';
      } else {
        return 'Dirección no encontrada';
      }
    } catch (e) {
      print('Error en geocoding: $e');
      return 'Error al obtener dirección';
    }
  }
  // <--- FIN DE LA FUNCIÓN DE AYUDA --->

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = 'Permisos de ubicación denegados';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = 'Permisos de ubicación denegados permanentemente';
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // <--- 3. USAR LA FUNCIÓN DE AYUDA --->
      String address =
          await _getAddressFromLatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = position;
        _currentAddress = address; // <--- MODIFICADO
        _isLoadingLocation = false;
      });

      // Escuchar cambios de ubicación en tiempo real
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) async { // <--- MODIFICADO (async)
        
        // <--- 4. USAR LA FUNCIÓN TAMBIÉN EN EL STREAM --->
        String streamAddress =
            await _getAddressFromLatLng(position.latitude, position.longitude);

        if (mounted) { // Añadir comprobación 'mounted' por buena práctica
          setState(() {
            _currentPosition = position;
            _currentAddress = streamAddress; // <--- MODIFICADO
          });
        }
      });
    } catch (e) {
      setState(() {
        _currentAddress = 'Error al obtener ubicación';
        _isLoadingLocation = false;
      });
      print('Error: $e');
    }
  }

  Future<void> _selectDestination() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esperando ubicación actual...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          initialPosition: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _destinationLocation = result['location'] as LatLng;
        _destinationAddress = result['address'] as String;
      });
    }
  }

  Future<void> _requestAccompaniment() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esperando ubicación actual...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un destino'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Calcular distancia
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _destinationLocation!.latitude,
      _destinationLocation!.longitude,
    );
    
    String distanceText = distance < 1000
        ? '${distance.round()}m'
        : '${(distance / 1000).toStringAsFixed(1)}km';

    // Crear mensaje para WhatsApp
    // <--- 5. AHORA EL MENSAJE INCLUIRÁ LAS DIRECCIONES (si se obtuvieron) --->
    String message = '''🚨 Solicitud de Acompañamiento 🚨

📍 Mi ubicación actual:
$_currentAddress
(http://maps.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude})

🎯 Destino:
$_destinationAddress
(http://maps.google.com/maps?q=${_destinationLocation!.latitude},${_destinationLocation!.longitude})

📏 Distancia: $distanceText

⏰ Hora: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}''';

    try {
      // Método 1: URL scheme de WhatsApp con texto pero SIN número (abre selector de contactos)
      final whatsappUrl = Uri.parse(
        'whatsapp://send?text=${Uri.encodeComponent(message)}',
      );

      bool opened = false;

      // Intentar abrir WhatsApp
      if (await canLaunchUrl(whatsappUrl)) {
        opened = await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!opened) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('WhatsApp no disponible'),
              content: const Text(
                'No se pudo abrir WhatsApp. Asegúrate de:\n\n'
                '1. Tener WhatsApp instalado\n'
                '2. Haber configurado WhatsApp\n'
                '3. Tener conexión a internet',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(
              'Error al intentar abrir WhatsApp:\n\n$e\n\n'
              'Verifica que WhatsApp esté instalado y configurado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
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
              colors: [Color(0xFF9333EA), Color(0xFFC084FC)],
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
          'Acompañamiento',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _getCurrentLocation,
            tooltip: 'Actualizar ubicación',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.people,
              size: 80,
              color: Color(0xFF9333EA),
            ),
            const SizedBox(height: 24),
            const Text(
              'Solicitar Acompañamiento',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Solicita que un guardia de seguridad te acompañe a tu destino dentro del campus',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              icon: Icons.location_on,
              title: 'Tu ubicación actual',
              subtitle: _currentAddress,
              color: const Color(0xFF10B981),
              isLoading: _isLoadingLocation,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDestination,
              child: _buildInfoCard(
                icon: Icons.my_location,
                title: 'Destino',
                subtitle: _destinationAddress,
                color: const Color(0xFF2563EB),
                isLoading: false,
                showArrow: true,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _requestAccompaniment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Solicitar Acompañamiento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9333EA),
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF9333EA), width: 2),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isLoading,
    bool showArrow = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF1F2937)),
                        ),
                      )
                    : Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
          if (showArrow)
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF6B7280),
              size: 16,
            ),
        ],
      ),
    );
  }
}

// Pantalla de selección de destino en el mapa
class MapSelectionScreen extends StatefulWidget {
  final LatLng initialPosition;

  const MapSelectionScreen({
    super.key,
    required this.initialPosition,
  });

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoadingAddress = false;
  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String? _routeDistance;
  String? _routeDuration;

  @override
  void initState() {
    super.initState();
    _markers.add(
      Marker(
        markerId: const MarkerId('current'),
        position: widget.initialPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Tu ubicación actual'),
      ),
    );
  }

  // <--- 6. AÑADIR LA MISMA FUNCIÓN DE AYUDA AQUÍ TAMBIÉN --->
  Future<String> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String street = place.street ?? '';
        String locality = place.locality ?? '';
        String subLocality = place.subLocality ?? '';
        String administrativeArea = place.administrativeArea ?? '';

        String address = [street, subLocality, locality, administrativeArea]
            .where((part) => part.isNotEmpty)
            .join(', ');

        return address.isNotEmpty ? address : 'Ubicación seleccionada';
      } else {
        return 'Dirección no encontrada';
      }
    } catch (e) {
      print('Error en geocoding: $e');
      return 'Error al obtener dirección';
    }
  }

  Future<void> _onMapTap(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoadingAddress = true;
      _selectedAddress = 'Buscando dirección...'; // <--- MODIFICADO (Placeholder)
      
      _markers.removeWhere((m) => m.markerId.value == 'destination');
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: const InfoWindow(title: 'Destino seleccionado'),
        ),
      );
    });

    // Calcular ruta
    await _calculateRoute(location);

    // <--- 7. OBTENER LA DIRECCIÓN ANTES DE TERMINAR --->
    String address =
        await _getAddressFromLatLng(location.latitude, location.longitude);

    setState(() {
      _selectedAddress = address; // <--- MODIFICADO
      _isLoadingAddress = false;
    });
  }

  Future<void> _calculateRoute(LatLng destination) async {
    try {
      // TODO: ¡IMPORTANTE! No expongas tu API Key de Google Maps en el código
      // Debes gestionarla de forma segura (variables de entorno, etc.)
      const String googleAPIKey = 'AIzaSyCGkMDMMJqfuxRnYPp-guHr0yTlhN6i1GA';

      PolylinePoints polylinePoints = PolylinePoints();
      
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(
            widget.initialPosition.latitude,
            widget.initialPosition.longitude,
          ),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.walking,
        ),
        googleApiKey: googleAPIKey,
      );

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        double totalDistance = Geolocator.distanceBetween(
          widget.initialPosition.latitude,
          widget.initialPosition.longitude,
          destination.latitude,
          destination.longitude,
        );

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              color: const Color(0xFF9333EA),
              width: 5,
              points: polylineCoordinates,
            ),
          );

          _routeDistance = totalDistance < 1000
              ? '${totalDistance.round()}m'
              : '${(totalDistance / 1000).toStringAsFixed(1)}km';
          
          // Cálculo simple de tiempo caminando (aprox 4.5 km/h)
          double hours = totalDistance / 1000 / 4.5;
          int minutes = (hours * 60).round();
          _routeDuration = '$minutes min caminando';
        });

        // Ajustar cámara para mostrar toda la ruta
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            widget.initialPosition.latitude < destination.latitude
                ? widget.initialPosition.latitude
                : destination.latitude,
            widget.initialPosition.longitude < destination.longitude
                ? widget.initialPosition.longitude
                : destination.longitude,
          ),
          northeast: LatLng(
            widget.initialPosition.latitude > destination.latitude
                ? widget.initialPosition.latitude
                : destination.latitude,
            widget.initialPosition.longitude > destination.longitude
                ? widget.initialPosition.longitude
                : destination.longitude,
          ),
        );

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      }
    } catch (e) {
      print('Error calculando ruta: $e');
    }
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'location': _selectedLocation,
        'address': _selectedAddress, // Ahora 'address' tendrá el nombre, no las coords.
      });
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
              colors: [Color(0xFF9333EA), Color(0xFFC084FC)],
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
          'Selecciona tu destino',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _onMapTap,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
          ),
          
          // Instrucción para el usuario
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9333EA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.touch_app,
                      color: Color(0xFF9333EA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Toca el mapa para seleccionar tu destino',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_selectedLocation != null)
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
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9333EA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Destino seleccionado',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _isLoadingAddress
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _selectedAddress, // <--- AHORA MUESTRA LA DIRECCIÓN
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_routeDistance != null && _routeDuration != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9333EA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.directions_walk,
                              color: Color(0xFF9333EA),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_routeDistance • $_routeDuration',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9333EA),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9333EA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmar Destino',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}