import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' show Value;
import '../providers/shop_settings_provider.dart';
import '../database/database.dart';
import '../theme/app_theme.dart';

class NavigationSettingsForm extends StatefulWidget {
  const NavigationSettingsForm({super.key});

  @override
  State<NavigationSettingsForm> createState() => _NavigationSettingsFormState();
}

class _NavigationSettingsFormState extends State<NavigationSettingsForm> {
  String _selectedPosition = 'bottom';
  bool _isLoading = false;

  final Map<String, String> _positions = {
    'bottom': 'ด้านล่าง',
    'top': 'ด้านบน',
    'left': 'ด้านซ้าย',
    'right': 'ด้านขวา',
  };

  final Map<String, IconData> _positionIcons = {
    'bottom': Icons.vertical_align_bottom,
    'top': Icons.vertical_align_top,
    'left': Icons.keyboard_arrow_left,
    'right': Icons.keyboard_arrow_right,
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentPosition();
  }

  void _loadCurrentPosition() {
    final provider = Provider.of<ShopSettingsProvider>(context, listen: false);
    setState(() {
      _selectedPosition = provider.navigationPosition;
    });
  }

  Future<void> _saveSettings() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<ShopSettingsProvider>(context, listen: false);
      await provider.updateSettings(
        ShopSettingsCompanion(
          navigationPosition: Value(_selectedPosition),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกการตั้งค่าสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ตั้งค่าตำแหน่งเมนู'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'เลือกตำแหน่งที่ต้องการแสดงเมนูหลัก',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...(_positions.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<String>(
                  value: entry.key,
                  groupValue: _selectedPosition,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPosition = value;
                      });
                    }
                  },
                  title: Row(
                    children: [
                      Icon(_positionIcons[entry.key], size: 20),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                  activeColor: AppTheme.primaryColor,
                ),
              );
            }).toList()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'การเปลี่ยนตำแหน่งจะมีผลทันทีหลังจากบันทึก',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('บันทึก'),
        ),
      ],
    );
  }
}
