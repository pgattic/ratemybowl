import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:rate_my_bowl/controllers/location_controller.dart';
import 'package:rate_my_bowl/screens/adding_restroom_screen.dart';
import 'package:rate_my_bowl/screens/review_screen.dart';
import 'package:rate_my_bowl/widgets/add_restroom_bottom_sheet.dart';
import 'package:rate_my_bowl/services/restroom_service.dart';
import 'package:rate_my_bowl/models/restroom.dart';
import 'package:rate_my_bowl/widgets/selected_pin_bottom_sheet.dart';
import '../widgets/restroom_pin.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Map + restroom state
  final MapController _mapController = MapController();
  final List<Restroom> _restrooms = [];

  Restroom? _selectedRestroom;
  bool _isLoadingRestrooms = false;
  LatLng? _lastFetchedCenter;

  // Debouncing & zoom
  Timer? _debounceTimer;
  LatLng? _pendingCenter;
  double _currentZoom = _defaultZoom;

  // User/location
  late final LocationController _locationController;
  bool _didCenterOnFirstFix = false;

  // Constants
  static const _defaultCenter = LatLng(40.24875188987069, -111.65141681875589);
  static const _defaultZoom = 18.0;
  static const _minFetchDistance = 200.0; // meters
  static const _debounceDelay = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();

    // Grab controller once, and reuse it. This avoids using context in dispose.
    _locationController = context.read<LocationController>();

    // Kick off location init after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationController.init();

      final userLocation = _locationController.userLatLong;
      final initialCenter = userLocation ?? _defaultCenter;

      // Center map and perform an initial fetch around this point.
      _mapController.move(initialCenter, _defaultZoom);
      _currentZoom = _defaultZoom;
      _fetchRestrooms(initialCenter, zoom: _defaultZoom, force: true);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  double _calculateRadiusFromZoom(double zoom) {
    // Rough heuristic: larger radius at low zoom.
    const baseRadius = 500.0; // meters
    const maxZoom = 18.0;
    final radius = baseRadius * math.pow(2, maxZoom - zoom);
    return radius.clamp(200.0, 100000.0);
  }

  double _approximateDistanceInMeters(LatLng a, LatLng b) {
    // Rough approximation; good enough for "should we refetch?" decisions.
    const metersPerDegreeLat = 111000.0;
    final avgLatRad = (a.latitude + b.latitude) / 2.0 * math.pi / 180.0;
    final metersPerDegreeLng = 111000.0 * math.cos(avgLatRad);

    final latMeters = (a.latitude - b.latitude).abs() * metersPerDegreeLat;
    final lngMeters = (a.longitude - b.longitude).abs() * metersPerDegreeLng;

    return math.sqrt(latMeters * latMeters + lngMeters * lngMeters);
  }

  void _debouncedFetchRestrooms(LatLng center, {double? zoom}) {
    _debounceTimer?.cancel();

    _pendingCenter = center;
    if (zoom != null) {
      _currentZoom = zoom;
    }

    _debounceTimer = Timer(_debounceDelay, () {
      if (!mounted || _pendingCenter == null) return;
      final centerToFetch = _pendingCenter!;
      _pendingCenter = null;

      _fetchRestrooms(centerToFetch, zoom: _currentZoom);
    });
  }

  Future<void> _fetchRestrooms(
    LatLng center, {
    bool force = false,
    double? zoom,
  }) async {
    if (!mounted) return;

    if (!force) {
      // Avoid overlapping fetches; just schedule a debounced one instead.
      if (_isLoadingRestrooms) {
        _debouncedFetchRestrooms(center, zoom: zoom);
        return;
      }
    } else {
      // Clear any pending debounce when forcing.
      _debounceTimer?.cancel();
      _debounceTimer = null;
      _pendingCenter = null;
    }

    final usedZoom = zoom ?? _currentZoom;
    final radius = _calculateRadiusFromZoom(usedZoom);

    // Skip fetches if user hasn't moved much and zoom hasn't changed.
    if (!force && _lastFetchedCenter != null) {
      final distance = _approximateDistanceInMeters(
        center,
        _lastFetchedCenter!,
      );
      if (distance < _minFetchDistance) {
        return;
      }
    }

    setState(() {
      _isLoadingRestrooms = true;
      _currentZoom = usedZoom;
    });

    try {
      final restrooms = await RestroomService.instance.getRestroomLocations(
        lat: center.latitude,
        lng: center.longitude,
        radius: radius,
      );

      if (!mounted) return;

      setState(() {
        _restrooms
          ..clear()
          ..addAll(restrooms);
        _isLoadingRestrooms = false;
        _lastFetchedCenter = center;
      });
    } catch (e, st) {
      // TODO: swap this for proper error tracking / snackbar.
      debugPrint('Error fetching restrooms: $e\n$st');
      if (!mounted) return;

      setState(() {
        _isLoadingRestrooms = false;
      });
    }
  }

  void _centerOn(LatLng pos, {double zoom = _defaultZoom}) {
    _mapController.move(pos, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = context.select<LocationController, LatLng?>(
      (lc) => lc.userLatLong,
    );
    final initialCenter = userLocation ?? _defaultCenter;

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: _currentZoom,
          minZoom: 3.0,
          maxZoom: 24.0,
          onMapEvent: (event) {
            final cam = event.camera;
            final newCenter = cam.center;
            final newZoom = cam.zoom;

            // Once we've done any initial fetch, we can base everything on camera.
            if (_lastFetchedCenter != null || _didCenterOnFirstFix) {
              _debouncedFetchRestrooms(newCenter, zoom: newZoom);
            }
          },
          onLongPress: (tapPosition, latLng) async {
            final result = await showModalBottomSheet<Restroom>(
              context: context,
              barrierColor: Colors.black38,
              builder: (_) => AddRestroomBottomSheet(
                screenBuilder: (context) =>
                    AddingRestroomScreen(initCrossPos: latLng),
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
            userAgentPackageName: 'com.tinklethinkers.rate_my_bowl',
          ),
          MarkerLayer(
            markers: _restrooms.map((restroom) {
              final isSelected = _selectedRestroom?.id == restroom.id;
              return Marker(
                point: restroom.coordinates,
                width: 40,
                height: 50,
                alignment: Alignment.topCenter,
                child: RestroomPin(
                  restroomGender: restroom.gender,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedRestroom = restroom;
                    });

                    _centerOn(
                      restroom.coordinates,
                      zoom: _mapController.camera.zoom,
                    );

                    showModalBottomSheet(
                          context: context,
                          barrierColor: Colors.black38,
                          builder: (_) => SelectedPinBottomSheet(
                            restroom: restroom,
                            screenBuilder: (context) => ReviewScreen(
                              restroomName: restroom.name,
                              restroomId: restroom.id,
                            ),
                          ),
                        )
                        .then((result) async {
                          if (!mounted) return;

                          final success =
                              result is Map && result['success'] == true;
                          if (!success) return;

                          final currentCenter = _mapController.camera.center;
                          await _fetchRestrooms(
                            currentCenter,
                            zoom: _currentZoom,
                            force: true,
                          );

                          if (!mounted) return;

                          if (_selectedRestroom != null) {
                            final updated = _restrooms.firstWhere(
                              (r) => r.id == _selectedRestroom!.id,
                              orElse: () => _selectedRestroom!,
                            );
                            setState(() {
                              _selectedRestroom = updated;
                            });
                          }
                        })
                        .whenComplete(() {
                          if (!mounted) return;
                          setState(() {
                            _selectedRestroom = null;
                          });
                        });
                  },
                ),
              );
            }).toList(),
          ),

          // User location marker + accuracy circle
          _UserLocationLayer(
            onFirstFix: (pos) {
              if (_didCenterOnFirstFix || !mounted) return;

              _didCenterOnFirstFix = true;
              _centerOn(pos, zoom: _defaultZoom);
              _fetchRestrooms(pos, zoom: _defaultZoom, force: true);
            },
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recenter on user
          if (userLocation != null) ...[
            FloatingActionButton(
              heroTag: "recenter",
              onPressed: () {
                _centerOn(userLocation, zoom: _defaultZoom);
                _fetchRestrooms(userLocation, zoom: _defaultZoom, force: true);
              },
              child: const Icon(Icons.my_location),
            ),
            const SizedBox(height: 12),
          ],

          // Add restroom at current map center
          FloatingActionButton(
            heroTag: "add",
            onPressed: () async {
              final center = _mapController.camera.center;
              final result = await showModalBottomSheet<Restroom>(
                context: context,
                barrierColor: Colors.black38,
                builder: (_) => AddRestroomBottomSheet(
                  screenBuilder: (context) =>
                      AddingRestroomScreen(initCrossPos: center),
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

    // Fire callback once when we get first non-null fix.
    if (userPos != null && !_hasCalledFirstFix) {
      _hasCalledFirstFix = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
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
