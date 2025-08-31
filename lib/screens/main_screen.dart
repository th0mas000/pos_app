import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_settings_provider.dart';
import '../widgets/adaptive_navigation_layout.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/membership/membership_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PosScreen(),
    const ProductsScreen(),
    const MembershipScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.point_of_sale),
      label: 'POS',
    ),
    const NavigationDestination(
      icon: Icon(Icons.inventory_2),
      label: 'สินค้า',
    ),
    const NavigationDestination(
      icon: Icon(Icons.card_membership),
      label: 'สมาชิก',
    ),
    const NavigationDestination(
      icon: Icon(Icons.analytics),
      label: 'รายงาน',
    ),
    const NavigationDestination(
      icon: Icon(Icons.settings),
      label: 'ตั้งค่า',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopSettingsProvider>(
      builder: (context, shopSettings, child) {
        return AdaptiveNavigationLayout(
          body: _screens[_currentIndex],
          currentIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: _destinations,
          position: shopSettings.navigationPosition,
        );
      },
    );
  }
}
