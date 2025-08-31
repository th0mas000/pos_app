import '../database/database.dart';
import 'package:drift/drift.dart' as drift;

class SettingsTest {
  static Future<void> testPromptPaySettings(AppDatabase database) async {
    print('=== Testing PromptPay Settings ===');
    
    try {
      // Test 1: Check if table exists and can be queried
      final settings = await database.select(database.shopSettings).getSingleOrNull();
      print('Current settings: $settings');
      
      // Test 2: Try to save a PromptPay ID
      final testPromptPayId = '0891234567';
      
      if (settings != null) {
        await (database.update(database.shopSettings)
          ..where((s) => s.id.equals(settings.id)))
          .write(ShopSettingsCompanion(
            promptPayId: drift.Value(testPromptPayId),
            updatedAt: drift.Value(DateTime.now()),
          ));
        print('Updated existing settings with PromptPay ID: $testPromptPayId');
      } else {
        await database.into(database.shopSettings).insert(ShopSettingsCompanion.insert(
          shopName: 'Test Shop',
          promptPayId: drift.Value(testPromptPayId),
        ));
        print('Inserted new settings with PromptPay ID: $testPromptPayId');
      }
      
      // Test 3: Verify the save
      final updatedSettings = await database.select(database.shopSettings).getSingleOrNull();
      print('PromptPay ID after save: ${updatedSettings?.promptPayId}');
      
      if (updatedSettings?.promptPayId == testPromptPayId) {
        print('✅ PromptPay settings working correctly!');
      } else {
        print('❌ PromptPay settings not saved correctly');
      }
      
    } catch (e) {
      print('❌ Error testing PromptPay settings: $e');
    }
    
    print('=== End Testing ===');
  }
}
