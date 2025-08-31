import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../theme/app_theme.dart';
import '../widgets/image_picker_widget.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final List<Category> categories;
  final VoidCallback onSaved;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.categories,
    required this.onSaved,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitController = TextEditingController();
  final _pointsEarnedController = TextEditingController();

  int? _selectedCategoryId;
  bool _isActive = true;
  String? _selectedImageFileName;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _populateFields();
    } else {
      _unitController.text = 'ชิ้น';
      _costController.text = '0';
      _stockController.text = '0';
      _pointsEarnedController.text = '1.0';
    }
  }

  void _populateFields() {
    final product = widget.product!;
    _nameController.text = product.name;
    _descriptionController.text = product.description ?? '';
    _skuController.text = product.sku ?? '';
    _barcodeController.text = product.barcode ?? '';
    _priceController.text = product.price.toString();
    _costController.text = product.cost.toString();
    _stockController.text = product.stock.toString();
    _unitController.text = product.unit;
    _pointsEarnedController.text = product.pointsEarned.toString();
    _selectedCategoryId = product.categoryId;
    _isActive = product.isActive;
    _selectedImageFileName = product.image;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spacing16),
            Expanded(
              child: Form(
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
          widget.product == null ? Icons.add : Icons.edit,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.spacing12),
        Text(
          widget.product == null ? 'เพิ่มสินค้าใหม่' : 'แก้ไขสินค้า',
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
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'ชื่อสินค้า *',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาใส่ชื่อสินค้า';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacing16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'รายละเอียด',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: AppTheme.spacing16),
          // Product Image Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'รูปภาพสินค้า',
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  ImagePickerWidget(
                    imageFileName: _selectedImageFileName,
                    onImageChanged: (fileName) {
                      setState(() {
                        _selectedImageFileName = fileName;
                      });
                    },
                    width: 150,
                    height: 150,
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'คำแนะนำ:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• ใช้รูปภาพที่มีความละเอียดสูง\n• ขนาดแนะนำ: 500x500 พิกเซล\n• รองรับไฟล์: JPG, PNG\n• ขนาดไฟล์ไม่เกิน 5MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU',
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'บาร์โค้ด',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          DropdownButtonFormField<int>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'หมวดหมู่',
            ),
            items: widget.categories.map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'ราคาขาย *',
                    suffixText: '฿',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาใส่ราคาขาย';
                    }
                    if (double.tryParse(value) == null) {
                      return 'กรุณาใส่ตัวเลข';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: TextFormField(
                  controller: _costController,
                  decoration: const InputDecoration(
                    labelText: 'ต้นทุน',
                    suffixText: '฿',
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
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนคงคลัง',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (int.tryParse(value) == null) {
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
                  controller: _pointsEarnedController,
                  decoration: const InputDecoration(
                    labelText: 'แต้มที่ได้รับ/ชิ้น',
                    suffixText: 'แต้ม',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาใส่แต้มที่ได้รับ';
                    }
                    if (double.tryParse(value) == null) {
                      return 'กรุณาใส่ตัวเลข';
                    }
                    final points = double.parse(value);
                    if (points < 0) {
                      return 'แต้มต้องไม่ติดลบ';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          TextFormField(
            controller: _unitController,
            decoration: const InputDecoration(
              labelText: 'หน่วย',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาใส่หน่วย';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacing16),
          SwitchListTile(
            title: const Text('เปิดใช้งาน'),
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
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
            onPressed: _saveProduct,
            child: const Text('บันทึก'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final database = Provider.of<AppDatabase>(context, listen: false);
      
      final companion = ProductsCompanion(
        id: widget.product?.id != null 
          ? drift.Value(widget.product!.id) 
          : const drift.Value.absent(),
        name: drift.Value(_nameController.text),
        description: drift.Value(_descriptionController.text.isEmpty 
          ? null 
          : _descriptionController.text),
        sku: drift.Value(_skuController.text.isEmpty 
          ? null 
          : _skuController.text),
        barcode: drift.Value(_barcodeController.text.isEmpty 
          ? null 
          : _barcodeController.text),
        categoryId: drift.Value(_selectedCategoryId),
        price: drift.Value(double.parse(_priceController.text)),
        cost: drift.Value(double.tryParse(_costController.text) ?? 0.0),
        stock: drift.Value(int.tryParse(_stockController.text) ?? 0),
        unit: drift.Value(_unitController.text),
        pointsEarned: drift.Value(double.tryParse(_pointsEarnedController.text) ?? 1.0),
        image: drift.Value(_selectedImageFileName),
        isActive: drift.Value(_isActive),
        updatedAt: drift.Value(DateTime.now()),
      );

      if (widget.product == null) {
        await database.into(database.products).insert(companion);
      } else {
        await database.update(database.products).replace(companion);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกสินค้าเรียบร้อย')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }
}
