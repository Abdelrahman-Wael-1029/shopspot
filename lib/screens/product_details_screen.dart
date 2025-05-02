import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopspot/utils/app_colors.dart';
import '../providers/location_provider.dart';
import '../models/product.dart';
import '../models/restaurant.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Restaurant? restaurant;
  final Product product;

  const ProductDetailsScreen({
    super.key,
    this.restaurant,
    required this.product,
  });

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        // make linear loading in bottom
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: (locationProvider.loading)
                ? LinearProgressIndicator()
                : SizedBox.shrink()),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            CachedNetworkImage(
              imageUrl: widget.product.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: AppColors.lightGrey,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: AppColors.lightGrey,
                child: Icon(
                  Icons.fastfood,
                  size: 60,
                  color: AppColors.grey,
                ),
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),

            // Restaurant Information
            if (widget.restaurant != null) ...[
              Divider(
                thickness: 1,
                color: AppColors.border,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restaurant Information',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Restaurant Name & Location
                    ListTile(
                      leading: Icon(
                        Icons.restaurant,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        widget.restaurant!.name,
                        style: theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        widget.restaurant!.location,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),

                    // Distance
                    if (locationProvider.hasLocation)
                      ListTile(
                        leading: Icon(
                          Icons.location_on,
                          color: AppColors.secondary,
                        ),
                        title: Text(
                          'Distance: ${locationProvider.calculateDistance(
                                widget.restaurant!.latitude,
                                widget.restaurant!.longitude,
                              ).toStringAsFixed(2)} km',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),

                    // Get Directions Button
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions'),
                        onPressed: () {
                          locationProvider.openGoogleMapWithDestination(
                            widget.restaurant!.latitude,
                            widget.restaurant!.longitude,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    // refresh location if not have permission or location
                    if (!locationProvider.hasLocation ||
                        !locationProvider.hasPermission)
                      const SizedBox(height: 16),
                    if (!locationProvider.hasLocation ||
                        !locationProvider.hasPermission)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.location_on),
                          label: const Text('Refresh Location'),
                          onPressed: locationProvider.refreshLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    // Map
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              widget.restaurant!.latitude,
                              widget.restaurant!.longitude,
                            ),
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                              enableScrollWheel: false,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.shopspot',
                            ),

                            // Restaurant Marker
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    widget.restaurant!.latitude,
                                    widget.restaurant!.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                            widget.restaurant!.name,
                                            style: theme.textTheme.headlineLarge
                                                ?.copyWith(
                                              fontSize: 18,
                                            ),
                                          ),
                                          content: Text(
                                            widget.restaurant!.location,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(
                                                'Close',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                          backgroundColor: AppColors.card,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.location_on,
                                      color: AppColors.error,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Current Location Marker
                            if (locationProvider.hasLocation)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      locationProvider
                                          .currentLocation!.latitude,
                                      locationProvider
                                          .currentLocation!.longitude,
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
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Error Message
            if (locationProvider.error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  locationProvider.error!,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
