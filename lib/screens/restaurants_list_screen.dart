import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/widgets/custom_search.dart';
import 'package:shopspot/providers/restaurant_provider.dart';
import 'package:shopspot/services/connectivity_service.dart';
import 'package:shopspot/widgets/restaurant_card.dart';

class RestaurantsListScreen extends StatefulWidget {
  const RestaurantsListScreen({super.key});

  @override
  State<RestaurantsListScreen> createState() => _RestaurantsListScreenState();
}

class _RestaurantsListScreenState extends State<RestaurantsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    // Initialize providers
    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);

    // If restaurants are already being loaded from splash screen, don't duplicate the effort
    if (!restaurantProvider.hasBeenInitialized) {
      // Initialize with context to use connectivity awareness
      await restaurantProvider.initialize(context);

      // Check if still mounted before accessing context
      if (!mounted) return;

      // Mark data as refreshed
      connectivityService.markRefreshed();
    }
  }

  Future<void> _refreshData() async {
    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);

    // Explicitly set loading state to true before refreshing
    restaurantProvider.setLoading(true);

    // Always use server data when explicitly refreshing
    bool success = false;

    // Only try to refresh from server if we're online
    if (connectivityService.isOnline) {
      success = await restaurantProvider.refreshRestaurants(context);

      // Mark that we've refreshed the data
      if (success) {
        connectivityService.markRefreshed();
      }
    } else {
      // Set loading to false when offline - don't show skeletons
      restaurantProvider.setLoading(false);

      // Check if still mounted before accessing context
      if (!mounted) return;

      // Show toast or alert that we're offline
      Fluttertoast.showToast(
        msg: 'You are offline. Please check your connection.',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        automaticallyImplyLeading: false,
        actions: [
          // Network status indicator
          Consumer<ConnectivityService>(
            builder: (context, connectivity, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: connectivity.isOnline ? Colors.green : Colors.red,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.profile,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner
          Consumer<ConnectivityService>(
            builder: (context, connectivity, child) {
              if (!connectivity.isOnline) {
                return Container(
                  color: Colors.orange.shade100,
                  padding: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800),
                      const SizedBox(width: 8.0),
                      const Expanded(
                        child: Text(
                          'You are offline. Showing cached data.',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          CustomSearch(
            searchController: _searchController,
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            hintText: 'Search restaurants...',
          ),
          Expanded(
            child: Consumer<RestaurantProvider>(
              builder: (context, restaurantProvider, child) {
                if (restaurantProvider.isLoading) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: 5,
                    itemBuilder: (_, index) => Column(
                      children: [
                        RestaurantCardSkeleton(key: Key('skeleton_$index')),
                      ],
                    ),
                  );
                }

                if (restaurantProvider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            restaurantProvider.error!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final restaurants =
                    restaurantProvider.searchRestaurants(_searchQuery);

                if (restaurants.isEmpty) {
                  return Center(
                    child: _searchQuery.isNotEmpty
                        ? const Text('No restaurants match your search')
                        : const Text('No restaurants available'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: restaurants.length,
                    itemBuilder: (_, index) {
                      final restaurant = restaurants[index];
                      return RestaurantCard(
                        key: ValueKey(
                            'restaurant_${restaurant.id}_${restaurant.isFavorite}'),
                        restaurant: restaurant,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
