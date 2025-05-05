import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/services/connectivity_service.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/widgets/custom_search.dart';
import 'package:shopspot/widgets/product_search_card.dart';
import 'package:shopspot/providers/product_provider.dart';
import 'package:shopspot/models/product_model.dart';

class ProductsSearchScreen extends StatefulWidget {
  const ProductsSearchScreen({super.key});

  @override
  State<ProductsSearchScreen> createState() => _ProductsSearchScreenState();
}

class _ProductsSearchScreenState extends State<ProductsSearchScreen> {
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
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Initialize providers
    Provider.of<ProductProvider>(context, listen: false).fetchData(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
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
            hintText: 'Search products...',
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (ctx, productProvider, child) {
                if (productProvider.isLoading) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 10,
                    itemBuilder: (_, index) {
                      return ProductSearchCardSkeleton(
                        key: ValueKey('skeleton_$index'),
                      );
                    },
                  );
                }

                if (productProvider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            productProvider.error!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final products =
                    productProvider.searchAllProducts(_searchQuery);

                if (products.isEmpty) {
                  return Center(
                    child: _searchQuery.isNotEmpty
                        ? const Text('No products match your search')
                        : const Text('No products available'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (_, index) {
                    Product product = products[index];
                    return ProductSearchCard(
                      key: Key('product_${product.id}'),
                      product: product,
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
