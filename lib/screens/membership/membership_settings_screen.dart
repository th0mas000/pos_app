import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database.dart';
import '../../providers/membership_provider.dart';
import '../../theme/app_theme.dart';
import 'package:drift/drift.dart' as drift;

class MembershipSettingsScreen extends StatefulWidget {
  const MembershipSettingsScreen({super.key});

  @override
  State<MembershipSettingsScreen> createState() => _MembershipSettingsScreenState();
}

class _MembershipSettingsScreenState extends State<MembershipSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // ลบระบบระดับสมาชิก - ใช้แค่ 1 tab
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าระบบสมาชิก'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // ลบ TabBar - ใช้หน้าเดียว
      ),
      body: const MembershipSettingsForm(), // ใช้ form โดยตรง
    );
  }
}

class MembershipSettingsForm extends StatefulWidget {
  const MembershipSettingsForm({super.key});

  @override
  State<MembershipSettingsForm> createState() => _MembershipSettingsFormState();
}

class _MembershipSettingsFormState extends State<MembershipSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _minSpendController;
  late TextEditingController _maxPointsController;
  // Controllers สำหรับการใช้แต้มถูกยกเลิกแล้ว
  late TextEditingController _pointsExpirationController;
  late TextEditingController _birthdayBonusController;
  late TextEditingController _referralBonusController;
  late TextEditingController _expirationWarningController;

  // ลบระบบระดับสมาชิก - ไม่ต้องใช้ตัวแปรนี้แล้ว
  bool _enablePointsExpiration = false;
  bool _enableBirthdayBonus = false;
  bool _enableReferralBonus = false;
  bool _enablePointsNotification = true;
  bool _enableExpirationWarning = true;

  @override
  void initState() {
    super.initState();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ensure membership service is initialized
      final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
      await membershipProvider.membershipService.ensureInitialized();
      _loadCurrentSettings();
    });
  }

  void _initControllers() {
    _minSpendController = TextEditingController();
    _maxPointsController = TextEditingController();
    // Controllers สำหรับการใช้แต้มถูกยกเลิกแล้ว
    _pointsExpirationController = TextEditingController();
    _birthdayBonusController = TextEditingController();
    _referralBonusController = TextEditingController();
    _expirationWarningController = TextEditingController();
  }

  void _loadCurrentSettings() {
    final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
    final settings = membershipProvider.settings;

    debugPrint('Loading membership settings: $settings');

    if (settings != null) {
      // pointsPerBaht ไม่ใช้แล้ว
      _minSpendController.text = settings.minSpendForPoints.toString();
      _maxPointsController.text = settings.maxPointsPerTransaction.toString();
      // การใช้แต้มถูกยกเลิกแล้ว - ไม่ต้องโหลดค่า
      _pointsExpirationController.text = settings.pointsExpirationDays.toString();
      _birthdayBonusController.text = settings.birthdayBonusPoints.toString();
      _referralBonusController.text = settings.referralBonusPoints.toString();
      _expirationWarningController.text = settings.expirationWarningDays.toString();

      setState(() {
        // ลบระบบระดับสมาชิก - ปิดการใช้งานโดยถาวร
        _enablePointsExpiration = settings.enablePointsExpiration;
        _enableBirthdayBonus = settings.enableBirthdayBonus;
        _enableReferralBonus = settings.enableReferralBonus;
        _enablePointsNotification = settings.enablePointsNotification;
        _enableExpirationWarning = settings.enableExpirationWarning;
      });
    } else {
      // ค่าเริ่มต้น (ไม่ต้องตั้งค่า pointsPerBaht)
      debugPrint('No settings found, using defaults');
      _minSpendController.text = '0.0';
      _maxPointsController.text = '1000.0';
      // การใช้แต้มถูกยกเลิกแล้ว - ไม่ต้องตั้งค่าเริ่มต้น
      _pointsExpirationController.text = '365';
      _birthdayBonusController.text = '100.0';
      _referralBonusController.text = '50.0';
      _expirationWarningController.text = '30';
    }
  }

  @override
  void dispose() {
    // pointsPerBahtController ไม่ใช้แล้ว
    _minSpendController.dispose();
    _maxPointsController.dispose();
    // Controllers สำหรับการใช้แต้มถูกยกเลิกแล้ว
    _pointsExpirationController.dispose();
    _birthdayBonusController.dispose();
    _referralBonusController.dispose();
    _expirationWarningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildSection(
            //   title: 'การสะสมแต้ม',
            //   icon: Icons.add_circle,
            //   children: [
            //     Text(
            //       'แต้มจะคำนวณจากสินค้าที่ซื้อ (ตั้งค่าที่หน้าจัดการสินค้า)',
            //       style: TextStyle(
            //         color: Colors.grey[600],
            //         fontSize: 14,
            //       ),
            //     ),
            //     const SizedBox(height: AppTheme.spacing12),
            //     _buildNumberField(
            //       controller: _minSpendController,
            //       label: 'ยอดซื้อขั้นต่ำเพื่อสะสมแต้ม (บาท)',
            //       hint: 'เช่น 50 = ต้องซื้อขั้นต่ำ 50 บาทขึ้นไป',
            //     ),
            //     const SizedBox(height: AppTheme.spacing12),
            //     _buildNumberField(
            //       controller: _maxPointsController,
            //       label: 'แต้มสูงสุดต่อรายการ',
            //       hint: 'เช่น 1000 = ได้แต้มสูงสุด 1,000 แต้มต่อรายการ',
            //     ),
            //   ],
            // ),
            // ระบบการใช้แต้มถูกยกเลิกแล้ว
            const SizedBox(height: AppTheme.spacing24),
            // ลบระบบระดับสมาชิก - ไม่แสดงหัวข้อนี้อีกต่อไป
            
            const SizedBox(height: AppTheme.spacing24),
            _buildSection(
              title: 'การหมดอายุของแต้ม',
              icon: Icons.schedule,
              children: [
                SwitchListTile(
                  title: const Text('เปิดใช้การหมดอายุของแต้ม'),
                  subtitle: const Text('แต้มจะหมดอายุตามระยะเวลาที่กำหนด'),
                  value: _enablePointsExpiration,
                  onChanged: (value) {
                    setState(() {
                      _enablePointsExpiration = value;
                    });
                  },
                ),
                if (_enablePointsExpiration) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  _buildNumberField(
                    controller: _pointsExpirationController,
                    label: 'แต้มหมดอายุหลังจาก (วัน)',
                    hint: 'เช่น 365 = แต้มหมดอายุหลังจาก 1 ปี',
                    isInteger: true,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.spacing24),
            _buildSection(
              title: 'โบนัสและโปรโมชั่น',
              icon: Icons.card_giftcard,
              children: [
                SwitchListTile(
                  title: const Text('โบนัสวันเกิด'),
                  subtitle: const Text('ให้แต้มโบนัสในวันเกิดของสมาชิก'),
                  value: _enableBirthdayBonus,
                  onChanged: (value) {
                    setState(() {
                      _enableBirthdayBonus = value;
                    });
                  },
                ),
                if (_enableBirthdayBonus) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  _buildNumberField(
                    controller: _birthdayBonusController,
                    label: 'แต้มโบนัสวันเกิด',
                    hint: 'จำนวนแต้มที่ให้ในวันเกิด',
                  ),
                ],
                const SizedBox(height: AppTheme.spacing12),
                SwitchListTile(
                  title: const Text('โบนัสการแนะนำเพื่อน'),
                  subtitle: const Text('ให้แต้มโบนัสเมื่อแนะนำเพื่อนมาสมัครสมาชิก'),
                  value: _enableReferralBonus,
                  onChanged: (value) {
                    setState(() {
                      _enableReferralBonus = value;
                    });
                  },
                ),
                if (_enableReferralBonus) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  _buildNumberField(
                    controller: _referralBonusController,
                    label: 'แต้มโบนัสการแนะนำ',
                    hint: 'จำนวนแต้มที่ให้เมื่อแนะนำเพื่อน',
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.spacing24),
            _buildSection(
              title: 'การแจ้งเตือน',
              icon: Icons.notifications,
              children: [
                SwitchListTile(
                  title: const Text('แจ้งเตือนเมื่อได้รับแต้ม'),
                  subtitle: const Text('แจ้งเตือนสมาชิกเมื่อได้รับแต้มใหม่'),
                  value: _enablePointsNotification,
                  onChanged: (value) {
                    setState(() {
                      _enablePointsNotification = value;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacing12),
                SwitchListTile(
                  title: const Text('เตือนแต้มใกล้หมดอายุ'),
                  subtitle: const Text('แจ้งเตือนเมื่อแต้มใกล้หมดอายุ'),
                  value: _enableExpirationWarning,
                  onChanged: (value) {
                    setState(() {
                      _enableExpirationWarning = value;
                    });
                  },
                ),
                if (_enableExpirationWarning) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  _buildNumberField(
                    controller: _expirationWarningController,
                    label: 'แจ้งเตือนก่อนหมดอายุ (วัน)',
                    hint: 'เช่น 30 = แจ้งเตือนก่อนหมดอายุ 30 วัน',
                    isInteger: true,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTheme.spacing32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                ),
                child: const Text(
                  'บันทึกการตั้งค่า',
                  style: AppTheme.heading3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: AppTheme.spacing8),
                Text(title, style: AppTheme.heading3),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isInteger = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'กรุณากรอก$label';
        }
        final number = isInteger ? int.tryParse(value) : double.tryParse(value);
        if (number == null || number < 0) {
          return 'กรุณากรอกตัวเลขที่ถูกต้อง';
        }
        return null;
      },
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      debugPrint('Saving membership settings...');
      final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);

      await membershipProvider.updateMembershipSettings(
        MembershipSettingsCompanion(
          // pointsPerBaht: ไม่ใช้แล้ว จะคำนวณจากสินค้า
          minSpendForPoints: drift.Value(double.parse(_minSpendController.text)),
          maxPointsPerTransaction: drift.Value(double.parse(_maxPointsController.text)),
          // การใช้แต้มถูกยกเลิกแล้ว - ไม่ต้องบันทึกค่า
          pointsToDiscountRate: const drift.Value(1.0), // ค่าเริ่มต้น
          minPointsToRedeem: const drift.Value(10.0), // ค่าเริ่มต้น
          maxDiscountPercent: const drift.Value(100.0), // ค่าเริ่มต้น
          enableMembershipTiers: const drift.Value(false), // ปิดระบบระดับสมาชิกถาวร
          enablePointsExpiration: drift.Value(_enablePointsExpiration),
          pointsExpirationDays: drift.Value(int.parse(_pointsExpirationController.text)),
          enableBirthdayBonus: drift.Value(_enableBirthdayBonus),
          birthdayBonusPoints: drift.Value(double.parse(_birthdayBonusController.text)),
          enableReferralBonus: drift.Value(_enableReferralBonus),
          referralBonusPoints: drift.Value(double.parse(_referralBonusController.text)),
          enablePointsNotification: drift.Value(_enablePointsNotification),
          enableExpirationWarning: drift.Value(_enableExpirationWarning),
          expirationWarningDays: drift.Value(int.parse(_expirationWarningController.text)),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
      
      debugPrint('Membership settings saved successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกการตั้งค่าเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving membership settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
