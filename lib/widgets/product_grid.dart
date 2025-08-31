import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../database/database.dart';
import '../providers/cart_provider.dart';
import '../providers/shop_settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/image_picker_widget.dart';
import '../utils/responsive_utils.dart';

class ProductGrid extends StatefulWidget {
  final int? categoryId;
  final String searchQuery;

  const ProductGrid({
    super.key,
    this.categoryId,
    this.searchQuery = '',
  });

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void didUpdateWidget(ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.searchQuery != widget.searchQuery) {
      _loadProducts();
    }
  }

  // เพิ่มฟังก์ชันสำหรับ refresh ข้อมูลเมื่อกลับมาจาก settings
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ไม่ต้องโหลด VAT rate ที่นี่เพราะจะใช้ Provider แทน
  }

  // เพิ่มฟังก์ชันสำหรับ refresh ทั้งหมด
  Future<void> refresh() async {
    await _loadProducts();
  }

  // ลบฟังก์ชัน _loadVatRate เพราะจะใช้ Provider แทน

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    final database = Provider.of<AppDatabase>(context, listen: false);
    var query = database.select(database.products)
      ..where((tbl) => tbl.isActive.equals(true));

    if (widget.categoryId != null) {
      query = query..where((tbl) => tbl.categoryId.equals(widget.categoryId!));
    }

    final products = await query.get();
    
    List<Product> filteredProducts = products;
    if (widget.searchQuery.isNotEmpty) {
      filteredProducts = products.where((product) =>
        product.name.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
        (product.barcode?.toLowerCase().contains(widget.searchQuery.toLowerCase()) ?? false) ||
        (product.sku?.toLowerCase().contains(widget.searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    setState(() {
      _products = filteredProducts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
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
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'ลองเปลี่ยนหมวดหมู่หรือคำค้นหา',
              style: AppTheme.body.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Consumer<ShopSettingsProvider>(
        builder: (context, shopSettings, child) {
          // Get card layout configuration based on navigation position and screen constraints
          final cardConfig = ResponsiveUtils.getCardLayoutConfig(context, shopSettings.navigationPosition);
          
          return MasonryGridView.count(
            crossAxisCount: cardConfig.gridColumns,
            mainAxisSpacing: AppTheme.spacing12,
            crossAxisSpacing: AppTheme.spacing12,
            itemCount: _products.length,
            itemBuilder: (context, index) {
              return ProductCard(
                product: _products[index],
                vatRate: shopSettings.vatRate,
                config: cardConfig,
              );
            },
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final double vatRate;
  final CardLayoutConfig config;

  const ProductCard({
    super.key,
    required this.product,
    this.vatRate = 7.0,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    return Card(
      child: Opacity(
        opacity: product.stock > 0 ? 1.0 : 0.6,
        child: InkWell(
          onTap: product.stock > 0 ? () async {
            final success = await cart.addItem(product);
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('สินค้า "${product.name}" หมดในคลัง'),
                  backgroundColor: AppTheme.errorColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } : null,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        child: Padding(
          padding: EdgeInsets.all(config.useCompactLayout ? config.horizontalPadding : AppTheme.spacing12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image section
              Container(
                height: config.imageHeight,
                width: double.infinity,
                child: product.image != null
                    ? ProductImageDisplay(
                        imageFileName: product.image,
                        width: double.infinity,
                        height: config.imageHeight,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radius8),
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                product.name,
                style: config.useCompactLayout 
                    ? AppTheme.heading3.copyWith(fontSize: 14)
                    : AppTheme.heading3,
                maxLines: config.titleMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.description != null && product.description!.isNotEmpty && config.showFullDescription)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacing4),
                  child: Text(
                    product.description!,
                    style: config.useCompactLayout 
                        ? AppTheme.caption.copyWith(fontSize: 10)
                        : AppTheme.caption,
                    maxLines: config.descriptionMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: AppTheme.spacing8),
              config.useCompactLayout 
                  ? _buildCompactPriceRow()
                  : _buildFullPriceRow(),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPriceRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '฿${_calculatePriceWithVat().toStringAsFixed(2)}',
                style: AppTheme.heading3.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _getStockColor(),
                borderRadius: BorderRadius.circular(AppTheme.radius4),
              ),
              child: Text(
                '${product.stock}',
                style: AppTheme.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
        if (vatRate > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'รวมภาษี ${vatRate.toStringAsFixed(1)}%',
              style: AppTheme.caption.copyWith(
                color: Colors.grey.shade600,
                fontSize: 9,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 1,
          ),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            '+${product.pointsEarned.toStringAsFixed(1)} แต้ม',
            style: AppTheme.caption.copyWith(
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
              fontSize: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullPriceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '฿${_calculatePriceWithVat().toStringAsFixed(2)}',
              style: AppTheme.heading3.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (vatRate > 0)
              Text(
                'รวมภาษี ${vatRate.toStringAsFixed(1)}%',
                style: AppTheme.caption.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '+${product.pointsEarned.toStringAsFixed(1)} แต้ม',
                style: AppTheme.caption.copyWith(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
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
    );
  }  double _calculatePriceWithVat() {
    return product.price * (1 + vatRate / 100);
  }

  Color _getStockColor() {
    if (product.stock <= 0) return AppTheme.errorColor;
    if (product.stock <= 5) return AppTheme.warningColor; // แสดงเตือนเมื่อคงเหลือ <= 5
    return AppTheme.successColor;
  }
}
