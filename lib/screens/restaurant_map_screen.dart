import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/providers/location_provider.dart';
import 'package:shopspot/utils/app_colors.dart';
import '../models/restaurant.dart';

class RestaurantMapScreen extends StatefulWidget {
  final List<Restaurant> restaurants;
  final String productName;

  const RestaurantMapScreen({
    super.key,
    required this.restaurants,
    required this.productName,
  });

  @override
  _RestaurantMapScreenState createState() => _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends State<RestaurantMapScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  void _createMarkers() {
    _markers = widget.restaurants.map((restaurant) {
      return Marker(
        point: LatLng(restaurant.latitude, restaurant.longitude),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(restaurant.name),
                content: Text(restaurant.location),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      var locationProvider =
                          Provider.of<LocationProvider>(context, listen: false);
                      locationProvider.openGoogleMapWithDestination(
                          restaurant.latitude, restaurant.longitude);
                    },
                    child: Text('Open Maps'),
                  ),
                ],
              ),
            );
          },
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }).toList();
  }

  void _fitBounds() {
    if (widget.restaurants.isEmpty) return;

    double minLat = widget.restaurants.first.latitude;
    double maxLat = widget.restaurants.first.latitude;
    double minLng = widget.restaurants.first.longitude;
    double maxLng = widget.restaurants.first.longitude;

    for (var restaurant in widget.restaurants) {
      if (restaurant.latitude < minLat) minLat = restaurant.latitude;
      if (restaurant.latitude > maxLat) maxLat = restaurant.latitude;
      if (restaurant.longitude < minLng) minLng = restaurant.longitude;
      if (restaurant.longitude > maxLng) maxLng = restaurant.longitude;
    }

    // Add some padding to the bounds
    final bounds = LatLngBounds(
      LatLng(minLat - 0.05, minLng - 0.05),
      LatLng(maxLat + 0.05, maxLng + 0.05),
    );

    _mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(
        padding: EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    if (widget.restaurants.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Restaurants for ${widget.productName}'),
        ),
        body: const Center(
          child: Text('No restaurants available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurants for ${widget.productName}'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(
            widget.restaurants.first.latitude,
            widget.restaurants.first.longitude,
          ),
          initialZoom: 12,
          onMapReady: () {
            Future.delayed(const Duration(milliseconds: 200), _fitBounds);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            // subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.shopspot',
          ),
          MarkerLayer(markers: _markers),
          // Current Location Marker
          if (locationProvider.hasLocation)
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    locationProvider.currentLocation!.latitude,
                    locationProvider.currentLocation!.longitude,
                  ),
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.my_location,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
