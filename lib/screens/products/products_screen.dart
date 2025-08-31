import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_form_dialog.dart';
import '../../widgets/image_picker_widget.dart';
import '../../utils/responsive_utils.dart';
import '../../providers/shop_settings_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final database = Provider.of<AppDatabase>(context, listen: false);
    
    final products = await database.select(database.products).get();
    final categories = await database.select(database.categories).get();
    
    setState(() {
      _products = products;
      _categories = categories;
      _isLoading = false;
    });
  }

  List<Product> get _filteredProducts {
    var filtered = _products;
    
    if (_selectedCategoryId != null) {
      filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (p.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการสินค้า'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // actions: [
        //   IconButton(
        //     onPressed: _addProduct,
        //     icon: const Icon(Icons.add),
        //   ),
        // ],
      ),
      body: _isLoading ? 
        const Center(child: CircularProgressIndicator()) :
        Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(child: _buildProductList()),
          ],
        ),
      // เพิ่มปุ่มเพิ่มสินค้าที่มุมขวาล่าง
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: AppTheme.primaryColor,
        tooltip: 'เพิ่มสินค้าใหม่',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'ค้นหาสินค้า...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: AppTheme.spacing12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('ทั้งหมด'),
                  selected: _selectedCategoryId == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                  },
                ),
                const SizedBox(width: AppTheme.spacing8),
                ..._categories.map((category) => Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacing8),
                  child: FilterChip(
                    label: Text(category.name),
                    selected: _selectedCategoryId == category.id,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategoryId = category.id;
                      });
                    },
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final filteredProducts = _filteredProducts;
    
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'ไม่พบสินค้า',
              style: AppTheme.heading3.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            // const SizedBox(height: AppTheme.spacing8),
            // ElevatedButton(
            //   onPressed: _addProduct,
            //   child: const Text('เพิ่มสินค้าใหม่'),
            // ),
          ],
        ),
      );
    }

    return Consumer<ShopSettingsProvider>(
      builder: (context, shopSettings, child) {
        // Get responsive configuration based on navigation position
        final isConstrained = ResponsiveUtils.isContentAreaConstrained(context, shopSettings.navigationPosition);
        
        return ListView.builder(
          padding: EdgeInsets.all(isConstrained ? AppTheme.spacing12 : AppTheme.spacing16),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return ProductListItem(
              product: product,
              category: _categories.firstWhere(
                (c) => c.id == product.categoryId,
                orElse: () => Category(
                  id: 0,
                  name: 'ไม่มีหมวดหมู่',
                  description: null,
                  color: null,
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              ),
              onEdit: () => _editProduct(product),
              onDelete: () => _deleteProduct(product),
              onStockChange: (product, newStock) => _updateStock(product, newStock),
              isConstrained: isConstrained,
            );
          },
        );
      },
    );
  }

  void _addProduct() {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        categories: _categories,
        onSaved: _loadData,
      ),
    );
  }

  Future<void> _updateStock(Product product, int newStock) async {
    if (newStock < 0) return; // ป้องกันค่าติดลบ
    
    try {
      final database = Provider.of<AppDatabase>(context, listen: false);
      await database.updateProductStock(product.id, newStock);
      _loadData(); // รีโหลดข้อมูล
      
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('อัปเดต stock ของ ${product.name} เป็น $newStock เรียบร้อยแล้ว'),
      //     backgroundColor: Colors.green,
      //   ),
      // );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        product: product,
        categories: _categories,
        onSaved: _loadData,
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบสินค้า'),
        content: Text('คุณต้องการลบสินค้า "${product.name}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final database = Provider.of<AppDatabase>(context, listen: false);
              await database.delete(database.products).delete(product);
              Navigator.pop(context);
              _loadData();
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

class ProductListItem extends StatelessWidget {
  final Product product;
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Product, int) onStockChange;
  final bool isConstrained;

  const ProductListItem({
    super.key,
    required this.product,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onStockChange,
    this.isConstrained = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: isConstrained ? 6.0 : AppTheme.spacing8),
      child: isConstrained ? _buildCompactLayout(context) : _buildStandardLayout(context),
    );
  }

  Widget _buildStandardLayout(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 60,
        height: 60,
        child: product.image != null
            ? ProductImageDisplay(
                imageFileName: product.image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
            : Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
      ),
      title: Text(
        product.name,
        style: AppTheme.heading3,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.name,
            style: AppTheme.caption,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Row(
            children: [
              Text(
                '฿${product.price.toStringAsFixed(2)}',
                style: AppTheme.body.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius4),
                ),
                child: Text(
                  '+${product.pointsEarned.toStringAsFixed(1)} แต้ม',
                  style: AppTheme.caption.copyWith(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: _getStockColor(),
                  borderRadius: BorderRadius.circular(AppTheme.radius4),
                ),
                child: Text(
                  '${product.stock} ${product.unit}',
                  style: AppTheme.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: _buildTrailingActions(context, false),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      child: Row(
        children: [
          // Compact image
          Container(
            width: 40,
            height: 40,
            child: product.image != null
                ? ProductImageDisplay(
                    imageFileName: product.image,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius4),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  category.name,
                  style: AppTheme.caption.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '฿${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getStockColor(),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${product.stock}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Compact trailing actions
          _buildTrailingActions(context, true),
        ],
      ),
    );
  }

  Widget _buildTrailingActions(BuildContext context, bool isCompact) {
    if (isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact stock adjustment
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => onStockChange(product, product.stock - 1),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    child: const Icon(Icons.remove, size: 12),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '${product.stock}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                InkWell(
                  onTap: () => onStockChange(product, product.stock + 1),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    child: const Icon(Icons.add, size: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton(
            iconSize: 16,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('แก้ไข', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppTheme.errorColor, size: 16),
                    SizedBox(width: 8),
                    Text('ลบ', style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
          ),
        ],
      );
    }

    // Standard trailing actions
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick stock adjustment
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => onStockChange(product, product.stock - 1),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.remove, size: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '${product.stock}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              InkWell(
                onTap: () => onStockChange(product, product.stock + 1),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.add, size: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('แก้ไข'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppTheme.errorColor),
                  SizedBox(width: 8),
                  Text('ลบ', style: TextStyle(color: AppTheme.errorColor)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
        ),
      ],
    );
  }

  Color _getStockColor() {
    if (product.stock <= 0) return AppTheme.errorColor;
    if (product.stock <= 5) return AppTheme.warningColor; // เตือนเมื่อคงเหลือ <= 5
    return AppTheme.successColor;
  }
}
