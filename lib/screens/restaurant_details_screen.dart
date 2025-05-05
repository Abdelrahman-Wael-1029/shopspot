import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopspot/services/connectivity_service.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/models/restaurant_model.dart';
import 'package:shopspot/providers/favorite_provider.dart';
import 'package:shopspot/providers/restaurant_provider.dart';
import 'package:shopspot/widgets/restaurant_location_widget.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Get the current favorite status from the provider
    final isFavorite = widget.restaurant.isFavorite;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        actions: [
          // Favorite button
          _isLoading
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
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  onPressed: () => _updateFavoriteStatus(isFavorite),
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant image
            SizedBox(
              height: 250,
              width: double.infinity,
              child: _buildImage(),
            ),

            // Restaurant details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name
                  Text(
                    widget.restaurant.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Integrated location widget (map + distance + directions)
                  RestaurantLocationWidget(restaurant: widget.restaurant),

                  const SizedBox(height: 16),

                  // Restaurant description
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.restaurant.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // View Products button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_bag),
                      label: const Text('View Products'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.products,
                          arguments: {
                            'restaurant': widget.restaurant,
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateFavoriteStatus(isFavorite) async {
    // Check connectivity status first
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);

    if (!connectivityService.isOnline) {
      // Show toast message when offline
      Fluttertoast.showToast(
        msg: 'You are offline. Please check your connection.',
        backgroundColor: Colors.red,
      );
      return;
    }

    // Also check if server is unavailable for favorites
    if (connectivityService.isServerUnavailable) {
      // Show toast message when server is unavailable
      Fluttertoast.showToast(
        msg: 'Unable to connect to the server. Please try again later.',
        backgroundColor: Colors.orange,
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the favorite provider
      final favoriteProvider =
          Provider.of<FavoriteProvider>(context, listen: false);
      // Get the restaurant provider
      final restaurantProvider =
          Provider.of<RestaurantProvider>(context, listen: false);

      // Call the appropriate method directly based on current state
      bool success = false;
      try {
        success =
            await favoriteProvider.toggleFavorite(widget.restaurant, context);
      } catch (e) {
        success = false;
      }

      // If successful, update the restaurant provider to ensure UI consistency
      if (success) {
        restaurantProvider.updateFavoriteStatus(
            widget.restaurant.id, !isFavorite // Toggle the current state
            );
      } else {
        // Show toast message that there was a problem connecting to the server
        Fluttertoast.showToast(
          msg: 'Unable to connect to the server. Please try again later.',
          backgroundColor: Colors.orange,
        );
      }
    } catch (e) {
      // Show error message
      Fluttertoast.showToast(
        msg: 'Something went wrong. Please try again.',
        backgroundColor: Colors.orange,
      );
    } finally {
      // Always reset loading state if mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImage() {
    return CachedNetworkImage(
      imageUrl: widget.restaurant.imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => _buildImageErrorPlaceholder(),
    );
  }

  // Simplified error placeholder
  Widget _buildImageErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.image_not_supported,
              size: 40,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
