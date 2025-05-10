import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shopspot/cubit/restaurant_cubit/restaurant_cubit.dart';
import 'package:shopspot/cubit/restaurant_cubit/restaurant_state.dart';
import 'package:shopspot/models/restaurant_model.dart';
import 'package:shopspot/models/restaurant_product_model.dart';
import 'package:shopspot/models/product_model.dart';
import 'package:shopspot/services/database_service.dart';
import 'package:shopspot/utils/app_routes.dart';
import 'package:shopspot/utils/color_scheme_extension.dart';

class ProductSearchCardSkeleton extends StatelessWidget {
  const ProductSearchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 24, top: 13, bottom: 13),
          child: Row(
            children: [
              // Image placeholder
              Container(
                width: 80,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title placeholder
                    Container(
                      height: 16,
                      width: MediaQuery.of(context).size.width * 0.48,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle placeholder
                    Container(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.45,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.35,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),

              // Expansion icon placeholder
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductSearchCard extends StatefulWidget {
  final Product product;

  const ProductSearchCard({
    super.key,
    required this.product,
  });

  @override
  State<ProductSearchCard> createState() => _ProductSearchCardState();
}

class _ProductSearchCardState extends State<ProductSearchCard> {
  List<Restaurant> restaurants = [];
  List<RestaurantProduct> relations = [];

  void _loadRelations() {
    if (restaurants.isNotEmpty) return;
    relations = DatabaseService.getRelationsByProductId(widget.product.id);
    restaurants = DatabaseService.getRestaurantsByRelations(relations);
    _sortRestaurantsByStatus();
  }

  void _sortRestaurantsByStatus() {
    if (restaurants.isEmpty) return;

    restaurants.sort((a, b) {
      // Find restaurant products for these restaurants
      final aRelation = relations.firstWhere(
        (relation) => relation.restaurantId == a.id,
        orElse: () => RestaurantProduct(
          restaurantId: a.id,
          productId: widget.product.id,
          price: 0,
          status: 'unknown',
          rating: 0,
        ),
      );

      final bRelation = relations.firstWhere(
        (relation) => relation.restaurantId == b.id,
        orElse: () => RestaurantProduct(
          restaurantId: b.id,
          productId: widget.product.id,
          price: 0,
          status: 'unknown',
          rating: 0,
        ),
      );

      // Sort by status priority (available > coming soon > out of stock)
      final aValue = _getStatusValue(aRelation.status);
      final bValue = _getStatusValue(bRelation.status);
      if (aValue != bValue) {
        return aValue.compareTo(bValue);
      }

      // If status is the same, sort by rating (higher first)
      return bRelation.rating.compareTo(aRelation.rating);
    });
  }

  int _getStatusValue(String status) {
    switch (status.toLowerCase().replaceAll('_', ' ')) {
      case 'available':
        return 0;
      case 'coming soon':
        return 1;
      case 'out of stock':
        return 2;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
        ),
        collapsedShape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImage(widget.product.imageUrl, 80, 56, Icons.fastfood),
        ),
        title: Text(
          widget.product.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          widget.product.description,
          style: const TextStyle(
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          _buildRestaurantList(),
        ],
      ),
    );
  }

  Widget _buildRestaurantList() {
    return BlocBuilder<RestaurantCubit, RestaurantState>(
      builder: (context, state) {
        if (state is RestaurantLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        _loadRelations();
        if (restaurants.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No restaurants found for this product'),
          );
        }
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
                      Navigator.pushNamed(
                        context,
                        AppRoutes.restaurantsMap,
                        arguments: {
                          'restaurants': restaurants,
                          'productName': widget.product.name,
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: restaurants.length,
                itemBuilder: (_, index) {
                  final restaurant = restaurants[index];

                  // Find the relation for this restaurant-product pair
                  final relation = relations.firstWhere(
                    (r) => r.restaurantId == restaurant.id,
                    orElse: () => RestaurantProduct(
                      restaurantId: restaurant.id,
                      productId: widget.product.id,
                      price: 0,
                      status: 'Unknown',
                      rating: 0,
                    ),
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 1,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.restaurantDetails,
                            arguments: {
                              'restaurant': restaurant,
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Restaurant image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildImage(restaurant.imageUrl, 70, 70,
                                    Icons.restaurant),
                              ),
                              const SizedBox(width: 12),
                              // Restaurant details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            restaurant.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Price
                                        Text(
                                          '\$${relation.price}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Status badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(relation.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        relation.status.replaceAll('_', ' '),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Rating
                                    Row(
                                      children: [
                                        RatingBarIndicator(
                                          rating: relation.rating,
                                          itemBuilder: (context, _) =>
                                              const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ),
                                          itemCount: 5,
                                          itemSize: 16.0,
                                          direction: Axis.horizontal,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          relation.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().replaceAll('_', ' ')) {
      case 'available':
        return Theme.of(context).colorScheme.success;
      case 'coming soon':
        return Theme.of(context).colorScheme.warning;
      case 'out of stock':
        return Theme.of(context).colorScheme.error;
      default:
        return Colors.grey;
    }
  }

  Widget _buildImage(
      String imageUrl, double width, double height, IconData errorIcon) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Icon(
          errorIcon,
          size: 24,
          color: Colors.grey,
        ),
      ),
    );
  }
}
