import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopspot/cubit/location_cubit/location_state.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/models/restaurant_model.dart';
import 'package:shopspot/cubit/location_cubit/location_cubit.dart';
import 'package:shopspot/services/connectivity_service/connectivity_service.dart';
import 'package:shopspot/cubit/favorite_cubit/favorite_cubit.dart';
import 'package:shopspot/cubit/restaurant_cubit/restaurant_cubit.dart';
import 'package:shopspot/utils/color_scheme_extension.dart';

class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and favorite button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Distance info
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
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
}

class RestaurantCard extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantCard({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.restaurantDetails,
            arguments: {
              'restaurant': widget.restaurant,
            },
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant image
            SizedBox(
              height: 180,
              width: double.infinity,
              child: _buildImage(),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name and favorite button - SEPARATE THIS PART
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.restaurant.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      FavoriteButton(restaurant: widget.restaurant),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Restaurant description
                  Text(
                    widget.restaurant.description,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Distance info
                  DistanceInfo(restaurant: widget.restaurant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              Icons.restaurant,
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

class FavoriteButton extends StatefulWidget {
  final Restaurant restaurant;

  const FavoriteButton({
    super.key,
    required this.restaurant,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bool isFavorite = widget.restaurant.isFavorite;

    return SizedBox(
      width: 40,
      height: 40,
      child: _isLoading
          ? Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.error),
                ),
              ),
            )
          : IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Theme.of(context).colorScheme.error : null,
              ),
              onPressed:
                  _isLoading ? null : () => _updateFavoriteStatus(isFavorite),
            ),
    );
  }

  Future<void> _updateFavoriteStatus(isFavorite) async {
    // Check connectivity status first
    final connectivityService = context.read<ConnectivityService>();

    if (!connectivityService.isOnline) {
      // Show toast message when offline
      Fluttertoast.showToast(
        msg: 'You are offline. Please check your connection.',
        backgroundColor: Theme.of(context).colorScheme.error,
        textColor: Theme.of(context).colorScheme.onError,
      );
      return;
    }

    // Also check if server is unavailable for favorites
    if (connectivityService.isServerUnavailable) {
      // Show toast message when server is unavailable
      Fluttertoast.showToast(
        msg: 'Unable to connect to the server. Please try again later.',
        backgroundColor: Theme.of(context).colorScheme.warning,
        textColor: Theme.of(context).colorScheme.onWarning,
      );
      return;
    }

    // Set loading state to show spinner
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the favorite cubit
      final favoriteCubit = context.read<FavoriteCubit>();

      // Get the restaurant cubit to update directly
      final restaurantCubit = context.read<RestaurantCubit>();

      // Call the appropriate method directly based on current state with a timeout
      bool success = false;
      try {
        // Run the actual operation
        success =
            await favoriteCubit.toggleFavorite(widget.restaurant, context);
      } catch (e) {
        success = false;
      }

      // Force an explicit update of the restaurant cubit only if successful
      if (success) {
        // Update the restaurant cubit with the new status
        restaurantCubit.updateFavoriteStatus(
            widget.restaurant.id, !isFavorite // Toggle current state
            );
      } else if (mounted) {
        // Show toast message that there was a problem connecting to the server
        Fluttertoast.showToast(
          msg: 'Unable to connect to the server. Please try again later.',
          backgroundColor: Theme.of(context).colorScheme.warning,
          textColor: Theme.of(context).colorScheme.onWarning,
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        Fluttertoast.showToast(
          msg: 'Something went wrong. Please try again.',
          backgroundColor: Theme.of(context).colorScheme.warning,
          textColor: Theme.of(context).colorScheme.onWarning,
        );
      }
    } finally {
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class DistanceInfo extends StatelessWidget {
  final Restaurant restaurant;

  const DistanceInfo({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        final locationCubit = context.read<LocationCubit>();
        final distance = locationCubit.getDistanceSync(restaurant);
        if (state is LocationLoading) {
          return Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Calculating distance...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                ),
              ),
            ],
          );
        } else if (distance != null) {
          return Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: Colors.blue,
              ),
              const SizedBox(width: 4),
              Text(
                locationCubit.formatDistance(distance),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        } else {
          return const Text(
            'Distance not available',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          );
        }
      },
    );
  }
}
