import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/providers/index_provider.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/widgets/custom_search.dart';
import 'package:shopspot/widgets/restaurant_card.dart';
import 'package:shopspot/models/restaurant_model.dart';
import 'package:shopspot/providers/favorite_provider.dart';
import 'package:shopspot/services/connectivity_service.dart';
import 'package:shopspot/providers/restaurant_provider.dart';

// Custom widget to handle loading state during dismissal
class DismissibleRestaurantCard extends StatefulWidget {
  final Restaurant restaurant;
  final Function(bool) onDismissStatusChanged;
  final Function() isDismissing;

  const DismissibleRestaurantCard({
    super.key,
    required this.restaurant,
    required this.onDismissStatusChanged,
    required this.isDismissing,
  });

  @override
  State<DismissibleRestaurantCard> createState() =>
      _DismissibleRestaurantCardState();
}

class _DismissibleRestaurantCardState extends State<DismissibleRestaurantCard> {
  bool _isLoading = false;
  Key _dismissibleKey = UniqueKey();

  // Set loading state and notify parent
  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
    // Pass the loading state to parent
    widget.onDismissStatusChanged(value);
  }

  // Reset the dismissible widget with a new key
  void _resetDismissible() {
    setState(() {
      _dismissibleKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);

    return Stack(
      children: [
        // The actual dismissible restaurant card
        Dismissible(
          key: _dismissibleKey,
          direction:
              _isLoading ? DismissDirection.none : DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          confirmDismiss: _isLoading || widget.isDismissing()
              ? (_) async => false
              : (direction) async {
                  if (!connectivityService.isOnline) {
                    // Show toast message when offline
                    Fluttertoast.showToast(
                      msg: 'You are offline. Please check your connection.',
                      backgroundColor: Colors.red,
                    );
                    return false;
                  }

                  // Also check if server is unavailable for favorites
                  if (connectivityService.isServerUnavailable) {
                    Fluttertoast.showToast(
                      msg:
                          'Unable to connect to the server. Please try again later.',
                      backgroundColor: Colors.orange,
                    );
                    return false;
                  }

                  // If online, proceed with confirmation dialog
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Remove from Favorites?'),
                        content: Text(
                          'Are you sure you want to remove ${widget.restaurant.name} from your favorites?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text('REMOVE'),
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldDelete == true) {
                    // Show loading indicator while processing the delete
                    _setLoading(true);
                  } else {
                    // If user cancelled, reset the dismissible widget
                    _resetDismissible();
                  }

                  return shouldDelete;
                },
          onDismissed: (direction) async {
            // Get providers before async operations
            final favoriteProvider =
                Provider.of<FavoriteProvider>(context, listen: false);
            final restaurantProvider =
                Provider.of<RestaurantProvider>(context, listen: false);

            try {
              // Remove from favorites - this updates the UI before the API call completes
              final success = await favoriteProvider.removeFromFavorites(
                  widget.restaurant, context);

              // Check if still mounted after async operation
              if (!mounted) return;

              // Only proceed if the removal was successful
              if (success) {
                // Also update the RestaurantProvider to maintain UI consistency
                restaurantProvider.updateFavoriteStatus(
                    widget.restaurant.id, false);

                Fluttertoast.showToast(
                  msg: '${widget.restaurant.name} removed from favorites.',
                  backgroundColor: Colors.green,
                );
              } else {
                // If removal was not successful, show an error message
                Fluttertoast.showToast(
                  msg:
                      'Unable to connect to the server. Please try again later.',
                  backgroundColor: Colors.orange,
                );

                // Reset the widget to prevent red screen errors
                _resetDismissible();
              }
            } catch (e) {
              Fluttertoast.showToast(
                msg: 'Something went wrong. Please try again.',
                backgroundColor: Colors.orange,
              );

              // Reset the widget to prevent red screen errors
              _resetDismissible();
            } finally {
              _setLoading(false);
            }
          },
          child: RestaurantCard(
            key: ValueKey('restaurant_${widget.restaurant.id}'),
            restaurant: widget.restaurant,
          ),
        ),

        // Loading overlay
        if (_isLoading)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              color: Color.fromARGB(26, 0, 0, 0),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isDismissing = false;
  bool isDismissing() => _isDismissing;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load favorites when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  // Track the dismiss state of a particular card
  void _onDismissStatusChanged(int restaurantId, bool isLoading) {
    setState(() {
      _isDismissing = isLoading;
    });
  }

  Future<void> _loadFavorites() async {
    // Capture providers before any async operations
    final favoriteProvider =
        Provider.of<FavoriteProvider>(context, listen: false);
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);

    // Only initialize if not already initialized
    if (!favoriteProvider.hasBeenInitialized) {
      // Initialize with context to use connectivity awareness
      await favoriteProvider.initialize(context);

      // Early return if widget is unmounted
      if (!mounted) return;

      // Mark data as refreshed
      connectivityService.markRefreshed();
    }
  }

  // Custom method to build the empty state UI for favorites
  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.favorite_border,
          size: 64,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        const Text(
          'No favorite restaurants yet',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add restaurants to your favorites to see them here',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () =>
              Provider.of<IndexProvider>(context, listen: false).changeIndex(0),
          child: const Text('Browse Restaurants'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
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
            child: Consumer2<RestaurantProvider, FavoriteProvider>(
              builder: (context, restaurantProvider, favoriteProvider, child) {
                if (favoriteProvider.isLoading ||
                    restaurantProvider.isLoading) {
                  // Create a more explicit loading skeleton to ensure it's visible
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          RestaurantCardSkeleton(key: Key('skeleton_$index')),
                        ],
                      );
                    },
                  );
                }

                final favorites =
                    favoriteProvider.searchFavorites(_searchQuery);

                if (favorites.isEmpty) {
                  return Center(
                    child: _searchQuery.isNotEmpty
                        ? const Text('No restaurants match your search')
                        : _buildEmptyState(),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: favorites.length,
                  itemBuilder: (_, index) {
                    final restaurant = favorites[index];
                    return DismissibleRestaurantCard(
                      key: ValueKey('dismissible_${restaurant.id}'),
                      restaurant: restaurant,
                      onDismissStatusChanged: (isLoading) =>
                          _onDismissStatusChanged(restaurant.id, isLoading),
                      isDismissing: isDismissing,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
