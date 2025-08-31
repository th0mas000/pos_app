import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shop_settings_form.dart';
import '../../widgets/category_management.dart';
import '../../widgets/navigation_settings_form.dart';
import '../../debug/settings_test.dart';
import '../membership/membership_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [
          _buildSettingsSection(
            title: 'ข้อมูลร้านค้า',
            icon: Icons.store,
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('ข้อมูลร้านค้า'),
                subtitle: const Text('แก้ไขชื่อร้าน ที่อยู่ และข้อมูลติดต่อ'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showShopSettingsDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildSettingsSection(
            title: 'การจัดการสินค้า',
            icon: Icons.inventory_2,
            children: [
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('หมวดหมู่สินค้า'),
                subtitle: const Text('จัดการหมวดหมู่สินค้า'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCategoryManagement(context),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          // _buildSettingsSection(
          //   title: 'ระบบสมาชิก',
          //   icon: Icons.card_membership,
          //   children: [
          //     ListTile(
          //       leading: const Icon(Icons.settings),
          //       title: const Text('ตั้งค่าระบบสมาชิก'),
          //       subtitle: const Text('กำหนดการสะสมแต้ม ระดับสมาชิก และสิทธิพิเศษ'),
          //       trailing: const Icon(Icons.chevron_right),
          //       onTap: () => _showMembershipSettings(context),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: AppTheme.spacing16),
          _buildSettingsSection(
            title: 'หน้าตาและการใช้งาน',
            icon: Icons.design_services,
            children: [
              ListTile(
                leading: const Icon(Icons.navigation),
                title: const Text('ตำแหน่งเมนูหลัก'),
                subtitle: const Text('เปลี่ยนตำแหน่งเมนูนำทาง'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showNavigationSettings(context),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildSettingsSection(
            title: 'ระบบ',
            icon: Icons.settings,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text('ล้างข้อมูลรายงาน'),
                subtitle: const Text('ลบข้อมูลการขายทั้งหมด (ไม่สามารถกู้คืนได้)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearDataDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('สำรองข้อมูล'),
                subtitle: const Text('สำรองและกู้คืนข้อมูล'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ฟีเจอร์นี้กำลังพัฒนา')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('เกี่ยวกับแอป'),
                subtitle: const Text('ข้อมูลแอปพลิเคชัน'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAboutDialog(context),
              ),
              // Debug button (remove in production)
              // ListTile(
              //   leading: const Icon(Icons.bug_report, color: Colors.orange),
              //   title: const Text('ทดสอบ PromptPay Settings'),
              //   subtitle: const Text('สำหรับแก้ไขปัญหา'),
              //   trailing: const Icon(Icons.chevron_right),
              //   onTap: () => _testPromptPaySettings(context),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spacing8),
                Text(title, style: AppTheme.heading3),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  void _showShopSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ShopSettingsForm(),
    );
  }

  void _showNavigationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NavigationSettingsForm(),
    );
  }

  // void _showMembershipSettings(BuildContext context) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const MembershipSettingsScreen(),
  //     ),
  //   );
  // }

  void _showCategoryManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CategoryManagement(),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ล้างข้อมูลรายงาน'),
        content: const Text(
          'คุณต้องการลบข้อมูลการขายทั้งหมดหรือไม่?\n\n'
          '⚠️ การดำเนินการนี้ไม่สามารถกู้คืนได้!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => _clearSalesData(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearSalesData(BuildContext context) async {
    try {
      Navigator.pop(context); // ปิด dialog
      
      // แสดง loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final database = Provider.of<AppDatabase>(context, listen: false);
      await database.clearSalesData();

      Navigator.pop(context); // ปิด loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบข้อมูลการขายเรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // ปิด loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Mini POS',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.point_of_sale,
          size: 32,
          color: AppTheme.primaryColor,
        ),
      ),
      children: [
        const Text('แอปพลิเคชัน POS สำเร็จรูปที่สร้างด้วย Flutter'),
        const SizedBox(height: 16),
        const Text('คุณสมบัติ:'),
        const Text('• ระบบขายหน้าร้าน'),
        const Text('• จัดการสินค้าและหมวดหมู่'),
        const Text('• จัดการลูกค้า'),
        const Text('• รายงานการขาย'),
        const Text('• ฐานข้อมูลท้องถิ่น'),
      ],
    );
  }

  Future<void> _testPromptPaySettings(BuildContext context) async {
    try {
      final database = Provider.of<AppDatabase>(context, listen: false);
      await SettingsTest.testPromptPaySettings(database);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ทดสอบเสร็จสิ้น กรุณาตรวจสอบ Debug Console'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการทดสอบ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
