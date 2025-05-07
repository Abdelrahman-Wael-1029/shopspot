import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shopspot/cubit/index_cubit/index_cubit.dart';
import 'package:shopspot/cubit/index_cubit/index_state.dart';
import 'package:shopspot/screens/restaurants_list_screen.dart';
import 'package:shopspot/screens/favorites_screen.dart';
import 'package:shopspot/screens/products_search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IndexCubit, IndexState>(
      builder: (context, state) {
        final indexCubit = context.read<IndexCubit>();
        return Scaffold(
          body: IndexedStack(
            index: indexCubit.currentIndex,
            children: [
              const RestaurantsListScreen(),
              const FavoritesScreen(),
              const ProductsSearchScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: indexCubit.currentIndex,
            onTap: (index) => indexCubit.setIndex(index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant),
                label: 'Restaurants',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
            ],
          ),
        );
      },
    );
  }
}
