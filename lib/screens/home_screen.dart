import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopspot/providers/restaurant_provider.dart';
import 'package:shopspot/screens/auth/profile_screen.dart';
import '../providers/index_provider.dart';
import 'restaurants_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
          
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IndexProvider>(
      builder: (context, indexProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: indexProvider.currentIndex,
            children: const [
              RestaurantsScreen(),
              SearchScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: indexProvider.currentIndex,
            onTap: (index) => indexProvider.changeIndex(index),
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Colors.grey,
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
      },
    );
  }
}
