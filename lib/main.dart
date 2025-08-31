import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'database/database.dart';
import 'providers/cart_provider.dart';
import 'providers/customers_provider.dart';
import 'providers/membership_provider.dart';
import 'providers/shop_settings_provider.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock app to portrait mode only - disable landscape orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  static final AppDatabase _database = AppDatabase();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: _database),
        ChangeNotifierProvider<ShopSettingsProvider>(
          create: (context) => ShopSettingsProvider(_database),
        ),
        ChangeNotifierProxyProvider<ShopSettingsProvider, CartProvider>(
          create: (context) => CartProvider(_database),
          update: (context, shopSettings, cartProvider) {
            cartProvider ??= CartProvider(_database);
            cartProvider.setShopSettingsProvider(shopSettings);
            return cartProvider;
          },
        ),
        ChangeNotifierProvider<CustomersProvider>(
          create: (context) => CustomersProvider(_database),
        ),
        ChangeNotifierProvider<MembershipProvider>(
          create: (context) => MembershipProvider(_database),
        ),
      ],
      child: MaterialApp(
        title: 'Mini POS',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
        localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('th', 'TH'), // ภาษาไทย
    Locale('en', 'US'), // ภาษาอังกฤษ (ถ้ามี)
  ],
      ),
    );
  }
}
