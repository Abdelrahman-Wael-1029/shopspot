import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopspot/utils/app_colors.dart';
import 'package:shopspot/widgets/custom_search.dart';
import '../providers/product_provider.dart';
import '../providers/restaurant_provider.dart';
import '../models/product.dart';
import '../models/restaurant.dart';
import 'product_details_screen.dart';
import 'restaurant_map_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Clear the restaurant cache when refreshing
          await context.read<ProductProvider>().fetchProducts(context);
        },
        child: SingleChildScrollView(
          child: Consumer<ProductProvider>(
            builder: (ctx, productProvider, child) {
              if (productProvider.isLoading) {
                return LinearProgressIndicator(
                  backgroundColor: AppColors.primary,
                  color: AppColors.secondary,
                );
              }

              return Column(
                children: [
                  CustomSearch(
                    hintText: 'Search products...',
                    onChanged: (value) {
                      Provider.of<ProductProvider>(context, listen: false)
                          .searchProducts(value);
                    },
                    onPressed: () {
                      _searchController.clear();
                      Provider.of<ProductProvider>(context, listen: false)
                          .searchProducts('');
                    },
                    searchController: _searchController,
                  ),
                  (productProvider.searchResults.isEmpty)
                      ? const Center(child: Text('No products found.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: productProvider.searchResults.length,
                          itemBuilder: (ctx, i) {
                            Product product = productProvider.searchResults[i];
                            return SearchResultItem(
                              product: product,
                            );
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

class SearchResultItem extends StatelessWidget {
  final Product product;

  const SearchResultItem({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: product.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 60,
              height: 60,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              width: 60,
              height: 60,
              color: Colors.grey[300],
              child: const Icon(Icons.fastfood, size: 30),
            ),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          product.description.length > 50
              ? '${product.description.substring(0, 50)}...'
              : product.description,
          style: const TextStyle(fontSize: 14),
        ),
        children: [
          FutureBuilder<List<Restaurant>>(
            future: _getRestaurantsForProduct(context, product.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load restaurants: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No restaurants found for this product'),
                );
              }

              List<Restaurant> restaurants = snapshot.data!;

              return Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Available at ${restaurants.length} ${restaurants.length == 1 ? 'restaurant' : 'restaurants'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.map),
                          label: const Text('Show on Map'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => RestaurantMapScreen(
                                  restaurants: restaurants,
                                  productName: product.name,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: restaurants.length,
                    itemBuilder: (ctx, i) {
                      Restaurant restaurant = restaurants[i];
                      return ListTile(
                        leading: const Icon(Icons.restaurant),
                        title: Text(restaurant.name),
                        subtitle: Text(restaurant.location,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(
                                product: product,
                                restaurant: restaurant,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper method to get restaurants using the provider's cache
  Future<List<Restaurant>> _getRestaurantsForProduct(
      BuildContext context, int productId) async {
    // Use the provider's caching mechanism
    return Provider.of<RestaurantProvider>(context, listen: false)
        .getRestaurantsForProduct(context, productId);
  }
}
