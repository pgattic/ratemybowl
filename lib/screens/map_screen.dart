import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/controllers/location_controller.dart';
import '../widgets/bathroom_pin.dart';
import '../models/bathroom_location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  BathroomLocation? selectedLocation;
  int _mapVersion = 0;

  static const _defaultCenter = LatLng(40.24875188987069, -111.65141681875589);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationController>().init();
    });
  }

  @override
  void dispose() {
    context.read<LocationController>().disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bathroomLocations = MockBathroomData.getBathroomLocations();
    final lc = context.watch<LocationController>();

    final LatLng center = lc.userLatLong ?? _defaultCenter;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            key: ValueKey('map-$_mapVersion-$center'),
            options: MapOptions(
              initialCenter: center,
              initialZoom: 18.0,
              minZoom: 3.0,
              maxZoom: 24.0,
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
                    child: BathroomPin(
                      bathroomTypes: location.bathroomTypes,
                      isSelected: selectedLocation?.id == location.id,
                      onTap: () {
                        setState(() {
                          selectedLocation = location;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),

              if (lc.userLatLong != null && lc.accuracy != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: lc.userLatLong!,
                      radius: lc.accuracy!,
                      useRadiusInMeter: true,
                      color: Colors.blue.withValues(alpha: 0.30),
                      borderColor: Colors.blue.withValues(alpha: 0.40),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              if (lc.userLatLong != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: lc.userLatLong!,
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
          ),
        ],
      ),
    );
  }
}
