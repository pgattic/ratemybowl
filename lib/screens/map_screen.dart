import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/controllers/location_controller.dart';
import 'package:rate_my_bowl/screens/adding_bathroom_screen.dart';
import 'package:rate_my_bowl/screens/review_screen.dart';
import 'package:rate_my_bowl/widgets/rmb_bottom_sheet.dart';
import '../widgets/bathroom_pin.dart';
import '../models/bathroom_location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  BathroomLocation? selectedLocation;
  Map<String, Object>? _currentReview;
  late final MapController _mapController;
  bool _didCenterOnFirstFix = false;

  static const _defaultCenter = LatLng(40.24875188987069, -111.65141681875589);
  static const _defaultZoom = 18.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationController>().init();
    });
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
    final bathroomLocations = MockBathroomData.getBathroomLocations();
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
          },
          onLongPress: (tapPosition, latLng) {
            showModalBottomSheet(
              context: context,
              barrierColor: Colors.black38,
              builder: (_) => RmbBottomSheet(
                addType: "restroom",
                screenBuilder: (context) => AddingBathroomScreen(),
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
            markers: bathroomLocations.map((location) {
              return Marker(
                point: location.coordinates,
                width: 40,
                height: 50,
                alignment: Alignment.topCenter,
                child: BathroomPin(
                  bathroomTypes: location.bathroomTypes,
                  isSelected: selectedLocation?.id == location.id,
                  onTap: () {
                    setState(() {
                      selectedLocation = location;
                    });

                    showModalBottomSheet(
                      context: context,
                      barrierColor: Colors.black38,
                      builder: (_) => RmbBottomSheet(
                        addType: "review",
                        screenBuilder: (context) =>
                            ReviewScreen(hintText: "test"),
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
                  screenBuilder: (context) => AddingBathroomScreen(),
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
