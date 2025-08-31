import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../providers/shop_settings_provider.dart';
import '../theme/app_theme.dart';

class ShopSettingsForm extends StatefulWidget {
  const ShopSettingsForm({super.key});

  @override
  State<ShopSettingsForm> createState() => _ShopSettingsFormState();
}

class _ShopSettingsFormState extends State<ShopSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _vatRateController = TextEditingController();
  final _currencyController = TextEditingController();
  final _currencySymbolController = TextEditingController();
  final _promptPayIdController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopSettings();
  }

  Future<void> _loadShopSettings() async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final settings = await database.select(database.shopSettings).getSingleOrNull();
    
    print('Loading settings - PromptPay ID: ${settings?.promptPayId}');
    
    if (settings != null) {
      _shopNameController.text = settings.shopName;
      _addressController.text = settings.address ?? '';
      _phoneController.text = settings.phone ?? '';
      _emailController.text = settings.email ?? '';
      _vatRateController.text = settings.vatRate.toString();
      _currencyController.text = settings.currency;
      _currencySymbolController.text = settings.currencySymbol;
      _promptPayIdController.text = settings.promptPayId ?? '';
      print('Loaded PromptPay ID into controller: ${_promptPayIdController.text}');
    } else {
      print('No settings found in database');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spacing16),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: _buildForm(),
                  ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.store,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.spacing12),
        const Text(
          'ตั้งค่าข้อมูลร้านค้า',
          style: AppTheme.heading2,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextFormField(
            controller: _shopNameController,
            decoration: const InputDecoration(
              labelText: 'ชื่อร้านค้า *',
              prefixIcon: Icon(Icons.store),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาใส่ชื่อร้านค้า';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacing16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'ที่อยู่',
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: AppTheme.spacing16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'เบอร์โทรศัพท์',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'อีเมล',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _vatRateController,
                  decoration: const InputDecoration(
                    labelText: 'อัตราภาษี',
                    suffixText: '%',
                    prefixIcon: Icon(Icons.percent),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'กรุณาใส่ตัวเลข';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: TextFormField(
                  controller: _currencyController,
                  decoration: const InputDecoration(
                    labelText: 'สกุลเงิน',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          TextFormField(
            controller: _currencySymbolController,
            decoration: const InputDecoration(
              labelText: 'สัญลักษณ์เงิน',
              prefixIcon: Icon(Icons.currency_exchange),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          TextFormField(
            controller: _promptPayIdController,
            decoration: const InputDecoration(
              labelText: 'PromptPay ID (เบอร์โทร/เลขบัตรประชาชน)',
              prefixIcon: Icon(Icons.qr_code),
              hintText: 'เช่น 0891234567 หรือ 1234567890123',
              helperText: 'เบอร์โทร 10 หลัก หรือเลขบัตรประชาชน 13 หลัก',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                // ตรวจสอบรูปแบบเบอร์โทรหรือเลขบัตรประชาชน
                if (!RegExp(r'^[0-9]{10}$|^[0-9]{13}$').hasMatch(value)) {
                  return 'กรุณาใส่เบอร์โทร 10 หลัก หรือเลขบัตรประชาชน 13 หลัก';
                }
                // ตรวจสอบเบอร์โทรให้ขึ้นต้นด้วย 0
                if (value.length == 10 && !value.startsWith('0')) {
                  return 'เบอร์โทรต้องขึ้นต้นด้วย 0';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('บันทึก'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final settingsProvider = Provider.of<ShopSettingsProvider>(context, listen: false);
      
      // Debug: print the values being saved
      print('Saving PromptPay ID: ${_promptPayIdController.text}');
      
      final companion = ShopSettingsCompanion(
        shopName: drift.Value(_shopNameController.text),
        address: drift.Value(_addressController.text.isEmpty 
          ? null 
          : _addressController.text),
        phone: drift.Value(_phoneController.text.isEmpty 
          ? null 
          : _phoneController.text),
        email: drift.Value(_emailController.text.isEmpty 
          ? null 
          : _emailController.text),
        vatRate: drift.Value(double.tryParse(_vatRateController.text) ?? 7.0),
        currency: drift.Value(_currencyController.text),
        currencySymbol: drift.Value(_currencySymbolController.text),
        promptPayId: drift.Value(_promptPayIdController.text.isEmpty 
          ? null 
          : _promptPayIdController.text),
        updatedAt: drift.Value(DateTime.now()),
      );

      // ใช้ provider แทนการอัพเดทตรง ๆ
      await settingsProvider.updateSettings(companion);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการตั้งค่าเรียบร้อย - ราคาสินค้าจะอัพเดททันที')),
        );
      }
    } catch (e) {
      print('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vatRateController.dispose();
    _currencyController.dispose();
    _currencySymbolController.dispose();
    super.dispose();
  }
}
