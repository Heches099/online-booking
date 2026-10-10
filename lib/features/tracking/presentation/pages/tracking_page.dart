import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/theme/app_colors.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;

  Position? _currentPosition;
  double _currentSpeed = 0.0;
  bool _isMapLoading = true;

  // Modern Silver Map Style
  static const String _mapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#f5f5f5"}]},
    {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#616161"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#f5f5f5"}]},
    {"featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#bdbdbd"}]},
    {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#eeeeee"}]},
    {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#c9c9c9"}]},
    {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _startTracking();
  }

void _startTracking() {
    _positionStream?.cancel();
    final stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
    _positionStream = stream.listen(_onPositionChanged);
    _positionStream!.onError(_onPositionError);
  }

  void _onPositionChanged(Position position) {
    setState(() {
      _currentPosition = position;
      // Convert m/s to km/h
      _currentSpeed = position.speed * 3.6;
      _isMapLoading = false;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    }
  }

  void _onPositionError(error) {
    _fallbackToNetworkLocation();
  }

  Future<void> _fallbackToNetworkLocation() async {
    await Future.delayed(const Duration(seconds: 2));
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        // Convert m/s to km/h
        _currentSpeed = position.speed * 3.6;
        _isMapLoading = false;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          if (!_isMapLoading && _currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude),
                zoom: 16,
              ),
              style: _mapStyle,
              onTap: (_) => AppSessionService.instance.markActivity(),
              onLongPress: (_) => AppSessionService.instance.markActivity(),
              onCameraMoveStarted: AppSessionService.instance.markActivity,
              onCameraIdle: AppSessionService.instance.markActivity,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
            )
          else
            const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          _buildGlassHeader(),
          _buildSpeedometerOverlay(),
          _buildTelemetryCard(),
        ],
      ),
    );
  }

  Widget _buildGlassHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: FadeInDown(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 20)
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.gps_fixed_rounded, color: AppColors.primary),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Live Journey Stream",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("Route: Dar es Salaam → Mwanza",
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.red, size: 8),
                    SizedBox(width: 4),
                    Text("LIVE",
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedometerOverlay() {
    return Positioned(
      top: 150,
      right: 20,
      child: FadeInRight(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              const Text("SPEED",
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.bold)),
              Text(
                _currentSpeed.toStringAsFixed(0),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900),
              ),
              const Text("KM/H",
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 8,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryCard() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: FadeInUp(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(77),
                  blurRadius: 30,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.bus_alert_rounded,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Kilimanjaro Royal - T 777 ABC",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text("Current Altitude: 1,200m ASL",
                            style:
                                TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _telemetryItem(Icons.timer_outlined, "ETA", "4h 20m"),
                  _telemetryItem(Icons.route_outlined, "DIST", "340 km"),
                  _telemetryItem(Icons.wifi_rounded, "WIFI", "Strong"),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("NOTIFY FAMILY OF LOCATION",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _telemetryItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white24, size: 20),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
