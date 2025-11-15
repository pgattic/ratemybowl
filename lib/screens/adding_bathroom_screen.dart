import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/restroom.dart';
import '../services/bathroom_service.dart';

class AddingBathroomScreen extends StatefulWidget {
  final LatLng? initCrossPos;
  const AddingBathroomScreen({super.key, this.initCrossPos});

  @override
  State<AddingBathroomScreen> createState() => _AddingBathroomScreenState();
}

class _AddingBathroomScreenState extends State<AddingBathroomScreen> {
  final TextEditingController _nameController = TextEditingController();
  late double _centerLat;
  late double _centerLng;
  Gender _selectedGender = Gender.Unisex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final pos = widget.initCrossPos;
    _centerLat = pos?.latitude ?? 40.24875188987069;
    _centerLng = pos?.longitude ?? -111.65141681875589;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveRestroom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a bathroom name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final restroom = Restroom(
        name: name,
        coordinates: LatLng(_centerLat, _centerLng),
        gender: _selectedGender,
        rating: 0.0,
        reviewCount: 0,
        attributes: [],
      );

      await BathroomService.instance.addRestroom(restroom);

      if (mounted) {
        final result = {
          'name': name,
          'latitude': _centerLat,
          'longitude': _centerLng,
          'gender': _selectedGender.name,
        };
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding bathroom: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Adding New Bathroom',
          style: GoogleFonts.quicksand(
            fontSize: 26.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.lightBlueAccent,
        elevation: 0,
      ),
      backgroundColor: Colors.lightBlueAccent,
      body: DefaultTextStyle(
        style: GoogleFonts.quicksand(
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Text(
                'Bathroom Name',
                style: GoogleFonts.quicksand(
                  fontSize: 26.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Bathroom name',
                        labelStyle: GoogleFonts.quicksand(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 14.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
              child: Text(
                'Gender',
                style: GoogleFonts.quicksand(
                  fontSize: 26.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: DropdownButtonFormField<Gender>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 14.0,
                    ),
                  ),
                  items: Gender.values.map((gender) {
                    return DropdownMenuItem<Gender>(
                      value: gender,
                      child: Text(
                        gender.name,
                        style: GoogleFonts.quicksand(),
                      ),
                    );
                  }).toList(),
                  onChanged: (Gender? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 18.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25.0),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(_centerLat, _centerLng),
                        initialZoom: 18.0,
                        minZoom: 3.0,
                        maxZoom: 24.0,
                        onPositionChanged: (position, hasGesture) {
                          setState(() {
                            _centerLat = position.center.latitude;
                            _centerLng = position.center.longitude;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.rate_my_bowl',
                        ),
                      ],
                    ),
                    const Center(
                      child: Icon(
                        Icons.add,
                        size: 36,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Center: ${_centerLat.toStringAsFixed(6)}, ${_centerLng.toStringAsFixed(6)}',
                style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontSize: 14.0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveRestroom,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Bathroom'),
                ),
              ),
            ),
          ], // end of Column children
        ),
      ),
    );
  }
}
