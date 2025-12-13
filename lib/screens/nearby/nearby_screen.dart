import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/nearby_provider.dart';
import 'chat_room_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final MapController _mapController = MapController();
  bool _hasCentered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NearbyProvider>(context, listen: false).initializeLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nearbyProvider = Provider.of<NearbyProvider>(context);

    // Initial Loading State
    if (nearbyProvider.isLoading && nearbyProvider.currentPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Permission / No Location State
    if (nearbyProvider.currentPosition == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Select Chat Area',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Location access is required.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: nearbyProvider.initializeLocation,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    // Auto center map once
    if (!_hasCentered && nearbyProvider.currentPosition != null) {
      _hasCentered = true;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Select Chat Area',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
            tooltip: 'Create Room',
            onPressed: () => _showCreateRoomDialog(context),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Rounded Map Container
              Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: nearbyProvider.currentPosition!,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.anonchat',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: nearbyProvider.currentPosition!,
                            color: Colors.blue.withOpacity(0.2),
                            borderStrokeWidth: 2,
                            borderColor: Colors.blue,
                            useRadiusInMeter: true,
                            radius: nearbyProvider.radius,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // User Location
                          Marker(
                            point: nearbyProvider.currentPosition!,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blueAccent,
                              size: 30,
                            ),
                          ),
                          // Rooms
                          ...nearbyProvider.rooms.map(
                            (room) => Marker(
                              point: LatLng(room.lat, room.lon),
                              width: 60,
                              height: 60,
                              child: GestureDetector(
                                onTap: () => _showRoomDetails(context, room),
                                child: Icon(
                                  Icons.location_on,
                                  color: room.isSystem
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 35,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Radius Pills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RadiusPill(
                    label: '10m',
                    value: 10,
                    groupValue: nearbyProvider.radius,
                    onTap: () => nearbyProvider.setRadius(10),
                  ),
                  _RadiusPill(
                    label: '100m',
                    value: 100,
                    groupValue: nearbyProvider.radius,
                    onTap: () => nearbyProvider.setRadius(100),
                  ),
                  _RadiusPill(
                    label: '1km',
                    value: 1000,
                    groupValue: nearbyProvider.radius,
                    onTap: () => nearbyProvider.setRadius(1000),
                  ),
                  _RadiusPill(
                    label: '5km',
                    value: 5000,
                    groupValue: nearbyProvider.radius,
                    onTap: () => nearbyProvider.setRadius(5000),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Helper Text
              const Text(
                'You will join a chat with others inside this circle.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 40),
              // Enter Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    nearbyProvider.initializeLocation(); // Refresh
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scanning for rooms...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Enter Nearby Chat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoomDetails(BuildContext context, dynamic room) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              room.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${room.memberCount} members • ${room.distance}m away',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(room: room),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Join Room',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Room'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Enter room name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await Provider.of<NearbyProvider>(
                    context,
                    listen: false,
                  ).createRoom(nameController.text.trim());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Room created!')),
                    );
                  }
                } catch (e) {
                  // handle error
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _RadiusPill extends StatelessWidget {
  final String label;
  final double value;
  final double groupValue;
  final VoidCallback onTap;

  const _RadiusPill({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
