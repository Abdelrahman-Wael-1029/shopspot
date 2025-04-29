import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_provider.dart';
import '../providers/restaurant_provider.dart';
import '../models/product.dart';
import '../models/restaurant.dart';
import 'product_details_screen.dart';
import 'restaurant_map_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty && !_isSearching) {
      setState(() {
        _isSearching = true;
      });
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (query == _searchController.text.trim()) {
          Provider.of<ProductProvider>(context, listen: false).searchProducts(query);
        }
        setState(() {
          _isSearching = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        Provider.of<ProductProvider>(context, listen: false)
                          .searchProducts('');
                      },
                    )
                  : null,
              ),
            ),
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (ctx, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (productProvider.error != null) {
                  return Center(
                    child: Text(
                      'An error occurred: ${productProvider.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                
                if (_searchController.text.isEmpty) {
                  return const Center(child: Text('Enter product name to search'));
                }
                
                if (productProvider.searchResults.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: productProvider.searchResults.length,
                  itemBuilder: (ctx, i) {
                    Product product = productProvider.searchResults[i];
                    return SearchResultItem(product: product);
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

class SearchResultItem extends StatelessWidget {
  final Product product;

  const SearchResultItem({Key? key, required this.product}) : super(key: key);

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
            future: Provider.of<RestaurantProvider>(context, listen: false)
                .getRestaurantsForProduct(product.id),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        subtitle: Text(
                          restaurant.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(
                                productId: product.id,
                                restaurantId: restaurant.id,
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
} 