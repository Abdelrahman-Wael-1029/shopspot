import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/providers/restaurant_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopspot/models/restaurant_model.dart';
import 'package:shopspot/providers/location_provider.dart';

class RestaurantLocationWidget extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantLocationWidget({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantLocationWidget> createState() =>
      _RestaurantLocationWidgetState();
}

class _RestaurantLocationWidgetState extends State<RestaurantLocationWidget> {
  final MapController _mapController = MapController();
  double? distance;
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    distance = locationProvider.getDistanceSync(widget.restaurant);
    final hasUserLocation = locationProvider.currentLocation != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini map
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(widget.restaurant.latitude,
                        widget.restaurant.longitude),
                    initialZoom: 14,
                    onMapReady: () {
                      if (hasUserLocation) {
                        _fitBothLocations(locationProvider);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.shopspot',
                    ),
                    MarkerLayer(
                      markers: [
                        // Restaurant marker
                        Marker(
                          point: LatLng(widget.restaurant.latitude,
                              widget.restaurant.longitude),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.red,
                            size: 30,
                          ),
                        ),
                        // Current location marker (if available)
                        if (hasUserLocation)
                          Marker(
                            point: LatLng(
                              locationProvider.currentLocation!.latitude,
                              locationProvider.currentLocation!.longitude,
                            ),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // Distance indicator
                if (distance != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            locationProvider.formatDistance(distance!),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Refresh button overlay
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: FloatingActionButton.small(
                    onPressed: _isRefreshing
                        ? null
                        : () => _refreshLocation(locationProvider),
                    child: _isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Get directions button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                onPressed: () {
                  launchUrl(Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&destination=${widget.restaurant.latitude},${widget.restaurant.longitude}&travelmode=driving',
                  ));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fitBothLocations(LocationProvider locationProvider) {
    if (locationProvider.currentLocation == null) return;

    // Create a bounding box that includes both the user's location and the restaurant
    final bounds = LatLngBounds(
      LatLng(
        // Find the minimum of the two latitudes and add some padding
        (locationProvider.currentLocation!.latitude <
                widget.restaurant.latitude)
            ? locationProvider.currentLocation!.latitude - 0.01
            : widget.restaurant.latitude - 0.01,
        // Find the minimum of the two longitudes and add some padding
        (locationProvider.currentLocation!.longitude <
                widget.restaurant.longitude)
            ? locationProvider.currentLocation!.longitude - 0.01
            : widget.restaurant.longitude - 0.01,
      ),
      LatLng(
        // Find the maximum of the two latitudes and add some padding
        (locationProvider.currentLocation!.latitude >
                widget.restaurant.latitude)
            ? locationProvider.currentLocation!.latitude + 0.01
            : widget.restaurant.latitude + 0.01,
        // Find the maximum of the two longitudes and add some padding
        (locationProvider.currentLocation!.longitude >
                widget.restaurant.longitude)
            ? locationProvider.currentLocation!.longitude + 0.01
            : widget.restaurant.longitude + 0.01,
      ),
    );

    // Delay slightly to ensure the map is properly initialized
    Future.delayed(const Duration(milliseconds: 200), () {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40),
        ),
      );
    });
  }

  Future<void> _refreshLocation(LocationProvider locationProvider) async {
    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Check permission first
      final hasPermission =
          await LocationProvider.checkLocationPermission(request: true);
      if (!hasPermission) {
        Fluttertoast.showToast(
          msg: 'Location permission denied. Please enable in settings.',
          backgroundColor: Colors.red,
        );
        return;
      }

      await locationProvider.refreshLocation();

      // Update the map view
      if (locationProvider.currentLocation != null) {
        _fitBothLocations(locationProvider);
        if (mounted) {
          await restaurantProvider.refreshRestaurantsDistances(context);
        }
        distance = locationProvider.getDistanceSync(widget.restaurant);
      }

      Fluttertoast.showToast(
        msg: 'Location updated',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to update location',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
}
