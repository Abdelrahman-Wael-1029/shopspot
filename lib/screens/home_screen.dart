import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/providers/product_provider.dart';
import 'package:shopspot/providers/restaurant_provider.dart';
import 'package:shopspot/screens/auth/profile_screen.dart';
import '../providers/index_bloc.dart';
import 'restaurants_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    
    Future.microtask(() =>
        Provider.of<RestaurantProvider>(context, listen: false)
            .fetchRestaurants());
    
    Future.microtask(() =>
        Provider.of<ProductProvider>(context, listen: false)
            .fetchProducts());
          
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(builder: (_, state) {
      final indexProvider = Provider.of<IndexBloc>(context);
      return Scaffold(
          body: IndexedStack(
            index: indexProvider.state,
            children: [
              RestaurantsScreen(),
              const SearchScreen(),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: indexProvider.state,
            onTap: (index) => indexProvider.changeIndex(index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant),
                label: 'Restaurants',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
    });



    
  }
}
