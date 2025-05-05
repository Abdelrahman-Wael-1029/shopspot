import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/providers/index_provider.dart';
import 'package:shopspot/screens/restaurants_list_screen.dart';
import 'package:shopspot/screens/favorites_screen.dart';
import 'package:shopspot/screens/products_search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IndexProvider>(
      builder: (context, indexProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: indexProvider.currentIndex,
            children: [
              const RestaurantsListScreen(),
              const FavoritesScreen(),
              const ProductsSearchScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: indexProvider.currentIndex,
            onTap: (index) => indexProvider.changeIndex(index),
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
