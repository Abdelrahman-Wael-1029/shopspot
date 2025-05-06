import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopspot/cubit/restaurant_cubit/restaurant_state.dart';
import 'package:shopspot/services/connectivity_service/connectivity_state.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/utils/utils.dart';
import 'package:shopspot/widgets/custom_search.dart';
import 'package:shopspot/cubit/restaurant_cubit/restaurant_cubit.dart';
import 'package:shopspot/services/connectivity_service/connectivity_service.dart';
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
    // Initialize cubits
    final restaurantCubit = context.read<RestaurantCubit>();
    final connectivityService = context.read<ConnectivityService>();

    // If restaurants are already being loaded from splash screen, don't duplicate the effort
    if (!restaurantCubit.hasBeenInitialized) {
      // Initialize with context to use connectivity awareness
      await restaurantCubit.initialize(context);

      // Check if still mounted before accessing context
      if (!mounted) return;

      // Mark data as refreshed
      connectivityService.markRefreshed();
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
          BlocBuilder<ConnectivityService, ConnectivityState>(
            builder: (context, isConnected) {
              final connectivity = context.read<ConnectivityService>();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: connectivity.isOnline ?getSuccessColor(context)
                      : Theme.of(context).colorScheme.error,
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
          BlocBuilder<ConnectivityService, ConnectivityState>(
            builder: (context, isConnected) {
              final connectivity = context.read<ConnectivityService>();
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
            child: BlocBuilder<RestaurantCubit, RestaurantState>(
              builder: (context, state) {
                final restaurantCubit = context.read<RestaurantCubit>();
                if (state is RestaurantLoading) {
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

                if (state is RestaurantError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                restaurantCubit.refreshData(context),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final restaurants =
                    restaurantCubit.searchRestaurants(_searchQuery);

                if (restaurants.isEmpty) {
                  return Center(
                    child: _searchQuery.isNotEmpty
                        ? const Text('No restaurants match your search')
                        : const Text('No restaurants available'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => restaurantCubit.refreshData(context),
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
