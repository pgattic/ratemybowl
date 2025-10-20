import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/bathroom_pin.dart';
import '../models/bathroom_location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  BathroomLocation? selectedLocation;

  @override
  Widget build(BuildContext context) {
    final bathroomLocations = MockBathroomData.getBathroomLocations();

    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(40.24875188987069, -111.65141681875589), // JFSB coordinates (where we'll be demoing). Eventually, this will be dynamic based on the user's location.
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
      ],
    );
  }
}
