import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shopspot/providers/location_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/product_provider.dart';
import '../providers/restaurant_provider.dart';
import '../models/product.dart';
import '../models/restaurant.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int restaurantId;
  final int productId;

  const ProductDetailsScreen({
    super.key,
    required this.restaurantId,
    required this.productId,
  });

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Restaurant? _restaurant;
  Position? _currentPosition;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRestaurantAndLocation();
  }

  Future<void> _loadRestaurantAndLocation() async {
    try {
      // Get restaurant details
      final restaurants =
          await Provider.of<RestaurantProvider>(context, listen: false)
              .getRestaurantsForProduct(widget.productId);

      final restaurant =
          restaurants.firstWhere((r) => r.id == widget.restaurantId);
      setState(() {
        _restaurant = restaurant;
      });

      // Get current location
      await _getCurrentLocation();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  double _calculateDistance() {
    if (_currentPosition == null || _restaurant == null) return 0;

    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _restaurant!.latitude,
          _restaurant!.longitude,
        ) /
        1000; // Convert to km
  }

  Future<void> _openMaps(context) async {
    if (_restaurant == null) return;
    var locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    locationProvider.openGoogleMapWithDestination(
        _restaurant!.latitude, _restaurant!.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Product?>(
              future: Provider.of<ProductProvider>(context, listen: false)
                  .getProductDetailsForRestaurant(
                      widget.restaurantId, widget.productId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Failed to load product details: ${snapshot.error ?? "Product not found"}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final product = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.fastfood, size: 60),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_restaurant != null) ...[
              const Divider(thickness: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Restaurant Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.restaurant),
                      title: Text(_restaurant!.name),
                      subtitle: Text(_restaurant!.location),
                    ),
                    if (_currentPosition != null)
                      ListTile(
                        leading: Icon(Icons.location_on),
                        title: Text(
                          'Distance: ${_calculateDistance().toStringAsFixed(2)} km',
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions'),
                        onPressed: () {
                          _openMaps(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              _restaurant!.latitude,
                              _restaurant!.longitude,
                            ),
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                              enableScrollWheel: false,
                            ),
                            // No direct equivalent for mapToolbarEnabled, zoomControlsEnabled
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              // subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName: 'com.example.shopspot',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    _restaurant!.latitude,
                                    _restaurant!.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(_restaurant!.name),
                                          content: Text(_restaurant!.location),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_currentPosition != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
