import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/product_provider.dart';
import '../providers/restaurant_provider.dart';
import '../models/product.dart';
import '../models/restaurant.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int restaurantId;
  final int productId;

  const ProductDetailsScreen({
    Key? key, 
    required this.restaurantId, 
    required this.productId,
  }) : super(key: key);

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
      final restaurants = await Provider.of<RestaurantProvider>(context, listen: false)
          .getRestaurantsForProduct(widget.productId);
      
      final restaurant = restaurants.firstWhere((r) => r.id == widget.restaurantId);
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
    ) / 1000; // Convert to km
  }

  Future<void> _openGoogleMaps() async {
    if (_restaurant == null) return;
    
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${_restaurant!.latitude},${_restaurant!.longitude}';
    
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps app')),
      );
    }
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
                  .getProductDetailsForRestaurant(widget.restaurantId, widget.productId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
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
                        onPressed: _openGoogleMaps,
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
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _restaurant!.latitude,
                              _restaurant!.longitude,
                            ),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(_restaurant!.id.toString()),
                              position: LatLng(
                                _restaurant!.latitude,
                                _restaurant!.longitude,
                              ),
                              infoWindow: InfoWindow(
                                title: _restaurant!.name,
                                snippet: _restaurant!.location,
                              ),
                            ),
                          },
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationEnabled: _currentPosition != null,
                          myLocationButtonEnabled: false,
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