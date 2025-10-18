import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(40.24875188987069, -111.65141681875589), // JFSB coordinates (where we'll be demoing). Eventually, this will be dynamic based on the user's location.
        initialZoom: 18.0,
        minZoom: 3.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.rate_my_bowl',
          maxZoom: 18,
        ),
        // Future pins will be added here as MarkerLayer widgets
      ],
    );
  }
}
