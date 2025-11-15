import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/controllers/location_controller.dart';
import 'package:rate_my_bowl/screens/adding_bathroom_screen.dart';
import 'package:rate_my_bowl/screens/review_screen.dart';
import 'package:rate_my_bowl/widgets/rmb_bottom_sheet.dart';
import 'package:rate_my_bowl/services/bathroom_service.dart';
import 'package:rate_my_bowl/models/restroom.dart';
import '../widgets/bathroom_pin.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Restroom? selectedRestroom;
  late final MapController _mapController;
  bool _didCenterOnFirstFix = false;
  List<Restroom> _restrooms = [];
  bool _isLoadingRestrooms = false;
  LatLng? _lastFetchedCenter;
  DateTime? _lastFetchTime;

  static const _defaultCenter = LatLng(40.24875188987069, -111.65141681875589);
  static const _defaultZoom = 18.0;
  static const _defaultRadius = 1000.0;
  static const _minFetchDistance = 200.0;
  static const _minFetchInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationController>().init();
      _fetchRestrooms(_defaultCenter);
    });
  }

  double _approximateDistanceInMeters(LatLng point1, LatLng point2) {
    // Simple approximation: 1 degree latitude ≈ 111km, 1 degree longitude ≈ 111km * cos(latitude)
    const metersPerDegreeLat = 111000.0;
    final metersPerDegreeLng = 111000.0 * (point1.latitude + point2.latitude) / 2.0 * 3.14159 / 180.0;
    
    final latDiff = (point1.latitude - point2.latitude).abs();
    final lngDiff = (point1.longitude - point2.longitude).abs();
    
    final latMeters = latDiff * metersPerDegreeLat;
    final lngMeters = lngDiff * metersPerDegreeLng;
    
    return math.sqrt(latMeters * latMeters + lngMeters * lngMeters);
  }

  Future<void> _fetchRestrooms(LatLng center, {bool force = false}) async {
    if (_isLoadingRestrooms) return;

    if (!force && _lastFetchedCenter != null) {
      final distance = _approximateDistanceInMeters(center, _lastFetchedCenter!);
      final timeSinceLastFetch = _lastFetchTime != null
          ? DateTime.now().difference(_lastFetchTime!)
          : Duration.zero;

      if (distance < _minFetchDistance && timeSinceLastFetch < _minFetchInterval) {
        return;
      }
    }

    setState(() {
      _isLoadingRestrooms = true;
    });

    try {
      final restrooms = await BathroomService.instance.getBathroomLocations(
        lat: center.latitude,
        lng: center.longitude,
        radius: _defaultRadius,
      );

      if (mounted) {
        setState(() {
          _restrooms = restrooms;
          _isLoadingRestrooms = false;
          _lastFetchedCenter = center;
          _lastFetchTime = DateTime.now();
        });
      }
    } catch (e) {
      print('Error fetching restrooms: $e');
      if (mounted) {
        setState(() {
          _isLoadingRestrooms = false;
        });
      }
    }
  }

  List<BathroomType> _genderToBathroomTypes(Gender gender) {
    return switch (gender) {
      Gender.Male => [BathroomType.men],
      Gender.Female => [BathroomType.women],
      Gender.Unisex => [BathroomType.other],
    };
  }

  @override
  void dispose() {
    context.read<LocationController>().disposeController();
    super.dispose();
  }

  void _centerOn(LatLng pos, {double zoom = _defaultZoom}) {
    _mapController.move(pos, zoom);
    _mapController.rotate(0.0);
  }

  @override
  Widget build(BuildContext context) {
    final lc = context.read<LocationController>();

    LatLng center = lc.userLatLong ?? _defaultCenter;
    double zoom = _defaultZoom;

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          minZoom: 3.0,
          maxZoom: 24.0,
          onMapEvent: (e) {
            final cam = e.camera;
            center = cam.center;
            zoom = cam.zoom;
            
            _fetchRestrooms(center);
          },
          onLongPress: (tapPosition, latLng) {
            showModalBottomSheet(
              context: context,
              barrierColor: Colors.black38,
              builder: (_) => RmbBottomSheet(
                addType: "restroom",
                screenBuilder: (context) =>
                    AddingBathroomScreen(initCrossPos: latLng),
              ),
            );
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.rate_my_bowl',
          ),
          MarkerLayer(
            markers: _restrooms.map((restroom) {
              return Marker(
                point: restroom.coordinates,
                width: 40,
                height: 50,
                alignment: Alignment.topCenter,
                child: BathroomPin(
                  bathroomTypes: _genderToBathroomTypes(restroom.gender),
                  isSelected: selectedRestroom?.id == restroom.id,
                  onTap: () {
                    setState(() {
                      selectedRestroom = restroom;
                    });

                    showModalBottomSheet(
                      context: context,
                      barrierColor: Colors.black38,
                      builder: (_) => RmbBottomSheet(
                        addType: "review",
                        screenBuilder: (context) =>
                            ReviewScreen(hintText: "Write your review here..."),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
          _UserLocationLayer(
            onFirstFix: (pos) {
              if (!_didCenterOnFirstFix) {
                _didCenterOnFirstFix = true;
                _centerOn(pos, zoom: _defaultZoom);
                _fetchRestrooms(pos, force: true);
              }
            },
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "recenter",
            onPressed: () {
              final pos = context.read<LocationController>().userLatLong;
              if (pos != null) {
                setState(() {
                  _centerOn(pos, zoom: _defaultZoom);
                });
                _fetchRestrooms(pos, force: true);
              }
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "add",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                barrierColor: Colors.black38,
                builder: (_) => RmbBottomSheet(
                  addType: "restroom",
                  screenBuilder: (context) =>
                      AddingBathroomScreen(initCrossPos: center),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _UserLocationLayer extends StatefulWidget {
  final void Function(LatLng pos)? onFirstFix;
  const _UserLocationLayer({this.onFirstFix});

  @override
  State<_UserLocationLayer> createState() => _UserLocationLayerState();
}

class _UserLocationLayerState extends State<_UserLocationLayer> {
  bool _hasCalledFirstFix = false;

  @override
  Widget build(BuildContext context) {
    final userPos = context.select<LocationController, LatLng?>(
      (lc) => lc.userLatLong,
    );
    final acc = context.select<LocationController, double?>(
      (lc) => lc.accuracy,
    );

    if (userPos != null && !_hasCalledFirstFix) {
      _hasCalledFirstFix = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onFirstFix?.call(userPos);
      });
    }

    return Stack(
      children: [
        if (userPos != null && acc != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: userPos,
                radius: acc,
                useRadiusInMeter: true,
                color: Colors.blue.withValues(alpha: 0.30),
                borderColor: Colors.blue.withValues(alpha: 0.40),
                borderStrokeWidth: 2,
              ),
            ],
          ),

        if (userPos != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userPos,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
