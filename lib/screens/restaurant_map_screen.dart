import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  void _createMarkers() {
    _markers = widget.restaurants.map((restaurant) {
      return Marker(
        markerId: MarkerId(restaurant.id.toString()),
        position: LatLng(restaurant.latitude, restaurant.longitude),
        infoWindow: InfoWindow(
          title: restaurant.name,
          snippet: restaurant.location,
        ),
      );
    }).toSet();
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

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.05, minLng - 0.05),
          northeast: LatLng(maxLat + 0.05, maxLng + 0.05),
        ),
        50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurants for ${widget.productName}'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            widget.restaurants.first.latitude,
            widget.restaurants.first.longitude,
          ),
          zoom: 12,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          Future.delayed(Duration(milliseconds: 200), _fitBounds);
        },
      ),
    );
  }
} 