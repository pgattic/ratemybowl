import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/controllers/location_controller.dart';
import 'package:rate_my_bowl/models/restroom.dart';
import 'package:rate_my_bowl/screens/review_screen.dart';
import 'package:rate_my_bowl/services/restroom_service.dart';
import 'package:rate_my_bowl/widgets/selected_pin_bottom_sheet.dart';

enum RestroomSortMode { distance, rating }

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  List<Restroom> _restrooms = [];
  String? _error;

  RestroomSortMode _sortMode = RestroomSortMode.distance;
  final Distance _distanceCalc = const Distance();
  static const int _maxResults = 30;
  static const double _nearbyRadius = 50;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearUser();
    });
  }

  Future<void> _loadNearUser() async {
    final locationController = context.read<LocationController>();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (locationController.status == LocStatus.idle) {
      await locationController.init();
    }

    if (locationController.status == LocStatus.denied) {
      setState(() {
        _isLoading = false;
        _hasLoadedOnce = true;
        _error =
            "Location permission denied. Please enable location services in Settings.";
      });
      return;
    }

    if (locationController.status != LocStatus.ready ||
        locationController.userLatLong == null) {
      setState(() {
        _isLoading = false;
        _hasLoadedOnce = true;
      });
      return;
    }

    final userLatLng = locationController.userLatLong!;

    try {
      final results = await RestroomService.instance.getRestroomLocations(
        lat: userLatLng.latitude,
        lng: userLatLng.longitude,
        radius: _milesToMeters(_nearbyRadius),
      );

      setState(() {
        _restrooms = results;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      debugPrint('Error fetching restrooms: $e');
      setState(() {
        _isLoading = false;
        _hasLoadedOnce = true;
        _error = 'Failed to load restrooms. Please try again.';
      });
    }
  }

  List<Restroom> _getSortedRestrooms(LatLng? userLatLng) {
    final list = List<Restroom>.from(_restrooms);

    if (userLatLng != null) {
      list.sort((a, b) {
        final distA = _distanceTo(userLatLng, a);
        final distB = _distanceTo(userLatLng, b);
        return distA.compareTo(distB);
      });
    }

    final nearest = list.take(_maxResults).toList();

    if (_sortMode == RestroomSortMode.rating) {
      nearest.sort((a, b) {
        final r = b.rating.compareTo(a.rating);
        if (r != 0 || userLatLng == null) return r;

        final distA = _distanceTo(userLatLng, a);
        final distB = _distanceTo(userLatLng, b);
        return distA.compareTo(distB);
      });
    }

    return nearest;
  }

  double _distanceTo(LatLng userLatLng, Restroom r) {
    return _distanceCalc(
      userLatLng,
      LatLng(r.coordinates.latitude, r.coordinates.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationController>();
    final userLatLng = loc.userLatLong;

    final list = _getSortedRestrooms(userLatLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Restrooms"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadNearUser,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBanner(loc),
          _buildSortBar(),
          const Divider(height: 0),
          Expanded(child: _buildBody(list, userLatLng)),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(LocationController loc) {
    if (_isLoading || loc.status == LocStatus.checking) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        color: Colors.red.shade50,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
            TextButton(onPressed: _loadNearUser, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (loc.status == LocStatus.denied) {
      return Container(
        width: double.infinity,
        color: Colors.amber.shade50,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.amber),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Location permission denied. Enable it in settings to see nearby restrooms.",
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text("Sort by:", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          SegmentedButton<RestroomSortMode>(
            segments: const [
              ButtonSegment(
                value: RestroomSortMode.distance,
                icon: Icon(Icons.place),
                label: Text("Closest"),
              ),
              ButtonSegment(
                value: RestroomSortMode.rating,
                icon: Icon(Icons.star),
                label: Text("Rating"),
              ),
            ],
            selected: <RestroomSortMode>{_sortMode},
            onSelectionChanged: (set) {
              setState(() {
                _sortMode = set.first;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Restroom> list, LatLng? userLatLng) {
    if (_isLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasLoadedOnce && list.isEmpty) {
      return Center(
        child: Text(
          "No restrooms found within ${_nearbyRadius.toInt()} miles.",
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 0, color: Colors.black38),
      itemBuilder: (context, index) {
        final r = list[index];
        final distanceMeters = (userLatLng != null)
            ? _distanceTo(userLatLng, r)
            : null;
        final distanceMiles = (distanceMeters != null)
            ? _metersToMiles(distanceMeters)
            : null;

        final icon = switch (r.gender) {
          Gender.male => Icon(Icons.man, color: Colors.blueAccent),
          Gender.female => Icon(Icons.woman, color: Colors.pinkAccent),
          Gender.unisex => Icon(Icons.wc),
        };

        return Container(
          color: Colors.white54,
          child: ListTile(
            leading: icon,
            title: Text(r.name, style: TextStyle(color: Colors.black)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (distanceMiles != null)
                  Text(
                    "${distanceMiles.toStringAsFixed(2)} mi",
                    style: TextStyle(color: Colors.black45),
                  ),
                r.reviewCount > 0
                    ? Text(
                        "Rating: ${r.rating.toStringAsFixed(1)} ★ (${r.reviewCount})",
                        style: TextStyle(color: Colors.black45),
                      )
                    : Text(
                        "No reviews",
                        style: TextStyle(color: Colors.black45),
                      ),
              ],
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                barrierColor: Colors.black38,
                builder: (_) => SelectedPinBottomSheet(
                  restroom: r,
                  screenBuilder: (context) =>
                      ReviewScreen(restroomName: r.name, restroomId: r.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  double _milesToMeters(double distMiles) {
    return distMiles * 1609.344;
  }

  double _metersToMiles(double distMeters) {
    return distMeters / 1609.344;
  }
}
