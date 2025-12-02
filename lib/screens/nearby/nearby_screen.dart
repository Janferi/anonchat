import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/nearby_provider.dart';
import 'chat_room_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check permission again just in case
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        Provider.of<NearbyProvider>(
          context,
          listen: false,
        ).fetchNearbyRooms(position.latitude, position.longitude);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nearbyProvider = Provider.of<NearbyProvider>(context);

    if (_isLoadingLocation) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentPosition == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Map')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Location access is required to find nearby rooms.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: const Text('Retry / Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Map')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentPosition!,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.anonchat',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _currentPosition!,
                    color: Colors.blue.withOpacity(0.1),
                    borderStrokeWidth: 2,
                    borderColor: Colors.blue,
                    useRadiusInMeter: true,
                    radius: nearbyProvider.radius,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // User's location
                  Marker(
                    point: _currentPosition!,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                  // Nearby rooms
                  ...nearbyProvider.rooms.map(
                    (room) => Marker(
                      point: LatLng(room.lat, room.lon),
                      width: 80,
                      height: 80,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    room.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${room.memberCount} members • ${room.distance}m away',
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ChatRoomScreen(room: room),
                                        ),
                                      );
                                    },
                                    child: const Text('Join Room'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Radius: ${nearbyProvider.radius.toInt()}m',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${nearbyProvider.rooms.length} Rooms Found',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: nearbyProvider.radius,
                      min: 100,
                      max: 5000,
                      divisions: 49,
                      label: '${nearbyProvider.radius.toInt()}m',
                      onChanged: (value) {
                        nearbyProvider.setRadius(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
