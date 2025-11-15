import 'dart:async';
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
  Timer? _debounceTimer;
  LatLng? _pendingCenter;
  double? _pendingZoom;

  static const _defaultCenter = LatLng(40.24875188987069, -111.65141681875589);
  static const _defaultZoom = 18.0;
  static const _minFetchDistance = 200.0;
  static const _debounceDelay = Duration(seconds: 2);
  double _currentZoom = _defaultZoom;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lc = context.read<LocationController>();
      lc.init();
      lc.addListener(_onLocationUpdate);
      final userLocation = lc.userLatLong;
      if (userLocation != null) {
        _fetchRestrooms(userLocation, zoom: _defaultZoom, force: true);
      }
    });
  }

  void _onLocationUpdate() {
    final lc = context.read<LocationController>();
    final userLocation = lc.userLatLong;
    if (userLocation != null && !_didCenterOnFirstFix) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_didCenterOnFirstFix) {
          _fetchRestrooms(userLocation, zoom: _defaultZoom, force: true);
        }
      });
    }
  }

  double _calculateRadiusFromZoom(double zoom) {
    const baseRadius = 500.0;
    const maxZoom = 18.0;
    final radius = baseRadius * math.pow(2, maxZoom - zoom);
    return radius.clamp(200.0, 100000.0);
  }

  double _approximateDistanceInMeters(LatLng point1, LatLng point2) {
    // this is just a rough calculation. If things aren't showing up when we'd expect them to, this should be the first place to check for bugs
    const metersPerDegreeLat = 111000.0;
    final metersPerDegreeLng = 111000.0 * (point1.latitude + point2.latitude) / 2.0 * 3.14159 / 180.0;
    
    final latDiff = (point1.latitude - point2.latitude).abs();
    final lngDiff = (point1.longitude - point2.longitude).abs();
    
    final latMeters = latDiff * metersPerDegreeLat;
    final lngMeters = lngDiff * metersPerDegreeLng;
    
    return math.sqrt(latMeters * latMeters + lngMeters * lngMeters);
  }

  void _debouncedFetchRestrooms(LatLng center, {double? zoom}) {
    _debounceTimer?.cancel();
    
    _pendingCenter = center;
    _pendingZoom = zoom;
    
    _debounceTimer = Timer(_debounceDelay, () {
      if (_pendingCenter != null && mounted) {
        final centerToFetch = _pendingCenter!;
        final zoomToFetch = _pendingZoom;
        _pendingCenter = null;
        _pendingZoom = null;
        _fetchRestrooms(centerToFetch, zoom: zoomToFetch);
      }
    });
  }

  Future<void> _fetchRestrooms(LatLng center, {bool force = false, double? zoom}) async {
    if (force) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      _pendingCenter = null;
      _pendingZoom = null;
    } else {
      if (_isLoadingRestrooms) {
        _debouncedFetchRestrooms(center, zoom: zoom);
        return;
      }
    }

    final currentZoom = zoom ?? _currentZoom;
    final radius = _calculateRadiusFromZoom(currentZoom);

    if (!force && _lastFetchedCenter != null) {
      final distance = _approximateDistanceInMeters(center, _lastFetchedCenter!);
      final zoomChanged = (zoom != null && (zoom - _currentZoom).abs() > 0.5);

      if (distance < _minFetchDistance && !zoomChanged) {
        return;
      }
    }

    setState(() {
      _isLoadingRestrooms = true;
      if (zoom != null) {
        _currentZoom = zoom;
      }
    });

    try {
      final restrooms = await BathroomService.instance.getBathroomLocations(
        lat: center.latitude,
        lng: center.longitude,
        radius: radius,
      );

      if (mounted) {
        setState(() {
          _restrooms = restrooms;
          _isLoadingRestrooms = false;
          _lastFetchedCenter = center;
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
    _debounceTimer?.cancel();
    context.read<LocationController>().removeListener(_onLocationUpdate);
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
    
    final userLocation = lc.userLatLong;
    if (userLocation != null && _lastFetchedCenter == null && !_isLoadingRestrooms) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastFetchedCenter == null) {
          _fetchRestrooms(userLocation, zoom: _defaultZoom, force: true);
        }
      });
    }

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
            final newCenter = cam.center;
            final newZoom = cam.zoom;
            
            center = newCenter;
            zoom = newZoom;
            
            if (_didCenterOnFirstFix || _lastFetchedCenter != null) {
              _debouncedFetchRestrooms(newCenter, zoom: newZoom);
            }
          },
          onLongPress: (tapPosition, latLng) async {
            final result = await showModalBottomSheet<Restroom>(
              context: context,
              barrierColor: Colors.black38,
              builder: (_) => RmbBottomSheet(
                addType: BottomSheetType.restroom,
                screenBuilder: (context) =>
                    AddingBathroomScreen(initCrossPos: latLng),
              ),
            );
            
            if (result != null && mounted) {
              setState(() {
                _restrooms.add(result);
              });
            }
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
                        addType: BottomSheetType.review,
                        restroom: restroom,
                        screenBuilder: (context) => ReviewScreen(
                          hintText: "Write your review here...",
                          restroomId: restroom.id,
                        ),
                      ),
                    ).then((result) {
                      if (result != null && result is Map && result['success'] == true) {
                        final currentCenter = _mapController.camera.center;
                        _fetchRestrooms(currentCenter, zoom: _currentZoom, force: true).then((_) {
                          if (selectedRestroom != null && mounted) {
                            final updatedRestroom = _restrooms.firstWhere(
                              (r) => r.id == selectedRestroom!.id,
                              orElse: () => selectedRestroom!,
                            );
                            setState(() {
                              selectedRestroom = updatedRestroom;
                            });
                          }
                        });
                      }
                    });
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
                _lastFetchedCenter = null;
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _fetchRestrooms(pos, zoom: _defaultZoom, force: true);
                  }
                });
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
                  _currentZoom = _defaultZoom;
                });
                _fetchRestrooms(pos, zoom: _defaultZoom, force: true);
              }
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "add",
            onPressed: () async {
              final result = await showModalBottomSheet<Restroom>(
                context: context,
                barrierColor: Colors.black38,
                builder: (_) => RmbBottomSheet(
                  addType: BottomSheetType.restroom,
                  screenBuilder: (context) =>
                      AddingBathroomScreen(initCrossPos: center),
                ),
              );
              
              if (result != null && mounted) {
                setState(() {
                  _restrooms.add(result);
                });
              }
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
