import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shopspot/cubit/location_cubit/location_cubit.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopspot/models/restaurant_model.dart';

class RestaurantsMapScreen extends StatefulWidget {
  final List<Restaurant> restaurants;
  final String productName;

  const RestaurantsMapScreen({
    super.key,
    required this.restaurants,
    required this.productName,
  });

  @override
  State<RestaurantsMapScreen> createState() => _RestaurantsMapScreenState();
}

class _RestaurantsMapScreenState extends State<RestaurantsMapScreen> {
  final MapController _mapController = MapController();
  List<Marker>? _markers;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _createMarkers());
  }

  void _createMarkers() {
    setState(() {
      _markers = widget.restaurants.map((restaurant) {
        // Pre-calculate distance if available
        final locationCubit = context.read<LocationCubit>();
        final distance = locationCubit.getDistanceSync(restaurant);
        final String distanceText =
            distance != null ? locationCubit.formatDistance(distance) : '';

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
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant.location),
                      if (distanceText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_walk,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                distanceText,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.restaurantDetails,
                          arguments: {
                            'restaurant': restaurant,
                          },
                        );
                      },
                      child: const Text('Details'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        launchUrl(
                          Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${restaurant.latitude},${restaurant.longitude}&travelmode=driving',
                          ),
                        );
                      },
                      child: const Text('Directions'),
                    ),
                  ],
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.restaurant,
                  color: Theme.of(context).colorScheme.error,
                  size: 30,
                ),
                if (distanceText.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      distanceText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList();
    });
  }

  void _fitBounds({bool includeUserLocation = true}) {
    if (widget.restaurants.isEmpty) return;

    final locationCubit = context.read<LocationCubit>();
    final hasLocation =
        locationCubit.currentLocation != null && includeUserLocation;

    double minLat = hasLocation
        ? locationCubit.currentLocation!.latitude
        : widget.restaurants.first.latitude;
    double maxLat = minLat;
    double minLng = hasLocation
        ? locationCubit.currentLocation!.longitude
        : widget.restaurants.first.longitude;
    double maxLng = minLng;

    for (var restaurant in widget.restaurants) {
      if (restaurant.latitude < minLat) {
        minLat = restaurant.latitude;
      } else if (restaurant.latitude > maxLat) {
        maxLat = restaurant.latitude;
      }
      if (restaurant.longitude < minLng) {
        minLng = restaurant.longitude;
      } else if (restaurant.longitude > maxLng) {
        maxLng = restaurant.longitude;
      }
    }

    // Add some padding to the bounds
    final bounds = LatLngBounds(
      LatLng(minLat - 0.01, minLng - 0.01),
      LatLng(maxLat + 0.01, maxLng + 0.01),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final locationCubit = context.read<LocationCubit>();

      // Check permission first
      final hasPermission =
          await LocationCubit.checkLocationPermission(request: true);
      if (!hasPermission) {
        Fluttertoast.showToast(
          msg: 'Location permission denied. Please enable in settings.',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
        return;
      }

      await locationCubit.refreshLocation();

      // Re-create markers with updated distances
      _createMarkers();

      // Fit bounds to include new location
      _fitBounds();

      Fluttertoast.showToast(
        msg: 'Location updated',
        backgroundColor: getSuccessColor(context),
      );
    } catch (e) {
      debugPrint('Error refreshing location: $e');
      Fluttertoast.showToast(
        msg: 'Failed to update location',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationCubit = context.read<LocationCubit>();

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
        title: Text(
          'Restaurants for ${widget.productName}',
          style:  TextStyle(
            fontSize: 18
          ),
        ),
        actions: [
          _isRefreshing
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh location',
                  onPressed: _refreshLocation,
                ),
        ],
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
            Future.delayed(
                const Duration(milliseconds: 200), () => _fitBounds());
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.shopspot',
          ),
          if (_markers != null) MarkerLayer(markers: _markers!),
          // Current Location Marker
          if (locationCubit.currentLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    locationCubit.currentLocation!.latitude,
                    locationCubit.currentLocation!.longitude,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _fitBounds(),
        tooltip: 'Fit all markers',
        child: const Icon(Icons.fullscreen),
      ),
    );
  }
}
