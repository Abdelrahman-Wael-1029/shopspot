import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shopspot/providers/connectivity_provider.dart';
import 'package:shopspot/utils/app_colors.dart';
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
          // consumer on connectivity provider for show status connection
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
          await context.read<RestaurantProvider>().fetchRestaurants();
        },
        child: SingleChildScrollView(
          child: Consumer<RestaurantProvider>(
            builder: (ctx, restaurantProvider, child) {
              if (restaurantProvider.isLoading) {
                return _buildShimmerEffect(context);
              }

              if (restaurantProvider.error != null) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'An error occurred: ${restaurantProvider.error}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
                          child: Text(
                            'No restaurants found.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: restaurantProvider.restaurants.length,
                          itemBuilder: (ctx, i) {
                            Restaurant restaurant =
                                restaurantProvider.restaurants[i];
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

  Widget _buildShimmerEffect(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final containerColor = isDark ? Colors.grey[850]! : Colors.white;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (ctx, i) {
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة وهمية للمطعم
                  Container(
                    width: double.infinity,
                    height: 160,
                    color: containerColor,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: containerColor,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 150,
                    height: 14,
                    color: containerColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 14,
                    color: containerColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 14,
                    color: containerColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
      margin: const EdgeInsets.only(bottom: 16),
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
            if (restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: restaurant.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    highlightColor:
                        isDark ? Colors.grey[700]! : Colors.grey[100]!,
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 160,
                    color: AppColors.lightGrey,
                    child: const Icon(Icons.restaurant, size: 40),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppColors.white : AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.lightGrey
                              : AppColors.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isDark ? AppColors.lightGrey : AppColors.darkGrey,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
