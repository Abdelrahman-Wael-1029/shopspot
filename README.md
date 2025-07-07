# 📱 ShopSpot - Your Personal Shopping Companion

![Flutter](https://img.shields.io/badge/Flutter-3.5.4-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5.4-0175C2?style=flat&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

**ShopSpot** is a comprehensive Flutter application that serves as your personal shopping companion. Find nearby stores, explore detailed information, track distances using real-time location services, and curate your favorite shopping destinations all in one intuitive platform.

## 📋 Table of Contents

- [🎯 App Overview](#-app-overview)
- [🎥 Demo](#-demo)
- [✨ Flutter-Specific Features](#-flutter-specific-features)
  - [Core Functionality](#core-functionality)
  - [Platform-Specific Features](#platform-specific-features)
  - [State Management](#state-management)
- [🛠️ Tech Stack & Dependencies](#️-tech-stack--dependencies)
  - [Flutter SDK](#flutter-sdk)
  - [Core Dependencies](#core-dependencies)
  - [Development Dependencies](#development-dependencies)
- [🏗️ App Architecture](#️-app-architecture)
  - [Project Structure](#project-structure)
  - [State Management Pattern](#state-management-pattern)
  - [Database Architecture](#database-architecture)
- [📋 Prerequisites & Installation](#-prerequisites--installation)
  - [System Requirements](#system-requirements)
  - [Platform-Specific Setup](#platform-specific-setup)
- [🚀 Getting Started](#-getting-started)
- [⚙️ Configuration Setup](#️-configuration-setup)
  - [API Configuration](#api-configuration)
  - [Location Services](#location-services)
  - [Database Configuration](#database-configuration)
- [📱 App Screens & Navigation](#-app-screens--navigation)
  - [Main Navigation Flow](#main-navigation-flow)
  - [Navigation Implementation](#navigation-implementation)
- [🎛️ State Management](#️-state-management)
  - [BLoC/Cubit Architecture](#bloccubit-architecture)
  - [Global State Providers](#global-state-providers)
- [🌐 Backend Integration](#-backend-integration)
  - [API Service Architecture](#api-service-architecture)
  - [Data Synchronization](#data-synchronization)
  - [Authentication](#authentication)
- [🧪 Testing](#-testing)
  - [Test Configuration](#test-configuration)
  - [Running Tests](#running-tests)
- [🚀 Building & Deployment](#-building--deployment)
  - [Development Build](#development-build)
  - [Release Build](#release-build)
  - [Build Configuration](#build-configuration)
- [📊 App Features Summary](#-app-features-summary)
- [🔧 Development](#-development)
  - [Code Generation](#code-generation)
  - [Debugging](#debugging)
- [📄 License](#-license)

## 🎯 App Overview

ShopSpot solves the common problem of discovering and managing shopping locations by providing a centralized platform where users can:

- **Discover Nearby Restaurants/Stores**: Find establishments around your current location
- **Detailed Information Access**: View comprehensive details about each location including descriptions, images, and contact information
- **Distance Tracking**: Real-time distance calculation from your current position
- **Favorites Management**: Save and organize your preferred shopping destinations
- **Product Search**: Search through products across different establishments
- **Interactive Maps**: Visualize store locations on an interactive map interface
- **Offline Support**: Access cached data even when offline

**Target Audience**: Local shoppers, food enthusiasts, travelers exploring new areas, and anyone looking to discover and organize their favorite shopping spots.

## 🎥 Demo

![ShopSpot Demo]()

## ✨ Flutter-Specific Features

### Core Functionality
- **🗺️ Interactive Maps**: Flutter Map integration with real-time location tracking
- **📍 Location Services**: Precise GPS tracking with Geolocator
- **⭐ Favorites System**: Persistent favorite locations using Hive local database
- **🔍 Smart Search**: Product and restaurant search with real-time filtering
- **📱 Responsive UI**: Material Design 3 with custom theming
- **🌐 Network Awareness**: Automatic online/offline mode switching
- **💾 Offline Caching**: Full offline support with Hive database
- **🎨 Modern UI**: Custom themes with dynamic color schemes

### Platform-Specific Features
- **📷 Image Handling**: Camera and gallery integration with compression
- **🔗 Deep Linking**: URL launcher for external navigation
- **📍 Location Permissions**: Proper permission handling for both platforms
- **🎯 Navigation**: Custom routing system with nested navigation

### State Management
- **Flutter BLoC Pattern**: Complete state management using Cubit architecture
- **Reactive UI**: Real-time UI updates based on state changes
- **Global State**: Centralized state management across the entire app

## 🛠️ Tech Stack & Dependencies

### Flutter SDK
- **Flutter**: 3.5.4
- **Dart**: 3.5.4

### Core Dependencies
```yaml
# State Management
flutter_bloc: ^9.1.1              # BLoC pattern for state management

# Database & Storage
hive: ^2.2.3                      # NoSQL local database
hive_flutter: ^1.1.0              # Flutter integration for Hive
path_provider: ^2.1.5             # File system paths

# Networking & API
http: ^1.3.0                      # HTTP client for API calls
connectivity_plus: ^5.0.2         # Network connectivity monitoring

# Location & Maps
geolocator: ^11.0.0               # GPS location services
flutter_map: ^8.1.1              # Interactive map widget
latlong2: ^0.9.1                  # Latitude/longitude calculations

# UI & Media
cached_network_image: ^3.3.1      # Network image caching
image_picker: ^1.1.2              # Camera and gallery access
flutter_image_compress: ^2.4.0    # Image compression
shimmer: ^3.0.0                   # Loading skeleton animations
flutter_rating_bar: ^4.0.1        # Star rating widget

# Utilities
fluttertoast: ^8.2.12            # Toast notifications
url_launcher: ^6.3.1             # External URL handling
path: ^1.9.1                     # File path manipulation

# App Configuration
flutter_native_splash: ^2.4.6     # Native splash screen
flutter_launcher_icons: ^0.14.3   # App icon generation
```

### Development Dependencies
```yaml
# Testing & Linting
flutter_test: flutter SDK         # Widget and unit testing
flutter_lints: ^5.0.0            # Dart linting rules

# Code Generation
build_runner: ^2.4.15            # Code generation tool
hive_generator: ^2.0.1           # Hive model generation
```

## 🏗️ App Architecture

### Project Structure
```
lib/
├── main.dart                     # App entry point with BLoC providers
├── cubit/                        # State Management (BLoC/Cubit)
│   ├── auth_cubit/              # Authentication state
│   ├── favorite_cubit/          # Favorites management
│   ├── index_cubit/             # Bottom navigation state
│   ├── location_cubit/          # Location services state
│   ├── product_cubit/           # Product data management
│   └── restaurant_cubit/        # Restaurant data management
├── models/                       # Data Models
│   ├── product_model.dart       # Product entity model
│   ├── restaurant_model.dart    # Restaurant entity model
│   ├── restaurant_product_model.dart
│   └── user_model.dart          # User entity model
├── screens/                      # UI Screens
│   ├── home_screen.dart         # Main navigation hub
│   ├── login_screen.dart        # User authentication
│   ├── signup_screen.dart       # User registration
│   ├── restaurants_list_screen.dart    # Restaurant listings
│   ├── restaurant_details_screen.dart  # Detailed restaurant view
│   ├── restaurants_map_screen.dart     # Map visualization
│   ├── products_list_screen.dart       # Product listings
│   ├── product_details_screen.dart     # Detailed product view
│   ├── products_search_screen.dart     # Product search interface
│   ├── favorites_screen.dart           # User favorites
│   └── profile_screen.dart             # User profile management
├── services/                     # Business Logic Services
│   ├── api_service.dart         # REST API communication
│   ├── database_service.dart    # Local database operations
│   └── connectivity_service/    # Network status monitoring
├── utils/                        # Utilities & Configuration
│   ├── app_routes.dart          # Navigation routing
│   ├── app_theme.dart           # Material Design theming
│   ├── app_colors.dart          # Color constants
│   └── color_scheme_extension.dart
└── widgets/                      # Reusable UI Components
```

### State Management Pattern
The app uses **Flutter BLoC** (Cubit) pattern for state management:

```dart
// Example: Restaurant Cubit State Management
class RestaurantCubit extends Cubit<RestaurantState> {
  RestaurantCubit() : super(RestaurantInitial());

  Future<void> fetchData(BuildContext context) async {
    emit(RestaurantLoading());
    // Fetch from API or local cache
    // Emit success or error states
  }
}
```

### Database Architecture
- **Hive Database**: Fast, lightweight NoSQL database for local storage
- **Model Generation**: Automated TypeAdapter generation for seamless serialization
- **Offline-First**: App functions fully offline with cached data

## 📋 Prerequisites & Installation

### System Requirements
- **Flutter SDK**: 3.5.4 or higher
- **Dart SDK**: 3.5.4 or higher
- **Android Studio**: Latest version (for Android development)
- **Xcode**: Latest version (for iOS development, macOS only)

### Platform-Specific Setup

#### Android
- Minimum SDK: API 21 (Android 5.0)
- Location permissions configured in AndroidManifest.xml
- Internet permission for API access

#### iOS
- iOS 12.0 or higher
- Location usage descriptions in Info.plist
- Camera and photo library permissions

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/Abdelrahman-Wael-1029/shopspot.git
cd shopspot
```

### 2. Install Dependencies
```bash
# Get Flutter packages
flutter pub get

# Generate Hive adapters
flutter packages pub run build_runner build
```

### 3. Configure Environment
1. Update the API base URL in `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'YOUR_API_SERVER_URL';
   ```

2. Set up location permissions (already configured):
   - Android: Location permissions in `android/app/src/main/AndroidManifest.xml`
   - iOS: Location usage descriptions in iOS configuration

### 4. Run the Application
```bash
# Run on connected device/emulator
flutter run

# Run in debug mode
flutter run --debug

# Run in release mode
flutter run --release
```

## ⚙️ Configuration Setup

### API Configuration
Update the API service configuration in `lib/services/api_service.dart`:
```dart
class ApiService {
  static const String baseUrl = 'http://192.168.1.3:8000/api';
  // Update with your backend server URL
}
```

### Location Services
The app is pre-configured for location services:
- **Android**: `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` permissions
- **iOS**: Location when in use permission

### Database Configuration
Hive database is automatically initialized with registered adapters:
- User data storage
- Restaurant information caching
- Product data persistence
- Favorites management

## 📱 App Screens & Navigation

### Main Navigation Flow
1. **🏠 Home Screen**: Bottom navigation hub with three main sections
   - Restaurants List
   - Favorites
   - Product Search

2. **🍽️ Restaurant Screens**:
   - `RestaurantsListScreen`: Browse all available restaurants
   - `RestaurantDetailsScreen`: Detailed restaurant information
   - `RestaurantsMapScreen`: Interactive map view

3. **🛍️ Product Screens**:
   - `ProductsSearchScreen`: Search products across restaurants
   - `ProductsListScreen`: Browse products by restaurant
   - `ProductDetailsScreen`: Detailed product information

4. **👤 User Screens**:
   - `LoginScreen`: User authentication
   - `SignupScreen`: New user registration
   - `ProfileScreen`: User profile management
   - `FavoritesScreen`: Manage favorite restaurants

### Navigation Implementation
```dart
class AppRoutes {
  static const String home = '/home';
  static const String restaurants = '/restaurants';
  static const String products = '/products';
  // Custom route generator with type-safe navigation
}
```

## 🎛️ State Management

### BLoC/Cubit Architecture
Each feature has its dedicated Cubit for state management:

```dart
// Authentication state management
class AuthCubit extends Cubit<AuthState> {
  // Handle login, logout, registration
}

// Location services state
class LocationCubit extends Cubit<LocationState> {
  // Manage GPS, permissions, distance calculations
}

// Restaurant data state
class RestaurantCubit extends Cubit<RestaurantState> {
  // Fetch, cache, and manage restaurant data
}
```

### Global State Providers
All Cubits are provided globally through `MultiBlocProvider`:
```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => RestaurantCubit()),
    BlocProvider(create: (_) => AuthCubit()),
    BlocProvider(create: (_) => LocationCubit()),
    // ... other providers
  ],
  child: const MyApp(),
)
```

## 🌐 Backend Integration

**Backend Repository**: [ShopSpot Restaurant API](https://github.com/Abdelrahman-Wael-1029/restaurant_api.git)

### API Service Architecture
- **RESTful API**: HTTP-based communication with backend server
- **Error Handling**: Comprehensive error handling with user feedback
- **Offline Support**: Automatic fallback to cached data
- **Network Monitoring**: Real-time connectivity status

### Data Synchronization
- **Online Mode**: Real-time data fetching from server
- **Offline Mode**: Local Hive database operations
- **Smart Caching**: Intelligent cache invalidation and updates

### Authentication
- JWT-based authentication system
- Secure token storage in local database
- Automatic session management

## 🧪 Testing

### Test Configuration
Basic widget test setup is included:
```dart
// test/widget_test.dart
testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  // Test widget behavior
});
```

### Running Tests
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

## 🚀 Building & Deployment

### Development Build
```bash
# Debug build for testing
flutter build apk --debug
flutter build ios --debug
```

### Release Build
```bash
# Android release
flutter build apk --release
flutter build appbundle --release

# iOS release
flutter build ios --release
```

### Build Configuration
- **Android**: Configured in `android/app/build.gradle`
- **iOS**: Configured in `ios/Runner.xcodeproj`
- **Icons**: Generated using `flutter_launcher_icons`
- **Splash**: Native splash screen with `flutter_native_splash`

## 📊 App Features Summary

| Feature | Implementation | Status |
|---------|---------------|--------|
| 🗺️ Interactive Maps | Flutter Map + OpenStreetMap | ✅ |
| 📍 Location Services | Geolocator package | ✅ |
| 💾 Offline Storage | Hive NoSQL database | ✅ |
| 🔍 Search Functionality | Real-time product search | ✅ |
| ⭐ Favorites System | Local persistence | ✅ |
| 🎨 Modern UI | Material Design 3 | ✅ |
| 🌐 API Integration | REST API with error handling | ✅ |
| 📱 Cross-Platform | Android & iOS support | ✅ |
| 🔐 Authentication | JWT-based auth system | ✅ |
| 📷 Image Handling | Camera + Gallery integration | ✅ |

## 🔧 Development

### Code Generation
```bash
# Generate Hive adapters
flutter packages pub run build_runner build

# Watch for changes and rebuild
flutter packages pub run build_runner watch
```

### Debugging
- Use Flutter DevTools for performance analysis
- BLoC state inspection with flutter_bloc
- Network debugging through API service logs

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### MIT License

```
MIT License

Copyright (c) 2025 ShopSpot

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

**ShopSpot** - Discover, Explore, and Favorite Your Shopping Destinations 🛍️
