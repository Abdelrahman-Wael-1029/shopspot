import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopspot/cubit/product_cubit/product_state.dart';
import 'package:shopspot/models/product_model.dart';
import 'package:shopspot/models/restaurant_model.dart';
import 'package:shopspot/models/restaurant_product_model.dart';
import 'package:shopspot/cubit/product_cubit/product_cubit.dart';
import 'package:shopspot/services/connectivity_service/connectivity_service.dart';
import 'package:shopspot/services/connectivity_service/connectivity_state.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/widgets/custom_search.dart';
import 'package:shopspot/widgets/product_card.dart';

class ProductsListScreen extends StatefulWidget {
  final Restaurant restaurant;

  const ProductsListScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Product> _products = [];
  List<RestaurantProduct> _restaurantProducts = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Use post-frame callback to avoid changing state during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    final productCubit = context.read<ProductCubit>();
    final products =
        await productCubit.fetchData(context, widget.restaurant.id);

    if (mounted) {
      setState(() {
        _products = products;
        _restaurantProducts =
            DatabaseService.getRelationsByRestaurantId(widget.restaurant.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.restaurant.name} Products'),
        actions: [
          // Network status indicator
          BlocBuilder<ConnectivityService, ConnectivityState>(
            builder: (context, state) {
              final connectivity = context.read<ConnectivityService>();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: connectivity.isOnline ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner
          BlocBuilder<ConnectivityService, ConnectivityState>(
            builder: (context, state) {
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
            hintText: 'Search products...',
          ),
          Expanded(
            child: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                final productCubit = context.read<ProductCubit>();
                if (state is ProductLoading) {
                  return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return ProductCardSkeleton(
                          key: ValueKey('skeleton_$index'),
                        );
                      });
                }

                if (state is ProductError) {
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
                            onPressed: _loadProducts,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final products =
                    productCubit.filterProducts(_products, _searchQuery);

                if (products.isEmpty) {
                  return Center(
                    child: _searchQuery.isNotEmpty
                        ? const Text('No products match your search')
                        : const Text('No products available'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        key: ValueKey('product_${product.id}'),
                        product: product,
                        restaurant: widget.restaurant,
                        restaurantProducts: _restaurantProducts,
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
