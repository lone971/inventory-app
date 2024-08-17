import 'package:flutter/material.dart';
import 'package:inventoryapp/screens/item_list.dart';
import 'package:inventoryapp/screens/dashboard.dart';
import 'package:inventoryapp/screens/item_update.dart';
import 'package:inventoryapp/screens/item_form.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light, // Light theme settings
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue, // Light theme app bar color
          foregroundColor: Colors.white, // Light theme app bar text color
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue, // Light theme FAB color
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue, // Light theme button color
            backgroundColor:
            Colors.transparent, // Set a background color if needed
          ),
        ),
        // Add other theme customizations as needed
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark, // Dark theme settings
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey, // Dark theme app bar color
          foregroundColor: Colors.white, // Dark theme app bar text color
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueGrey, // Dark theme FAB color
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blueGrey, // Dark theme button color
            backgroundColor:
            Colors.transparent, // Set a background color if needed
          ),
        ),
        // Add other theme customizations as needed
      ),
      themeMode: ThemeMode.system, // Automatically switch themes
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const ItemList());
          case '/dashboard':
            return MaterialPageRoute(builder: (context) => const Dashboard());
          case '/item_update':
          // Extract arguments for ItemUpdate
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ItemUpdate(item: args),
            );
          case '/item_form':
            return MaterialPageRoute(builder: (context) => const ItemForm());
          default:
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('404'),
                ),
                body: const Center(
                  child: Text('Page not found'),
                ),
              ),
            );
        }
      },
    );
  }
}
