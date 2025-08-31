import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';

class SettingsService {
  static const String _promptPayIdKey = 'promptpay_id';
  
  static Future<String?> getPromptPayId() async {
    try {
      // ลองดึงจาก SharedPreferences ก่อน (สำหรับการ cache)
      final prefs = await SharedPreferences.getInstance();
      final cachedId = prefs.getString(_promptPayIdKey);
      if (cachedId != null) {
        return cachedId;
      }
      
      // หากไม่มี cache ให้ดึงจากฐานข้อมูล
      // สำหรับตอนนี้ return default value
      return null;
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> savePromptPayId(String promptPayId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_promptPayIdKey, promptPayId);
    } catch (e) {
      // Handle error
    }
  }
  
  static Future<String?> getPromptPayIdFromDatabase(AppDatabase database) async {
    try {
      final settings = await database.select(database.shopSettings).getSingleOrNull();
      return settings?.promptPayId;
    } catch (e) {
      return null;
    }
  }
}
