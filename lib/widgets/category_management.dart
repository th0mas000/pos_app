import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../theme/app_theme.dart';

class CategoryManagement extends StatefulWidget {
  const CategoryManagement({super.key});

  @override
  State<CategoryManagement> createState() => _CategoryManagementState();
}

class _CategoryManagementState extends State<CategoryManagement> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    
    final database = Provider.of<AppDatabase>(context, listen: false);
    final categories = await database.select(database.categories).get();
    
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spacing16),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCategoryList(),
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
          Icons.category,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.spacing12),
        Text(
          'จัดการหมวดหมู่สินค้า',
          style: AppTheme.heading2.copyWith(
            fontSize: 18, // ปรับขนาดฟอนต์ตามที่ต้องการ
          ),
        ),
        // const Spacer(),
        // IconButton(
        //   onPressed: _addCategory,
        //   icon: const Icon(Icons.add),
        //   tooltip: 'เพิ่มหมวดหมู่',
        // ),
      ],
    );
  }

  Widget _buildCategoryList() {
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'ไม่มีหมวดหมู่',
              style: AppTheme.heading3.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('เพิ่มหมวดหมู่แรก'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return CategoryListItem(
          category: category,
          onEdit: () => _editCategory(category),
          onDelete: () => _deleteCategory(category),
        );
      },
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: ElevatedButton(
            onPressed: _addCategory,
            child: const Text('เพิ่มหมวดหมู่'),
          ),
        ),
      ],
    );
  }

  void _addCategory() {
    _showCategoryDialog();
  }

  void _editCategory(Category category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({Category? category}) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        category: category,
        onSaved: _loadCategories,
      ),
    );
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบหมวดหมู่'),
        content: Text('คุณต้องการลบหมวดหมู่ "${category.name}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final database = Provider.of<AppDatabase>(context, listen: false);
              await database.delete(database.categories).delete(category);
              Navigator.pop(context);
              _loadCategories();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }
}

class CategoryListItem extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
    Widget build(BuildContext context) {
      return Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.5 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius8),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: category.color != null
                        ? _parseColor(category.color!)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius8),
                  ),
                  child: Icon(
                    Icons.category,
                    color: category.color != null
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTheme.heading3,
                      ),
                      if (category.description != null && category.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            category.description!,
                            style: AppTheme.caption,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).platform == TargetPlatform.iOS
                            ? Colors.blue
                            : Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      tooltip: 'แก้ไข',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      tooltip: 'ลบ',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.blue;
    }
  }
}

class CategoryFormDialog extends StatefulWidget {
  final Category? category;
  final VoidCallback onSaved;

  const CategoryFormDialog({
    super.key,
    this.category,
    required this.onSaved,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  Color _selectedColor = Colors.blue;
  bool _isActive = true;

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final category = widget.category!;
    _nameController.text = category.name;
    _descriptionController.text = category.description ?? '';
    _isActive = category.isActive;
    
    if (category.color != null) {
      try {
        _selectedColor = Color(int.parse(category.color!.replaceFirst('#', '0xff')));
      } catch (e) {
        _selectedColor = Colors.blue;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spacing16),
            Form(
              key: _formKey,
              child: _buildForm(),
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
          widget.category == null ? Icons.add : Icons.edit,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.spacing12),
        Text(
          widget.category == null ? 'เพิ่มหมวดหมู่' : 'แก้ไขหมวดหมู่',
          style: AppTheme.heading2,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'ชื่อหมวดหมู่ *',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณาใส่ชื่อหมวดหมู่';
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
          maxLines: 2,
        ),
        const SizedBox(height: AppTheme.spacing16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('สีหมวดหมู่', style: AppTheme.body),
            const SizedBox(height: AppTheme.spacing8),
            Wrap(
              spacing: AppTheme.spacing8,
              children: _availableColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                    ),
                    child: _selectedColor == color
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                  ),
                );
              }).toList(),
            ),
          ],
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
            onPressed: _saveCategory,
            child: const Text('บันทึก'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final database = Provider.of<AppDatabase>(context, listen: false);
      
      final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2)}';
      
      final companion = CategoriesCompanion(
        id: widget.category?.id != null 
          ? drift.Value(widget.category!.id) 
          : const drift.Value.absent(),
        name: drift.Value(_nameController.text),
        description: drift.Value(_descriptionController.text.isEmpty 
          ? null 
          : _descriptionController.text),
        color: drift.Value(colorHex),
        isActive: drift.Value(_isActive),
        updatedAt: drift.Value(DateTime.now()),
      );

      if (widget.category == null) {
        await database.into(database.categories).insert(companion);
      } else {
        await database.update(database.categories).replace(companion);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกหมวดหมู่เรียบร้อย')),
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
    super.dispose();
  }
}
