import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopspot/providers/location_bloc.dart';
import 'package:shopspot/providers/location_state.dart';
import 'package:shopspot/utils/app_colors.dart';
import '../models/product.dart';
import '../models/restaurant.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Restaurant? restaurant;
  final Product product;

  const ProductDetailsScreen({
    super.key,
    this.restaurant,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: BlocBuilder<LocationBloc, LocationState>(
            builder: (context, state) {
              if (state is LocationLoading) {
                return const LinearProgressIndicator();
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          final hasLocation = state is LocationSuccess;
          final hasPermission = state is LocationSuccess || state is LocationPermissionDenied;

          final position = state is LocationSuccess ? state.position : null;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: AppColors.lightGrey,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: AppColors.lightGrey,
                    child: const Icon(
                      Icons.fastfood,
                      size: 60,
                      color: AppColors.grey,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),

                if (restaurant != null) ...[
                  const Divider(thickness: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Restaurant Information',
                          style: theme.textTheme.headlineLarge?.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.restaurant, color: AppColors.primary),
                          title: Text(restaurant!.name, style: theme.textTheme.bodyLarge),
                          subtitle: Text(restaurant!.location, style: theme.textTheme.bodyMedium),
                        ),
                        if (hasLocation)
                          ListTile(
                            leading: const Icon(Icons.location_on, color: AppColors.secondary),
                            title: Text(
                              'Distance: ${context.read<LocationBloc>().calculateDistance(position, restaurant!.latitude, restaurant!.longitude).toStringAsFixed(2)} km',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.directions),
                            label: const Text('Get Directions'),
                            onPressed: () {
                              context.read<LocationBloc>().openGoogleMapWithDestination(
                                    restaurant!.latitude,
                                    restaurant!.longitude,
                                  );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (!hasLocation || !hasPermission) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.location_on),
                              label: const Text('Refresh Location'),
                              onPressed: () {
                                context.read<LocationBloc>().refreshLocation();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                  restaurant!.latitude,
                                  restaurant!.longitude,
                                ),
                                initialZoom: 15,
                                interactionOptions: const InteractionOptions(
                                  enableScrollWheel: false,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.shopspot',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(restaurant!.latitude, restaurant!.longitude),
                                      width: 40,
                                      height: 40,
                                      child: GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(restaurant!.name, style: theme.textTheme.headlineLarge?.copyWith(fontSize: 18)),
                                              content: Text(restaurant!.location, style: theme.textTheme.bodyMedium),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Close', style: TextStyle(color: AppColors.primary)),
                                                ),
                                              ],
                                              backgroundColor: AppColors.card,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Icon(Icons.location_on, color: AppColors.error, size: 30),
                                      ),
                                    ),
                                  ],
                                ),
                                if (hasLocation)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(position!.latitude, position.longitude),
                                        width: 40,
                                        height: 40,
                                        child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (state is LocationFailure || state is LocationPermissionDenied)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      (state is LocationFailure) ? state.error : (state as LocationPermissionDenied).message,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}