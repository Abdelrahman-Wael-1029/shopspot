import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shopspot/providers/connectivity_provider.dart';
import 'package:shopspot/utils/app_colors.dart';
import 'package:shopspot/widgets/card_skeleton.dart';
import 'package:shopspot/widgets/custom_search.dart';
import '../providers/restaurant_provider.dart';
import '../models/restaurant.dart';
import 'products_screen.dart';

class RestaurantsScreen extends StatelessWidget {
  static const routeName = '/restaurants';

  RestaurantsScreen({super.key});

  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          // Consumer on connectivity provider for show status connection
          Consumer<ConnectivityProvider>(
            builder: (ctx, connectivityProvider, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  connectivityProvider.isOnline
                      ? (Icons.wifi)
                      : (Icons.wifi_off),
                  color: connectivityProvider.isOnline
                      ? AppColors.accent
                      : AppColors.error,
                ),
              );
            },
          )
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<RestaurantProvider>().fetchRestaurants(context);
        },
        child: SingleChildScrollView(
          child: Consumer<RestaurantProvider>(
            builder: (ctx, restaurantProvider, child) {
              if (restaurantProvider.isLoading) {
                return ResponsiveCardGrid(
                  itemCount: 7,
                  itemBuilder: (_, __) => const CardSkeleton(),
                );
              }

              return Column(
                children: [
                  CustomSearch(
                    hintText: 'Search restaurants...',
                    onPressed: () {
                      searchController.clear();
                      restaurantProvider.clearSearch();
                    },
                    onChanged: (value) {
                      restaurantProvider.search(value);
                    },
                    searchController: searchController,
                  ),
                  (restaurantProvider.restaurants.isEmpty)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No restaurants found.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        )
                      : ResponsiveCardGrid(
                          itemCount: restaurantProvider.restaurants.length,
                          itemBuilder: (ctx, index) {
                            Restaurant restaurant =
                                restaurantProvider.restaurants[index];
                            return RestaurantCard(restaurant: restaurant);
                          },
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ResponsiveCardGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const ResponsiveCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine number of columns based on screen width
        int crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: _getAspectRatio(crossAxisCount),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    // Mobile: < 600, Tablet: 600-900, Desktop: > 900
    if (width < 600) {
      return 1; // Mobile - 1 card per row
    } else if (width < 900) {
      return 2; // Tablet - 2 cards per row
    } else {
      return 3; // Desktop - 3 cards per row
    }
  }

  // Adjust aspect ratio based on grid layout
  double _getAspectRatio(int crossAxisCount) {
    switch (crossAxisCount) {
      case 1:
        return 1.3; // More vertical space for mobile
      case 2:
        return 1.4; // Balanced for tablet
      case 3:
        return 1.0; // More square-like for desktop
      default:
        return 1;
    }
  }
}

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 3,
      color: isDark ? AppColors.overlay : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductsScreen(
                restaurant: restaurant,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RestaurantImage(imageUrl: restaurant.imageUrl),
            Expanded(
              child: RestaurantDetails(restaurant: restaurant),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantImage extends StatelessWidget {
  final String? imageUrl;

  const RestaurantImage({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        height: 120,
        decoration: const BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: const Center(
          child: Icon(Icons.restaurant, size: 40),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 120,
          color: AppColors.lightGrey,
          child: const Icon(Icons.restaurant, size: 40),
        ),
      ),
    );
  }
}

class RestaurantDetails extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetails({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurant.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              restaurant.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        isDark ? AppColors.lightGrey : AppColors.textSecondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: isDark ? AppColors.lightGrey : AppColors.darkGrey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  restaurant.location,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            isDark ? AppColors.lightGrey : AppColors.darkGrey,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
