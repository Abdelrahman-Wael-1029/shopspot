import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopspot/cubit/product_cubit/product_state.dart';
import 'package:shopspot/services/connectivity_service/connectivity_service.dart';
import 'package:shopspot/services/connectivity_service/connectivity_state.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/utils/color_scheme_extension.dart';
import 'package:shopspot/widgets/custom_search.dart';
import 'package:shopspot/widgets/product_search_card.dart';
import 'package:shopspot/cubit/product_cubit/product_cubit.dart';

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
    // Initialize cubits
    final productCubit = context.read<ProductCubit>();
    if (productCubit.state is ProductLoading) {
      return; // Prevent multiple loading states
    } else if (productCubit.state is ProductInitial ||
        productCubit.state is ProductError) {
      await productCubit.fetchData(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        actions: [
          // Network status indicator
          BlocBuilder<ConnectivityService, ConnectivityState>(
            builder: (context, state) {
              final connectivity = context.read<ConnectivityService>();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: connectivity.isOnline
                      ? Theme.of(context).colorScheme.success
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
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final products = productCubit.searchAllProducts(_searchQuery);

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
                    final product = products[index];
                    final relations =
                        DatabaseService.getRelationsByProductId(product.id);
                    final restaurants =
                        DatabaseService.getRestaurantsByRelations(relations);
                    return ProductSearchCard(
                      key: Key('product_${product.id}'),
                      product: product,
                      restaurants: restaurants,
                      relations: relations,
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
