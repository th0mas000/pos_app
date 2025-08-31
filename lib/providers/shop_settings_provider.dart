import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';

class ShopSettingsProvider extends ChangeNotifier {
  final AppDatabase _database;
  ShopSetting? _shopSettings;
  
  ShopSettingsProvider(this._database) {
    loadSettings();
  }
  
  ShopSetting? get shopSettings => _shopSettings;
  double get vatRate => _shopSettings?.vatRate ?? 7.0;
  String get shopName => _shopSettings?.shopName ?? 'ร้านค้า';
  String get currency => _shopSettings?.currency ?? 'THB';
  String get currencySymbol => _shopSettings?.currencySymbol ?? '฿';
  String? get promptPayId => _shopSettings?.promptPayId;
  String get navigationPosition => _shopSettings?.navigationPosition ?? 'bottom';
  
  Future<void> loadSettings() async {
    try {
      final settings = await _database.select(_database.shopSettings).getSingleOrNull();
      _shopSettings = settings;
      notifyListeners();
    } catch (e) {
      print('Error loading shop settings: $e');
      // Create default settings if none exist or there's an error
      try {
        await _createDefaultSettings();
      } catch (e2) {
        print('Error creating default settings: $e2');
      }
    }
  }
  
  Future<void> _createDefaultSettings() async {
    await _database.into(_database.shopSettings).insert(
      ShopSettingsCompanion(
        shopName: const Value('ร้านค้า'),
        navigationPosition: const Value('bottom'),
      ),
    );
    await loadSettings();
  }
  
  Future<void> updateSettings(ShopSettingsCompanion companion) async {
    try {
      final existing = await _database.select(_database.shopSettings).getSingleOrNull();
      
      if (existing != null) {
        // Update existing record
        await (_database.update(_database.shopSettings)
          ..where((s) => s.id.equals(existing.id)))
          .write(companion);
      } else {
        // Insert new record with required fields
        final newCompanion = ShopSettingsCompanion(
          shopName: const Value('ร้านค้า'),
          navigationPosition: companion.navigationPosition,
        );
        await _database.into(_database.shopSettings).insert(newCompanion);
      }
      
      // Reload settings to reflect changes
      await loadSettings();
    } catch (e) {
      print('Error updating shop settings: $e');
      rethrow;
    }
  }
  
  double calculatePriceWithVat(double basePrice) {
    return basePrice * (1 + vatRate / 100);
  }
  
  double calculateVatAmount(double basePrice) {
    return basePrice * (vatRate / 100);
  }
}
